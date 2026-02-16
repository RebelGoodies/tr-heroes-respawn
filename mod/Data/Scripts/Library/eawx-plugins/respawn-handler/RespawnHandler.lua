---@License: MIT

require("deepcore/std/class")
require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("deepcore/crossplot/crossplot")
require("PGStoryMode")
require("HeroUtil")
require("HeroSystem")

CONSTANTS = ModContentLoader.get("GameConstants")

---@class RespawnHandler
RespawnHandler = class()

---@param gc GalacticConquest
---@param id string
function RespawnHandler:new(gc, id)
	self.gc = gc
	self.id = id
	self.human_player = gc.HumanPlayer
	
	self.inited = false
	self.squadrons_inited = false
	self.human_respawn = true
	self.ai_respawn = true

	---@type number|nil
	self.time_override = nil --debug

	---@type PlayerObject|nil
	self.isard_ssd_owner = nil
	
	---track number of deaths, ["HERO_ID"] = 7
	---@type table<string, integer>
	self.deaths = {}

	---["FACTION"] = {["HERO_ID"] = true/false}
	---@type table<string, table<string, boolean>>
	self.respawning_list = {}

	---["FACTION"] = {["HERO_ID"] = true/false}
	---@type table<string, table<string, boolean>>
	self.omit_list = {}       

	---["FACTION"] = {["squadron_name"] = {"hero_fighter", {"exclude_if_alive"}, was_alive, has_died}}
	---@class RespawnSquadronInfo
	---@field hero_fighter string
	---@field exclude_if_alive string[]
	---@field was_alive boolean
	---@field has_died boolean
	---@type table<string, table<string, RespawnSquadronInfo>>
	self.squadrons = {}
	
	--Format tables to have all factions. Prevents crashes from faction not being there.
	---@type string[]
	local all_factions = CONSTANTS.ALL_FACTIONS
	for _, faction in pairs (all_factions) do
		self.respawning_list[faction] = {}
		self.omit_list[faction] = {}
		self.squadrons[faction] = require("HeroSquadronList")
	end
	
	--Fill omit_list
	---@type table<string, string[]>
	local exceptions = require("RespawnExceptions")
	if exceptions then
		for faction, hero_list in pairs(exceptions) do
			for _, hero_id in pairs(hero_list) do
				self.omit_list[faction][string.upper(hero_id)] = true
			end
		end
	end

	---[HERO_UNIT] = {FACTIONS}
	---@type table<string, string[]>
	local built_in_respawn = {
		["DELVARDUS_THALASSA"] = {"ERIADU_AUTHORITY"},
		["TREUTEN_13X"] = {"GREATER_MALDROOD"},
		["TYBER_ZANN_MERCILESS"] = {"ZSINJ_EMPIRE"},
		["ZSINJ_IRON_FIST_VSD"] = {"ZSINJ_EMPIRE"},
		["THRAWN_GREY_WOLF"] = {"EMPIREOFTHEHAND"},
		["FRAAN_GLORY"] = {}, --any faction
		["JENN_TEAM"] = {}, --any faction
		["JAALIB_BRANDL_PROTECTORATE_I"] = {"REBEL"},
	}

	for hero_unit, faction_list in pairs(built_in_respawn) do
		for _, faction in pairs(faction_list) do
			self:add_to_omit(hero_unit, faction)
		end
	end
	
	---@type table<string, table<string, table<string, string|boolean>>>
	self.regime_sets = require("eawx-mod-icw/spawn-sets/EmpireProgressSet")
	
	crossplot:subscribe("INITIALIZE_AI", self.init, self)
	-- crossplot:subscribe("OMIT_RESPAWN_BULK", self.bulk_add_to_omit, self)
	-- crossplot:subscribe("OMIT_RESPAWN", self.add_to_omit, self)
	-- crossplot:subscribe("ALLOW_RESPAWN", self.remove_from_omit, self)
	
	gc.Events.GalacticProductionFinished:attach_listener(self.on_construction_finished, self)
	gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)
	gc.Events.PlanetOwnerChanged:attach_listener(self.on_planet_owner_changed, self)
	gc.Events.TacticalBattleEnded:attach_listener(self.on_battle_end, self)

	--Replace buildable
	UnitUtil.SetLockList("ZSINJ_EMPIRE", {"Random_Pirate_Fighter", "Random_Pirate_Hero", "Random_Pirate_Legend", "Random_Pirate_Fleet"}, false)
	UnitUtil.SetLockList("ZSINJ_EMPIRE", {"Random_Pirate_Fighter_2", "Random_Pirate_Hero_2", "Random_Pirate_Legend_2", "Random_Pirate_Fleet_2"})
	UnitUtil.SetLockList("HUTT_CARTELS", {"Random_Pirate_Fighter", "Random_Pirate_Hero", "Random_Pirate_Legend", "Random_Pirate_Fleet"}, false)
	UnitUtil.SetLockList("HUTT_CARTELS", {"Random_Pirate_Fighter_2", "Random_Pirate_Hero_2", "Random_Pirate_Legend_2", "Random_Pirate_Fleet_2"})
end

function RespawnHandler:init()
	if self.inited then
		return
	end
	
	if Find_Object_Type("OPTION_RESPAWN_OFF") then
		if self.human_respawn then
			self.human_player.Unlock_Tech(Find_Object_Type("OPTION_RESPAWN_OFF"))
		else
			self.human_player.Unlock_Tech(Find_Object_Type("OPTION_RESPAWN_ON"))
		end
		if self.ai_respawn then
			self.human_player.Unlock_Tech(Find_Object_Type("OPTION_AI_RESPAWN_OFF"))
		else
			self.human_player.Unlock_Tech(Find_Object_Type("OPTION_AI_RESPAWN_ON"))
		end
		--if self.id == "PROGRESSIVE" then
		--	self.human_player.Unlock_Tech(Find_Object_Type("OPTION_REGIME_NO_DESPAWN"))
		--end
	end
	
	if self.id == "PROGRESSIVE" then
		-- self:regime_check()
	end
	
	self:squadron_check()
end

---DEPRECATED
---Check every cycle
---@param args any
function squadron_loop(args)
	--Logger:trace("entering RespawnHandler:squadron_loop")
	local handler = args[1]
	if not handler.squadrons_inited then
		return
	end
	handler:squadron_check()
	Register_Timer(squadron_loop, 40, {handler})
end

---With the new 3.4 fighter system, this is not needed, except for Han and Chewie.
---Fighter hero deaths are not detected by on_galactic_hero_killed.
function RespawnHandler:squadron_check()
	--Logger:trace("entering RespawnHandler:squadron_check")
	for faction, squadron_list in pairs(self.squadrons) do
		for squadron, info in pairs(squadron_list) do
			if info[1] then
				if not self.squadrons_inited then
					self.squadrons_inited = true
					if not info[2] then
						info[2] = {}
					end
					info[3] = false
					info[4] = false
					--Register_Timer(squadron_loop, 36, {self})
				end
				local hero_fighter = info[1]
				local hero_object = Find_First_Object(hero_fighter)
				local exclude_if_alive = info[2]
				local was_alive = info[3]
				local has_died = info[4]
				local is_alive = TestValid(hero_object)
				
				if is_alive then
					info[4] = false
				elseif was_alive and not has_died then
					info[4] = true
					self:on_galactic_hero_killed(string.upper(squadron), faction, nil, exclude_if_alive)
				end
				if hero_object and hero_object.Get_Owner() == Find_Player(faction) then
					info[3] = is_alive
				end
			end
		end
	end
end

---@param planet Planet
---@param new_owner string
---@param old_owner string
function RespawnHandler:on_planet_owner_changed(planet, new_owner, old_owner)
	self:squadron_check()
end

---@param mode_name string
function RespawnHandler:on_battle_end(mode_name)
	--Logger:trace("entering RespawnHandler:on_battle_end "..mode_name)
	local han = Find_First_Object("Han_Solo")
	local chewie = Find_First_Object("Chewbacca")
	
	if TestValid(han) and not TestValid(chewie) then
		local planet_obj = han.Get_Planet_Location()
		han.Despawn()
		respawn_hero("Han_Solo_Team", "REBEL", planet_obj)
		
	elseif not TestValid(han) and TestValid(chewie) then
		local planet_obj = chewie.Get_Planet_Location()
		chewie.Despawn()
		respawn_hero("Han_Solo_Team", "REBEL", planet_obj)
	end
	
	self:squadron_check()
end

---@param owner string
---@return boolean enabled true if respawn is active for this faction
function RespawnHandler:respawn_status_check(owner)
	local is_human = Find_Player(owner).Is_Human()
	if (is_human and self.human_respawn) or (not is_human and self.ai_respawn) then
		return true
	else
		return false
	end
end

---@param hero_name string
---@param owner string
---@param killer_name string
---@param exclude_if_alive string[]
function RespawnHandler:on_galactic_hero_killed(hero_name, owner, killer_name, exclude_if_alive)
	if hero_name == "Isard_Lusankya" then
		self.isard_ssd_owner = nil
	end
	--Logger:trace("entering RespawnHandler:on_galactic_hero_killed "..hero_name.." for "..owner)
	if self:respawn_status_check(owner) and not self.respawning_list[owner][hero_name] then --Second check really only needed for "Han_Solo_Team"
		local multiplier = self:calc_multiplier(hero_name)
		local cycle_time = self.time_override or get_cycle_time(hero_name, owner) * multiplier
		
		if cycle_time > 0 and not self.omit_list[owner][hero_name] then
			if not in_list_is_alive(exclude_if_alive) then
				Register_Timer(try_respawn, cycle_time*40, {hero_name, owner, self, exclude_if_alive})
				self.respawning_list[owner][hero_name] = true
				if Find_Player(owner).Is_Human() then
					StoryUtil.ShowScreenText("%s will respawn in about " .. tostring(Dirty_Floor(cycle_time+0.5)) .. " cycles.", 20, hero_name, {r = 244, g = 244, b = 0})
				else
					StoryUtil.ShowScreenText("%s will respawn in about " .. tostring(Dirty_Floor(cycle_time+0.5)) .. " cycles.", 15, hero_name, {r = 244, g = 160, b = 0})
				end
			end
		else
			StoryUtil.ShowScreenText("%s will not respawn.", 10, hero_name, {r = 244, g = 200, b = 0})
		end
	end
end

---Increase respawn time by 10% each death
---@param hero_name string
---@return number multiplier percentage applied to the default respawn time
function RespawnHandler:calc_multiplier(hero_name)
	--Logger:trace("entering RespawnHandler:calc_multiplier")
	local percent_increase = 0.1 --10%
	if not self.deaths[hero_name] then
		self.deaths[hero_name] = 1
	else
		self.deaths[hero_name] = self.deaths[hero_name] + 1
	end
	return 1 + (percent_increase * (self.deaths[hero_name] - 1))
end

---@param args any
function try_respawn(args)
	local hero_name = args[1]
	local owner = args[2]
	--Logger:trace("entering RespawnHandler:try_respawn "..hero_name.." for "..owner)
	local handler = args[3]
	local exclude_if_alive = args[4]
	if handler:respawn_status_check(owner) then
		if not handler.omit_list[owner][hero_name] then
			if not in_list_is_alive(exclude_if_alive) then
				respawn_hero(warlord_check(hero_name, owner), owner)
				handler.respawning_list[owner][hero_name] = false
			end
		else
			StoryUtil.ShowScreenText("%s will not return.", 10, hero_name, {r = 244, g = 200, b = 0})
		end
	end
end

---@param planet Planet
---@param object_type_name string
function RespawnHandler:on_construction_finished(planet, object_type_name)
	--Logger:trace("entering RespawnHandler:on_construction_finished")
	if object_type_name == "ISARDUPGRADE" then
		self.isard_ssd_owner = planet:get_owner()
		return
	elseif self.isard_ssd_owner and not TestValid(Find_First_Object("Isard_Lusankya")) then
		StoryUtil.SpawnAtSafePlanet("KUAT", self.isard_ssd_owner, StoryUtil.GetSafePlanetTable(), {"Isard_Lusankya"})
		self.isard_ssd_owner = nil
		return
	end
	
	if object_type_name == "OPTION_RESPAWN_ON" then
		self.human_respawn = true
		self.human_player.Lock_Tech(Find_Object_Type("OPTION_RESPAWN_ON"))
		self.human_player.Unlock_Tech(Find_Object_Type("OPTION_RESPAWN_OFF"))
		StoryUtil.ShowScreenText("Human Hero Respawns ENABLED", 6, nil, {r = 88, g = 244, b = 44})
	
	elseif object_type_name == "OPTION_RESPAWN_OFF" then
		self.human_respawn = false
		self.human_player.Lock_Tech(Find_Object_Type("OPTION_RESPAWN_OFF"))
		self.human_player.Unlock_Tech(Find_Object_Type("OPTION_RESPAWN_ON"))
		StoryUtil.ShowScreenText("Human Hero Respawns DISABLED", 6, nil, {r = 244, g = 66, b = 0})
	
	elseif object_type_name == "OPTION_AI_RESPAWN_ON" then
		self.ai_respawn = true
		self.human_player.Lock_Tech(Find_Object_Type("OPTION_AI_RESPAWN_ON"))
		self.human_player.Unlock_Tech(Find_Object_Type("OPTION_AI_RESPAWN_OFF"))
		StoryUtil.ShowScreenText("AI Hero Respawns ENABLED", 6, nil, {r = 100, g = 244, b = 44})
	
	elseif object_type_name == "OPTION_AI_RESPAWN_OFF" then
		self.ai_respawn = false
		self.human_player.Lock_Tech(Find_Object_Type("OPTION_AI_RESPAWN_OFF"))
		self.human_player.Unlock_Tech(Find_Object_Type("OPTION_AI_RESPAWN_ON"))
		StoryUtil.ShowScreenText("AI Hero Respawns DISABLED", 6, nil, {r = 244, g = 100, b = 0})
	
	elseif object_type_name == "OPTION_REGIME_NO_DESPAWN" then
		GlobalValue.Set("REGIME_DESPAWN", false)
		self.human_player.Lock_Tech(Find_Object_Type("OPTION_REGIME_NO_DESPAWN"))
		self.human_player.Unlock_Tech(Find_Object_Type("OPTION_REGIME_YES_DESPAWN"))
		StoryUtil.ShowScreenText("Regime hero removal DISABLED", 6, nil, {r = 244, g = 180, b = 44})
		--self:regime_check()
	
	elseif object_type_name == "OPTION_REGIME_YES_DESPAWN" then
		GlobalValue.Set("REGIME_DESPAWN", true)
		self.human_player.Lock_Tech(Find_Object_Type("OPTION_REGIME_YES_DESPAWN"))
		self.human_player.Unlock_Tech(Find_Object_Type("OPTION_REGIME_NO_DESPAWN"))
		StoryUtil.ShowScreenText("Regime hero removal ENABLED", 6, nil, {r = 160, g = 244, b = 44})
		--self:regime_check()
	
	elseif object_type_name == "OPTION_FAST_RESPAWN" then
		self.time_override = 1
	end
end

---@param faction string
---@param hero_list string[]
function RespawnHandler:bulk_add_to_omit(faction, hero_list)
	--Logger:trace("entering RespawnHandler:bulk_add_to_omit")
	for _, hero_name in pairs(hero_list) do
		self:add_to_omit(hero_name, faction)
	end
end

---@param hero_name string
---@param faction string
function RespawnHandler:add_to_omit(hero_name, faction)
	--Logger:trace("entering RespawnHandler:add_to_omit "..hero_name)
	local owner = string.upper(faction)
	if self.omit_list[owner] then
		self.omit_list[owner][string.upper(hero_name)] = true
	end
end

---@param hero_name string
---@param faction string
function RespawnHandler:remove_from_omit(hero_name, faction)
	--Logger:trace("entering RespawnHandler:remove_from_omit "..hero_name)
	local owner = string.upper(faction)
	if self.omit_list[owner] then
		self.omit_list[owner][string.upper(hero_name)] = false
	end
end

function RespawnHandler:regime_check()
	local leading_empire = GlobalValue.Get("IMPERIAL_REMNANT")
	for regime, sets in pairs(self.regime_sets) do
		for planet, herolist in pairs(sets) do
			for _, hero_table in pairs(herolist) do
				if hero_table.remove or hero_table.remove_isard or hero_table.remove_ccogm then
					self:add_to_omit(hero_table.object, leading_empire)
				--else
				--	self:remove_from_omit(hero_table.object, leading_empire)
				end
			end
		end
	end
end

return RespawnHandler
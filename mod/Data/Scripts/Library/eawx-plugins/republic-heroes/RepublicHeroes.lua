--**************************************************************************************************
--*    _______ __                                                                                  *
--*   |_     _|  |--.----.---.-.--.--.--.-----.-----.                                              *
--*     |   | |     |   _|  _  |  |  |  |     |__ --|                                              *
--*     |___| |__|__|__| |___._|________|__|__|_____|                                              *
--*    ______                                                                                      *
--*   |   __ \.-----.--.--.-----.-----.-----.-----.                                                *
--*   |      <|  -__|  |  |  -__|     |  _  |  -__|                                                *
--*   |___|__||_____|\___/|_____|__|__|___  |_____|                                                *
--*                                   |_____|                                                      *
--*                                                                                                *
--*                                                                                                *
--*       File:              RepublicHeroes.lua                                                     *
--*       File Created:      Monday, 24th February 2020 02:19                                      *
--*       Author:            [TR] Jorritkarwehr                                                             *
--*       Last Modified:     Monday, 24th February 2020 02:34                                      *
--*       Modified By:       [TR] Jorritkarwehr                                                             *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("PGStoryMode")
require("PGSpawnUnits")
require("deepcore/std/class")
require("eawx-util/StoryUtil")
require("HeroSystem")

RepublicHeroes = class()

function RepublicHeroes:new(gc, herokilled_finished_event, human_player)
    self.human_player = human_player
    gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	herokilled_finished_event:attach_listener(self.on_galactic_hero_killed, self)
	self.inited = false
	
	crossplot:subscribe("NR_ADMIRAL_DECREMENT", self.admiral_decrement, self)
	crossplot:subscribe("NR_ADMIRAL_LOCKIN", self.admiral_lockin, self)
	crossplot:subscribe("NR_ADMIRAL_EXIT", self.admiral_exit, self)
	crossplot:subscribe("NR_ADMIRAL_STORYLOCK", self.admiral_storylock, self)
	crossplot:subscribe("NR_ADMIRAL_RETURN", self.admiral_return, self)
	
	crossplot:subscribe("ERA_THREE_TRANSITION", self.Era_3, self)
	crossplot:subscribe("ERA_FOUR_TRANSITION", self.Era_4, self)
	crossplot:subscribe("ERA_SEVEN_TRANSITION", self.Era_7, self)
	
	crossplot:subscribe("NCMP2_HEROES", self.NCMP2_handler, self)
	crossplot:subscribe("BAC_HEROES", self.Bothan_Heroes, self)
	crossplot:subscribe("MEDIATOR_HEROES", self.Mediator_Heroes, self)
	
	hero_data = {
		total_slots = 4,			--Max slot number. Set at the start of the GC and never change
		free_hero_slots = 4,		--Slots open to buy
		vacant_hero_slots = 0,	--Slots that need another action to move to free
		initialized = false,
		full_list = { --All options for reference operations
			["Ackbar"] = {"ACKBAR_ASSIGN",{"ACKBAR_RETIRE","ACKBAR_RETIRE2"},{"HOME_ONE","GALACTIC_VOYAGER"},"TEXT_UNIT_GALACTIC_VOYAGER"},
			["Nantz"] = {"NANTZ_ASSIGN",{"NANTZ_RETIRE","NANTZ_RETIRE2"},{"NANTZ_INDEPENDENCE","NANTZ_FAITHFUL_WATCHMAN"},"TEXT_UNIT_NANTZ"},
			["Sovv"] = {"SOVV_ASSIGN",{"SOVV_RETIRE","SOVV_RETIRE2"},{"SOVV_DAUNTLESS","SOVV_VOICE_OF_THE_PEOPLE"},"TEXT_UNIT_SOVV"},
			["Solo"] = {"SOLO_ASSIGN",{"SOLO_RETIRE"},{"SOLO_REMONDA"},"TEXT_HERO_HAN_SOLO",["no_random"] = true, ["required_unit"] = "MILLENNIUM_FALCON", ["required_team"] = "HAN_SOLO_TEAM"},
			["Han"] = {"HAN_ASSIGN",{"HAN_RETIRE"},{"HAN_INTREPID"},"TEXT_HERO_HAN_SOLO",["no_random"] = true, ["required_unit"] = "MILLENNIUM_FALCON", ["required_team"] = "HAN_SOLO_TEAM"}, --Han's forms are so separate that it's easier to handle them separately
			["Iblis"] = {"IBLIS_ASSIGN",{"IBLIS_RETIRE","IBLIS_RETIRE2","IBLIS_RETIRE3","IBLIS_RETIRE4"},{"IBLIS_PEREGRINE","IBLIS_SELONIAN_FIRE","IBLIS_BAIL_ORGANA","IBLIS_HARBINGER"},"TEXT_HERO_GARM"},
			["Drayson"] = {"DRAYSON_ASSIGN",{"DRAYSON_RETIRE","DRAYSON_RETIRE2"},{"DRAYSON_TRUE_FIDELITY","DRAYSON_NEW_HOPE"},"TEXT_HERO_DRAYSON"},
			["Ragab"] = {"RAGAB_ASSIGN",{"RAGAB_RETIRE"},{"RAGAB_EMANCIPATOR"},"TEXT_HERO_RAGAB"},
			["Kalback"] = {"KALBACK_ASSIGN",{"KALBACK_RETIRE"},{"KALBACK_JUSTICE"},"TEXT_HERO_KALBACK"},
			["Tallon"] = {"TALLON_ASSIGN",{"TALLON_RETIRE"},{"TALLON_SILENT_WATER"},"TEXT_HERO_TALLON"},
			["Vantai"] = {"VANTAI_ASSIGN",{"VANTAI_RETIRE"},{"VANTAI_MOONSHADOW"},"TEXT_HERO_VANTAI"},
			["Brand"] = {"BRAND_ASSIGN",{"BRAND_RETIRE","BRAND_RETIRE2"},{"BRAND_INDOMITABLE","BRAND_YALD"},"TEXT_HERO_BRAND"},
			["Bell"] = {"BELL_ASSIGN",{"BELL_RETIRE"},{"BELL_ENDURANCE"},"TEXT_HERO_BELL"},
			["Abaht"] = {"ABAHT_ASSIGN",{"ABAHT_RETIRE"},{"ABAHT_INTREPID"},"TEXT_HERO_ABAHT"},
			["Nammo"] = {"NAMMO_ASSIGN",{"NAMMO_RETIRE"},{"NAMMO_DEFIANCE"},"TEXT_HERO_NAMMO"},
			["Krefey"] = {"KREFEY_ASSIGN",{"KREFEY_RETIRE"},{"KREFEY_RALROOST"},"TEXT_HERO_KREFEY"},
			["Snunb"] = {"SNUNB_ASSIGN",{"SNUNB_RETIRE","SNUNB_RETIRE2"},{"SNUNB_ANTARES_SIX","SNUNB_RESOLVE"},"TEXT_HERO_SNUNB"},
			["Ackdool"] = {"ACKDOOL_ASSIGN",{"ACKDOOL_RETIRE"},{"ACKDOOL_MEDIATOR"},"TEXT_HERO_ACKDOOL"},
			["Burke"] = {"BURKE_ASSIGN",{"BURKE_RETIRE"},{"BURKE_REMEMBER_ALDERAAN"},"TEXT_HERO_BURKE"},
			["Massa"] = {"MASSA_ASSIGN",{"MASSA_RETIRE","MASSA_RETIRE2"},{"MASSA_LUCREHULK_AUXILIARY","MASSA_LUCREHULK_CARRIER"},"TEXT_HERO_MASSA"},
			["Dorat"] = {"DORAT_ASSIGN",{"DORAT_RETIRE"},{"DORAT_ARROW_OF_SULLUST"},"TEXT_HERO_DORAT"},
			["Grant"] = {"GRANT_ASSIGN",{"GRANT_RETIRE"},{"GRANT_ORIFLAMME"},"TEXT_HERO_GRANT"},
			["Lando"] = {"LANDO_ASSIGN",{"LANDO_RETIRE","LANDO_RETIRE2"},{"LANDO_LIBERATOR","LANDO_ALLEGIANCE"},"TEXT_HERO_LANDO",["no_random"] = true, ["required_unit"] = "LANDO_CALRISSIAN", ["required_team"] = "LANDO_CALRISSIAN_TEAM"},
		},
		available_list = {--Heroes currently available for purchase. Seeded with those who have no special prereqs
			"Ackbar",
			"Nantz",
			"Sovv",
			"Solo",
			"Drayson",
			"Ragab",
			"Kalback",
			"Tallon",
			"Vantai",
			"Snunb",
			"Burke",
			"Massa",
			"Lando",
		},
		story_locked_list = {--Heroes not accessible, but able to return with the right conditions
			["Dorat"] = true
		},
		active_player = Find_Player("Rebel"),
		extra_name = "EXTRA_ADMIRAL_SLOT",
		random_name = "RANDOM_ASSIGN",
		global_display_list = "NR_ADMIRAL_LIST" --Name of global array used for documention of currently active heroes
	}
	
	Krefey_Checks = 0
end

function RepublicHeroes:on_production_finished(planet, object_type_name)--object_type_name, owner)
	--Logger:trace("entering RepublicHeroes:on_production_finished")
	if not self.inited then
		self.inited = true
		self:init_heroes()
	end
	if object_type_name == "DORAT_MASSA" then
		Handle_Hero_Exit("Dorat", hero_data, true)
		Handle_Hero_Add("Massa", hero_data)
	elseif object_type_name == "MASSA_DORAT" or object_type_name == "MASSA_DORAT2" then
		Handle_Hero_Exit("Massa", hero_data, true)
		Handle_Hero_Add("Dorat", hero_data)
	else
		Handle_Build_Options(object_type_name, hero_data)
		if object_type_name == "HAN_ASSIGN" then
			Handle_Hero_Exit("Abaht", hero_data)
			if hero_data.active_player.Is_Human() then
				Story_Event("HAN_INTREPID_SPEECH")
			end
		elseif object_type_name == "HAN_RETIRE" then
			Handle_Hero_Add("Abaht", hero_data)
		end
	end
end

function RepublicHeroes:init_heroes()
	--Logger:trace("entering RepublicHeroes:init_heroes")
	init_hero_system(hero_data)
	
	local tech_level = GlobalValue.Get("CURRENT_ERA")
	
	--Handle special actions for starting tech level
	if tech_level >= 2 then
		Handle_Hero_Exit("Kalback", hero_data)
		Handle_Hero_Exit("Massa", hero_data)
		Handle_Hero_Add("Dorat", hero_data)
		local assign_unit = Find_Object_Type("DORAT_MASSA")
		hero_data.active_player.Lock_Tech(assign_unit)
	end
	
	if tech_level >= 3 then
		Handle_Hero_Add("Iblis", hero_data)
	end
	
	if tech_level >= 4 then
		Handle_Hero_Exit("Solo", hero_data)
		Handle_Hero_Add("Grant", hero_data)
		local assign_unit = Find_Object_Type("GRANT_RETIRE") --Starts locked as to not be there when PA Grant is attacking
		hero_data.active_player.Unlock_Tech(assign_unit)
	end
	
	if tech_level >= 5 then
		Handle_Hero_Exit("Ragab", hero_data)
		set_unit_index("Lando", 2, hero_data)
	end
	
	if tech_level >= 7 then
		Handle_Hero_Add("Brand", hero_data)
		Handle_Hero_Add("Abaht", hero_data)
		Handle_Hero_Add("Han", hero_data)
		Krefey_Check()
		
		hero_data.total_slots = hero_data.total_slots + 1
		hero_data.free_hero_slots = hero_data.free_hero_slots + 1
		Unlock_Hero_Options(hero_data)
	end
end

function RepublicHeroes:admiral_decrement(quantity)
	--Logger:trace("entering RepublicHeroes:admiral_decrement")
	Decrement_Hero_Amount(quantity, hero_data)
end

function RepublicHeroes:admiral_lockin(list)
	--Logger:trace("entering RepublicHeroes:admiral_lockin")
	lock_retires(list, hero_data)
end

function RepublicHeroes:admiral_storylock(list)
	--Logger:trace("entering RepublicHeroes:admiral_storylock")
	for _, tag in pairs(list) do
		Handle_Hero_Exit(tag, hero_data, true)
	end
end

function RepublicHeroes:admiral_exit(list)
	--Logger:trace("entering RepublicHeroes:admiral_exit")
	for _, tag in pairs(list) do
		Handle_Hero_Exit(tag, hero_data)
	end
end

function RepublicHeroes:admiral_return(list)
	--Logger:trace("entering RepublicHeroes:admiral_return")
	for _, tag in pairs(list) do
		if check_hero_exists(tag, hero_data) then
			Handle_Hero_Add(tag, hero_data)
		end
	end
end

function RepublicHeroes:on_galactic_hero_killed(hero_name, owner)
	--Logger:trace("entering RepublicHeroes:on_galactic_hero_killed")
	if hero_name == "CHIMERA" then
		if Handle_Hero_Exit("Kalback", hero_data) then
			if hero_data.active_player.Is_Human() then
				Story_Event("KALBACK_SPEECH")
			end
		end
	end
	local tag = Handle_Hero_Killed(hero_name, owner, hero_data)
	if tag == "Ackbar" then
		if not check_hero_exists("Ackbar", hero_data) then
			Handle_Hero_Add("Nammo", hero_data)
		end
	elseif tag == "Massa" then
		local assign_unit = Find_Object_Type("DORAT_MASSA")
		hero_data.active_player.Lock_Tech(assign_unit)
		
		if check_hero_exists("Dorat", hero_data) then
			Handle_Hero_Add("Dorat", hero_data)
		end
	elseif tag == "Dorat" then
		local assign_unit = Find_Object_Type("MASSA_DORAT")
		hero_data.active_player.Lock_Tech(assign_unit)
		local assign_unit = Find_Object_Type("MASSA_DORAT2")
		hero_data.active_player.Lock_Tech(assign_unit)
		
		if check_hero_exists("Massa", hero_data) then
			Handle_Hero_Add("Massa", hero_data)
		end
	elseif tag == "Han" or tag == "Solo" then
		local planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
		SpawnList({"Han_Solo_Team"}, planet, hero_data.active_player, true, false)
		if hero_data.active_player.Is_Human() then
			Story_Event("HAN_RESPAWN_SPEECH")
		end
	elseif tag == "Lando" then
		local planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
		SpawnList({"Lando_Calrissian_Team"}, planet, hero_data.active_player, true, false)
		if hero_data.active_player.Is_Human() then
			Story_Event("LANDO_RESPAWN_SPEECH")
		end
	end
end

function RepublicHeroes:Era_3()
	--Logger:trace("entering RepublicHeroes:Era_3")
	Handle_Hero_Add("Iblis", hero_data)
end

function RepublicHeroes:Era_4()
	--Logger:trace("entering RepublicHeroes:Era_4")
	Handle_Hero_Exit("Kalback", hero_data)
end

function Krefey_Check()
	--Logger:trace("entering RepublicHeroes:Krefey_Check")
	Krefey_Checks = Krefey_Checks + 1
	if Krefey_Checks == 2 then
		Handle_Hero_Add("Krefey", hero_data)
	end
end

function RepublicHeroes:Era_7()
	--Logger:trace("entering RepublicHeroes:Era_7")
	Handle_Hero_Add("Han", hero_data)
	Krefey_Check()
end

function RepublicHeroes:NCMP2_handler()
	--Logger:trace("entering RepublicHeroes:NCMP2_handler")
	hero_data.total_slots = hero_data.total_slots + 1
	--Free does not go up beause Bell is occupying the new slot
	local planet = FindPlanet("Coruscant")
	if TestValid(planet) then
		if not StoryUtil.CheckFriendlyPlanet(planet,hero_data.active_player) then
			planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
		end
	else
		planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
	end
	if TestValid(planet) then
		SpawnList({"Bell_Endurance"}, planet, hero_data.active_player, true, false)
	end
	Handle_Hero_Add("Brand", hero_data)
	Handle_Hero_Add("Abaht", hero_data)
	local dummy = Find_First_Object("Solo_Remonda")
	if TestValid(dummy) then
		planet = dummy.Get_Planet_Location()
		if not TestValid(planet) then
			planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
		end
		if Handle_Hero_Exit("Solo", hero_data) then
			SpawnList({"Han_Solo_Team"}, planet, hero_data.active_player, true, false)
			if hero_data.active_player.Is_Human() then
				Story_Event("HAN_RETIRE_SPEECH")
			end
		end
	else
		Handle_Hero_Exit("Solo", hero_data)
	end
	Get_Active_Heroes(false, hero_data)
end

function RepublicHeroes:Bothan_Heroes()
	--Logger:trace("entering RepublicHeroes:Bothan_Heroes")
	Krefey_Check()
end

function RepublicHeroes:Mediator_Heroes()
	--Logger:trace("entering RepublicHeroes:Mediator_Heroes")
	Handle_Hero_Add("Ackdool", hero_data)
end
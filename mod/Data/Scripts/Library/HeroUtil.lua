require("PGStoryMode")
require("eawx-util/ChangeOwnerUtilities")
StoryUtil = require("eawx-util/StoryUtil")

---The hero respawn time based on combat power
---@param hero_id string
---@param owner string
---@return number time
function get_cycle_time(hero_id, owner)
	local min_time = 7
	local max_time = 40

	local object_type = Find_Object_Type(hero_id)
	if not TestValid(object_type) then
		return min_time
	end

	local combat_power = object_type.Get_Combat_Rating()
	if object_type.Is_Hero() and combat_power then
		local cycle_time = 0
		if combat_power < 3 then                 -- Econ heroes
			cycle_time = 10 + (combat_power * 2) -- Range 10 to 14
		elseif combat_power <= 260 then            -- Ground heroes
			cycle_time = (combat_power + 110) / 18 -- Range 7 to 20
		else                                         -- Space heroes
			cycle_time = (combat_power + 2100) / 340 -- Range 7 to Max
		end
		if cycle_time < min_time then
			cycle_time = min_time
		elseif cycle_time > max_time then -- Works out to over 11500 power
			cycle_time = -1
		end
		return cycle_time
	end
	return min_time
end

---@param hero_id string
---@param owner string
---@param planet PlanetObject|nil
function respawn_hero(hero_id, owner, planet)
	local find_it = Find_First_Object(hero_id) 
	if TestValid(find_it) then
		return
	end
	
	if not TestValid(planet) then
		planet = StoryUtil.FindFriendlyPlanet(owner)
	end
	
	local player = Find_Player(owner)
	if planet and player then
		if player.Is_Human() then
			local planet_name = planet.Get_Type().Get_Name()
			StoryUtil.ShowScreenText("%s has arrived at " .. tostring(planet_name), 15, hero_id, {r = 0, g = 244, b = 0})
		end
		SpawnList({hero_id}, planet, player, true, false)
	end
end

---@param hero_id string
---@param owner string
---@return string swap
function warlord_check(hero_id, owner)
	local swap = hero_id
	-- if hero_id == "DELVARDUS_BRILLIANT" and owner == "ERIADU_AUTHORITY" then
	-- 	swap = "DELVARDUS_THALASSA"
	-- elseif hero_id == "TREUTEN_CRIMSON_SUNRISE" and owner == "GREATER_MALDROOD" then
	-- 	swap = "TREUTEN_13X"
	-- elseif hero_id == "TYBER_ZANN_TEAM2" and owner == "ZSINJ_EMPIRE" then
	-- 	swap = "TYBER_ZANN_TEAM"
	-- end
	return swap
end

---@param hero_list string[]
---@param hero_id string
---@return boolean exists
function in_list(hero_list, hero_id)
	if hero_list then
		for _, hero_name in pairs(hero_list) do
			if string.upper(hero_name) == string.upper(hero_id) then
				return true
			end
		end
	end
	return false
end

---@param hero_list string[]
---@return boolean is_alive
function in_list_is_alive(hero_list)
	if hero_list then
		for _, hero in pairs(hero_list) do
			if TestValid(Find_First_Object(hero)) then
				return true
			end
		end
	end
	return false
end

---@param val number
---@return string floor
function Dirty_Floor(val)
	return string.format("%d", val) -- works on implicit string to int conversion
end
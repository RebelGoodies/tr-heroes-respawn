require("PGStoryMode")
require("eawx-util/ChangeOwnerUtilities")
StoryUtil = require("eawx-util/StoryUtil")

-- The hero respawn time based on combat power
function get_cycle_time(hero_id, owner)
	local min_time = 7
	local max_time = 40

	local object_type = Find_Object_Type(hero_id)
	local combat_power = object_type.Get_Combat_Rating()
	if object_type.Is_Hero() and combat_power then
		local cycle_time
		if combat_power < 3 then                 -- Econ heroes
			cycle_time = 10 + (combat_power * 2) -- Range 10 to 14
		elseif combat_power <= 350 then            -- Ground heroes
			cycle_time = (combat_power + 110) / 18 -- Range 7 to 20
			if cycle_time > 20 then
				cycle_time = 20
			end
		else                                         -- Space heroes
			cycle_time = (combat_power + 2000) / 350 -- Range 7 to Max
		end
		if cycle_time < min_time then
			cycle_time = min_time
		elseif cycle_time > max_time then
			cycle_time = max_time
		end
		return cycle_time
	end
	return min_time
end

function respawn_hero(hero_id, owner)
	local find_it = Find_First_Object(hero_id) 
	if TestValid(find_it) then
		return
	end
		
	local planet = StoryUtil.FindFriendlyPlanet(owner)
	if planet then
		local player = Find_Player(owner)
		if player.Is_Human() then
			local planet_name = planet.Get_Type().Get_Name()
			StoryUtil.ShowScreenText("%s has arrived at " .. tostring(planet_name), 15, hero_id, {r = 0, g = 244, b = 0})
		end
		SpawnList({hero_id}, planet, player, true, false)
	end
end

function warlord_check(hero_id, owner)
	local swap = hero_id
	if hero_id == "DELVARDUS_BRILLIANT" and owner == "ERIADU_AUTHORITY" then
		swap = "THALASSA"
	elseif hero_id == "CRIMSONSUNRISE_STAR_DESTROYER" and owner == "GREATER_MALDROOD" then
		swap = "13X_TERADOC"
	elseif hero_id == "TYBER_ZANN_TEAM2" and owner == "ZSINJ_EMPIRE" then
		swap = "TYBER_ZANN_TEAM"
	end
	return swap
end

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

function Dirty_Floor(val)
	return string.format("%d", val) -- works on implicit string to int conversion
end
--******************************************************************************
--     _______ __
--    |_     _|  |--.----.---.-.--.--.--.-----.-----.
--      |   | |     |   _|  _  |  |  |  |     |__ --|
--      |___| |__|__|__| |___._|________|__|__|_____|
--     ______
--    |   __ \.-----.--.--.-----.-----.-----.-----.
--    |      <|  -__|  |  |  -__|     |  _  |  -__|
--    |___|__||_____|\___/|_____|__|__|___  |_____|
--                                    |_____|
--*   @Author:              [TR]Pox
--*   @Date:                2018-03-10T15:09:24+01:00
--*   @Project:             Imperial Civil War
--*   @Filename:            story_util.lua
--*   @Last modified by:    [TR]Pox
--*   @Last modified time:  2018-03-17T02:24:26+01:00
--*   @License:             This source code may only be used with explicit permission from the developers
--*   @Copyright:           © TR: Imperial Civil War Development Team
--******************************************************************************

-- Needed old versions for FTGU hero spawns

StoryUtil2 = {
    __important = true
}

function StoryUtil2.FindFriendlyPlanet(player)
    if type(player) == "string" then
        player = Find_Player(player)
    end

    local allPlanets = FindPlanet.Get_All_Planets()

    local random = 0
    local planet = nil

    while table.getn(allPlanets) > 0 do
        random = GameRandom(1, table.getn(allPlanets))
        planet = allPlanets[random]
        table.remove(allPlanets, random)

        if planet.Get_Owner() == player and EvaluatePerception("Enemy_Present", player, planet) == 0 then
            return planet
        end
    end

    return nil
end

function StoryUtil2.CheckFriendlyPlanet(planet, player)
	if planet.Get_Owner() == player and EvaluatePerception("Enemy_Present", player, planet) == 0 then
		return true
	else
		return false
    end
end

function StoryUtil2.SpawnAtSafePlanet(planet_name, player, spawn_location_table, spawn_list, ai_use_set)
    local player_string = player
    if type(player) == "string" then
        player = Find_Player(player)
    end

    player_string = player.Get_Faction_Name()

    local capital_structure = nil
    local capital_location = nil
    local capital = nil

    if CONSTANTS.ALL_FACTIONS_CAPITALS[player_string] then
        capital = CONSTANTS.ALL_FACTIONS_CAPITALS[player_string].STRUCTURE
        if capital then
            capital_structure = Find_First_Object(capital)
            if capital_structure then
                capital_location = capital_structure.Get_Planet_Location()
            end
        end
    end      

    if spawn_location_table[planet_name] then
        local start_planet = FindPlanet(planet_name)
		
        if not StoryUtil2.CheckFriendlyPlanet(start_planet, player) then
            if player == Find_Player("Warlords") or player == Find_Player("Independent_Forces") then
                return nil
            else
                if capital_location ~= nil then
                    start_planet = capital_location
                else
                    start_planet = StoryUtil2.FindFriendlyPlanet(player)
                end
            end
        end
		
        local ai_use = true
        if ai_use_set == false then
            ai_use = false
        end

        if start_planet then
            SpawnList(spawn_list, start_planet, player, ai_use, false)
            return start_planet
        else
            DebugMessage(
                "%s -- No spawn planet could be found as alternative for %s!",
                tostring(Script),
                tostring(planet_name)
            )
            return nil
        end
    else
        start_planet = nil
        if capital_location ~= nil then
            start_planet = capital_location
        else
            start_planet = StoryUtil2.FindFriendlyPlanet(player)
        end
		
		local ai_use = true
        if ai_use_set == false then
            ai_use = false
        end

        if start_planet then
            SpawnList(spawn_list, start_planet, player, ai_use, false)
            return start_planet
        else
            DebugMessage(
                "%s -- No spawn planet could be found as alternative for %s!",
                tostring(Script),
                tostring(planet_name)
            )
            return nil
        end
    end
end

return StoryUtil2

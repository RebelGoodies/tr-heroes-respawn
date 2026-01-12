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
--*   @Filename:            StoryUtil2.lua
--*   @Last modified by:    Not [TR]Pox
--*   @Last modified time:  2018-03-17T02:24:26+01:00
--*   @License:             This source code may only be used with explicit permission from the developers
--*   @Copyright:           © TR: Imperial Civil War Development Team
--******************************************************************************

-- Needed old versions for FTGU hero spawns
-- New version crashes if faction does not have a planet

StoryUtil2 = {
    __important = true
}

---@param player string|PlayerObject|nil
---@return PlanetObject|nil
function StoryUtil2.FindFriendlyPlanet(player)
    if not player then
        return
    end

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

		-- This works fine. New version crashes if faction does not have a planet
        if planet.Get_Owner() == player and EvaluatePerception("Enemy_Present", player, planet) == 0 then
            return planet
        end
    end

    return nil
end

return StoryUtil2

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
--*       File:              BountyHunters.lua                                                     *
--*       File Created:      Monday, 24th February 2020 02:19                                      *
--*       Author:            [TR] Kiwi                                                             *
--*       Last Modified:     Friday, 9th April 2021 21:16                                      *
--*       Modified By:       [TR] Kiwi                                                             *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("deepcore/std/class")
require("eawx-util/StoryUtil")

BountyHunters = class()

function BountyHunters:new(gc)
    --Table With bounty hunters
    self.BountyHunterHeroes = {
        "Boba_Fett_Team",
        "Dengar_Team",
        "Bossk_Team",
		"Menndo_Team",
		"Snoova_Team",
		"Labansat_Team",
		"Dej_Vennor_Team"
    }
    self.PossibleRecruiters = {
        "EMPIRE",
        "ERIADU_AUTHORITY",
        "GREATER_MALDROOD",
        "PENTASTAR",
        "ZSINJ_EMPIRE",
		"CORPORATE_SECTOR"
    }
    --galactic_conquest class
    self.gc = gc
    --attach listener to production finished event
    self.gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
end

function BountyHunters:on_production_finished(planet, object_type_name)
    --Logger:trace("entering BountyHunters:on_production_finished")
    if object_type_name ~= "RANDOM_BOUNTY_HUNTER" then
        return
    end
    --Grabs random array index for bounty hunter table
    local bountyHunterIndex = GameRandom.Free_Random(1,table.getn(self.BountyHunterHeroes))
    --Grab Object Type for Random Bounty Hunter dummy
    local RandomBountyHunter = Find_First_Object("Random_Bounty_Hunter")
    --Grab selected bounty hunter via random index
    local bounty_hunter_to_spawn = self.BountyHunterHeroes[bountyHunterIndex]
    --Remove selected bounty hunter from table
    table.remove(self.BountyHunterHeroes, bountyHunterIndex)
    
    if TestValid(RandomBountyHunter) then
        --Grab Owner and Location of random bounty hunter dummy
        local BountyHunterOwner = RandomBountyHunter.Get_Owner()
        local BountyHunterLocation = RandomBountyHunter.Get_Planet_Location()
        --Grab Object type for selected bounty hunter
        local BountyHunterUnit = Find_Object_Type(bounty_hunter_to_spawn)
        --Spawn Bounty hunter at location of bounty hunter dummy for bounty hunter owner
        Spawn_Unit(BountyHunterUnit, BountyHunterLocation, BountyHunterOwner)
        --Despawn dummy object
        RandomBountyHunter.Despawn()
        --If no objects are left in table, lock the dummy and detach listener from production finished event
        if table.getn(self.BountyHunterHeroes) == 0 then
            for _, faction in pairs(self.PossibleRecruiters) do
                Find_Player(faction).Lock_Tech(Find_Object_Type("RANDOM_BOUNTY_HUNTER"))
            end
            self.gc.Events.GalacticProductionFinished:detach_listener(self.on_production_finished, self)
        end
    end
end
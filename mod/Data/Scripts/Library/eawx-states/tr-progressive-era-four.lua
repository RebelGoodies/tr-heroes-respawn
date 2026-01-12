require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("eawx-util/ChangeOwnerUtilities")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)

        GlobalValue.Set("CURRENT_ERA", 4)

        self.LeaderApproach = false

        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")

        Find_Player("Empire").Lock_Tech(Find_Object_Type("Dummy_Regicide_Palpatine"))

        StoryUtil.SetPlanetRestricted("BYSS", 0)
        StoryUtil.SetPlanetRestricted("THE_MAW", 1)
        StoryUtil.SetPlanetRestricted("TSOSS", 1)
        StoryUtil.SetPlanetRestricted("DOORNIK", 1)
        StoryUtil.SetPlanetRestricted("ZFELL", 1)
        StoryUtil.SetPlanetRestricted("NZOTH", 1)
        StoryUtil.SetPlanetRestricted("JTPTAN", 1)
        StoryUtil.SetPlanetRestricted("POLNEYE", 1)
        StoryUtil.SetPlanetRestricted("PRILDAZ", 1)
		StoryUtil.SetPlanetRestricted("KATANA_SPACE", 0)

        Story_Event("PALPATINE_REQUEST_COMPLETED")
		Story_Event("GC_CORUSCANT_EVAC_LONG")

        if Find_Player("local") == Find_Player("Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_PALPATINE_ERA", 15, nil, "Emperor_Loop", 0)
        elseif Find_Player("local") == Find_Player("Rebel") then
            StoryUtil.Multimedia("TEXT_CONQUEST_PALPATINE_NR_INTRO_TWO", 15, nil, "Mon_Mothma_Loop", 0)
            Story_Event("NEWREP_PALPATINE_STARTED")
        elseif Find_Player("local") == Find_Player("EmpireoftheHand") then
            StoryUtil.Multimedia("TEXT_CONQUEST_PALPATINE_EOTH_INTRO_ONE", 15, nil, "Parck_Loop", 0)
        end

        if self.entry_time <= 5 then
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFourStartSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end

            
        else

            self.DespawnList = {
                "Dummy_Regicide_Palpatine",
                "Aralani_Frontier",
                "Mon_Mothma",
                "Covell_AT_AT_Walker",
                "Judicator_Star_Destroyer",
                "Relentless_Star_Destroyer",
                "Joruus_Cboath",
                "Dezon_Constrainer",
                "Drost",
                "Chimera",
                "Corellian_Gunboat_Ferrier",
                "Rukh"
            }
			
			Story_Event("REMOVE_PHENNIR")

            if self.Active_Planets["BYSS"] then
                local planet = FindPlanet("Byss")
                if planet.Get_Owner() ~= Find_Player("Neutral") then
                    ChangePlanetOwnerAndRetreat(planet, Find_Player("Empire"))
                end
                local spawn_list_Palpatine = {
                        -- "Empire_Shipyard_Level_Four",
                        -- "Empire_Star_Base_4",
                        -- "Empire_MoffPalace",
                        -- "E_Ground_Barracks",
                        -- "E_Ground_Light_Vehicle_Factory",
                        -- "E_Ground_Heavy_Vehicle_Factory",
                        -- "E_Ground_Advanced_Vehicle_Factory",
                        -- "Ground_Empire_Hypervelocity_Gun",
                        "Imperial_Stormtrooper_Squad",
                        "Imperial_Stormtrooper_Squad",
                        "Imperial_AT_ST_Company",
                        "Imperial_AT_PT_Company",
                        "Imperial_IDT_Group",
                        "Imperial_Century_Tank_Company",
                        "Imperial_AT_AT_Company",
                        "Imperial_XR85_Company",
                        "Generic_Secutor",
                        "Generic_Tector",
                        "Generic_Star_Destroyer_Two",
                        "Generic_Star_Destroyer_Two",
                        "Generic_Star_Destroyer",
                        "Generic_Procursator",
                        "Generic_Procursator",
                        "MTC_Support",
                        "MTC_Support",
                        "Generic_Acclamator_Assault_Ship_Leveler",
                        "Generic_Acclamator_Assault_Ship_Leveler",
                        "Vindicator_Cruiser",   
                        "Vindicator_Cruiser",   
                        "Vindicator_Cruiser",   
                        "Victory_II_Frigate",
                        "Victory_II_Frigate",
                        "Raider_Corvette",
                        "Raider_Corvette",
                        "Raider_Corvette",
                        "Raider_Corvette",
                        "Raider_Corvette",
                        "Raider_Corvette",
                        "Raider_Corvette",     
                        "Raider_Corvette",
                        "CR90_Zsinj",
                        "CR90_Zsinj",
                        "CR90_Zsinj",
                        "CR90_Zsinj",
                        "CR90_Zsinj",
                        "CR90_Zsinj"
                }
                SpawnList(spawn_list_Palpatine, planet, Find_Player("Empire"), true, false)
            end

            for _, object in pairs(self.DespawnList) do
                checkObject = Find_First_Object(object) -- doesn't work if hero respawning
                if TestValid(checkObject) then
                    checkObject.Despawn()
				else
					Story_Event("ERA_FOUR_START") -- Manual xml removal
					break
				end
            end

            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFourProgressSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end

            UnitUtil.ReplaceAtLocation("Home_One", "Galactic_Voyager")

			crossplot:publish("ERA_FOUR_TRANSITION", "empty")
        end

        
    end,
    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.LeaderApproach == false) and (self.current_time - self.entry_time) <= 402 then
            self.LeaderApproach = true
            if Find_Player("local") == Find_Player("Empire") then
                StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_JAX_CONTACT", 15, nil, nil, 0)
                Story_Event("JAX_REQUEST_STARTED")
                Find_Player("Empire").Unlock_Tech(Find_Object_Type("Dummy_Regicide_Jax"))

            end
        end
    end,
    on_exit = function(self, state_context)
    end
}
require("eawx-util/StoryUtil")
require("eawx-util/ChangeOwnerUtilities")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)

        GlobalValue.Set("CURRENT_ERA", 6)

        self.LeaderApproach = false
        
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")

        Find_Player("Empire").Lock_Tech(Find_Object_Type("Dummy_Regicide_Daala"))

        StoryUtil.SetPlanetRestricted("BYSS", 0)
        StoryUtil.SetPlanetRestricted("THE_MAW", 0)
        StoryUtil.SetPlanetRestricted("TSOSS", 0)
        StoryUtil.SetPlanetRestricted("DOORNIK", 1)
        StoryUtil.SetPlanetRestricted("ZFELL", 1)
        StoryUtil.SetPlanetRestricted("NZOTH", 1)
        StoryUtil.SetPlanetRestricted("JTPTAN", 1)
        StoryUtil.SetPlanetRestricted("POLNEYE", 1)
        StoryUtil.SetPlanetRestricted("PRILDAZ", 1)
		StoryUtil.SetPlanetRestricted("KATANA_SPACE", 0)

        Story_Event("DAALA_REQUEST_COMPLETED")

        if Find_Player("local") == Find_Player("Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_DAALA_ERA", 15, nil, "Daala_Loop", 0)
        elseif Find_Player("local") == Find_Player("Rebel") then
            StoryUtil.Multimedia("TEXT_CONQUEST_DAALA_NR_INTRO_ONE", 15, nil, "Leia_Loop", 0)
            Story_Event("NEWREP_DAALA_STARTED")
        elseif Find_Player("local") == Find_Player("EmpireoftheHand") then
            StoryUtil.Multimedia("TEXT_CONQUEST_DAALA_EOTH_INTRO_ONE", 15, nil, "Parck_Loop", 0)
        end

        if self.entry_time <= 5 then
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraSixStartSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end

            if self.Active_Planets["BYSS"] then
                Destroy_Planet("Byss")
            end
            if self.Active_Planets["DA_SOOCHA"] then
                Destroy_Planet("Da_Soocha")
            end
            
        else

            if self.Active_Planets["THE_MAW"] then
                local planet = FindPlanet("The_Maw")
                if planet.Get_Owner() ~= Find_Player("Neutral") then
                    ChangePlanetOwnerAndRetreat(planet, Find_Player("Empire"))
                end
                local spawn_list_Daala = {
                	-- "Empire_Shipyard_Level_Three",
                	-- "Empire_Star_Base_4",
                	-- "Empire_MoffPalace",
                	-- "E_Ground_Barracks",
                	"Imperial_Stormtrooper_Squad",
                	"Imperial_Stormtrooper_Squad",
                    "Generic_Star_Destroyer",
                    "Generic_Star_Destroyer",
                    "Generic_Star_Destroyer",
                    "Crusader_Gunship",
                    "Crusader_Gunship",
                    "Strike_Cruiser",
                    "Strike_Cruiser",
                    "Carrack_Cruiser",
                    "Carrack_Cruiser"
                }
                SpawnList(spawn_list_Daala, planet, Find_Player("Empire"), true, false)

            end

            self.DespawnList = {
                "Dummy_Regicide_Daala",
                "Emperors_Revenge_Star_Destroyer",
                "Jeratai_Allegiance",
                "Xexus_Shev",
                "Kooloota-Fyf",
                "Carnor_Jax",
                "Mahd_Windcaller",
                "Manos",
                "Za",
                "Immodet_Floating_Fortress"
            }

            for _, object in pairs(self.DespawnList) do
                checkObject = Find_First_Object(object) -- doesn't work if hero respawning
                if TestValid(checkObject) then
                    checkObject.Despawn()
				else
					Story_Event("ERA_SIX_START") -- Manual xml removal
					break
                end
            end

            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraSixProgressSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end
			
			crossplot:publish("ERA_SIX_TRANSITION", "empty")

        end

    end,
    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.LeaderApproach == false) then
            self.LeaderApproach = true
            if Find_Player("local") == Find_Player("Empire") then
                StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_PELLAEON_CONTACT", 15, nil, "Daala_Loop", 0)
                Story_Event("PELLAEON_REQUEST_STARTED")
                Find_Player("Empire").Unlock_Tech(Find_Object_Type("Dummy_Regicide_Pellaeon"))
            end
        end
    end,
    on_exit = function(self, state_context)
    end
}
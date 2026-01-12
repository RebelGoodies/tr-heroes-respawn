require("eawx-util/StoryUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)


        GlobalValue.Set("CURRENT_ERA", 3)
        
        self.LeaderApproach = false

        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")

        Find_Player("Empire").Lock_Tech(Find_Object_Type("Dummy_Regicide_Thrawn"))

        StoryUtil.SetPlanetRestricted("BYSS", 1)
        StoryUtil.SetPlanetRestricted("THE_MAW", 1)
        StoryUtil.SetPlanetRestricted("TSOSS", 1)
        StoryUtil.SetPlanetRestricted("DOORNIK", 1)
        StoryUtil.SetPlanetRestricted("ZFELL", 1)
        StoryUtil.SetPlanetRestricted("NZOTH", 1)
        StoryUtil.SetPlanetRestricted("JTPTAN", 1)
        StoryUtil.SetPlanetRestricted("POLNEYE", 1)
        StoryUtil.SetPlanetRestricted("PRILDAZ", 1)
		StoryUtil.SetPlanetRestricted("KATANA_SPACE", 1)

        Story_Event("THRAWN_REQUEST_COMPLETED")
		Story_Event("GC_DELTA_SOURCE_INIT")
		Story_Event("GC_KATANA_FLEET")

        if Find_Player("local") == Find_Player("Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_THRAWN_ERA", 15, nil, "Thrawn_Loop", 0)
        elseif Find_Player("local") == Find_Player("Rebel") then
            StoryUtil.Multimedia("TEXT_CONQUEST_THRAWN_NR_INTRO_ONE", 15, nil, "Mon_Mothma_Loop", 0)
            Story_Event("NEWREP_THRAWN_STARTED")
        elseif Find_Player("local") == Find_Player("EmpireoftheHand") then
            StoryUtil.Multimedia("TEXT_CONQUEST_THRAWN_EOTH_INTRO_TWO", 15, nil, "Parck_Loop", 0)
        end

        if self.entry_time <= 5 then
             self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraThreeStartSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end
            
        else

            self.DespawnList = {
                "Dummy_Regicide_Thrawn",
                "Grey_Wolf",
                "Lusankya",
                "Reckoning_Star_Destroyer",
                "Corrupter_Star_Destroyer",   
                "Agonizer_Star_Destroyer",
				"Vorru",
				"Grath_Stormtrooper",
				"Veers_AT_AT_Walker"
            }
			Story_Event("REMOVE_DLARIT")
			
            for _, object in pairs(self.DespawnList) do
                local checkObject = Find_First_Object(object) -- doesn't work if hero respawning
                if TestValid(checkObject) then
                    checkObject.Despawn()
				else
					Story_Event("ERA_THREE_START") -- Manual xml removal
					break
                end
            end
            
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraThreeProgressSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end
			
			crossplot:publish("ERA_THREE_TRANSITION", "empty")
        end
    
    end,
    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.LeaderApproach == false) then
            self.LeaderApproach = true
            if Find_Player("local") == Find_Player("Empire") then
                StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_PALPATINE_CONTACT", 15, nil, "Emperor_Loop", 0)
                Story_Event("PALPATINE_REQUEST_STARTED")
                Find_Player("Empire").Unlock_Tech(Find_Object_Type("Dummy_Regicide_Palpatine"))
            end
        end
    end,
    on_exit = function(self, state_context)
    end
}
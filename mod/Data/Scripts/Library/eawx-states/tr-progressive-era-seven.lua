require("eawx-util/StoryUtil")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)

        GlobalValue.Set("CURRENT_ERA", 7)

        self.LeaderApproach = false
        self.TerrikApproach = false
        
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")

        Find_Player("Empire").Lock_Tech(Find_Object_Type("Dummy_Regicide_Pellaeon"))

        StoryUtil.SetPlanetRestricted("BYSS", 0)
        StoryUtil.SetPlanetRestricted("THE_MAW", 0)
        StoryUtil.SetPlanetRestricted("TSOSS", 0)
        StoryUtil.SetPlanetRestricted("DOORNIK", 0)
        StoryUtil.SetPlanetRestricted("ZFELL", 0)
        StoryUtil.SetPlanetRestricted("NZOTH", 0)
        StoryUtil.SetPlanetRestricted("JTPTAN", 0)
        StoryUtil.SetPlanetRestricted("POLNEYE", 0)
        StoryUtil.SetPlanetRestricted("PRILDAZ", 0)
		StoryUtil.SetPlanetRestricted("KATANA_SPACE", 0)

        Story_Event("PELLAEON_REQUEST_COMPLETED")
		Story_Event("GC_BLACK_FLEET_CRISIS")

        if Find_Player("local") == Find_Player("Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_PELLAEON_ERA", 15, nil, "Pellaeon_Loop", 0)
        elseif Find_Player("local") == Find_Player("Rebel") then
            StoryUtil.Multimedia("TEXT_CONQUEST_PELLAEON_NR_INTRO_ONE", 15, nil, "Gavrisom_Loop", 0)
            Story_Event("NEWREP_PELLAEON_STARTED")
        elseif Find_Player("local") == Find_Player("EmpireoftheHand") then
            StoryUtil.Multimedia("TEXT_CONQUEST_PELLAEON_EOTH_INTRO_ONE", 15, nil, "Parck_Loop", 0)
        end

        if self.entry_time <= 5 then
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraSevenStartSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end
			
			crossplot:publish("CONQUER_NZOTH", "empty")

            if self.Active_Planets["BYSS"] then
                Destroy_Planet("Byss")
            end
            if self.Active_Planets["DA_SOOCHA"] then
                Destroy_Planet("Da_Soocha")
            end
            if self.Active_Planets["CARIDA"] then
                Destroy_Planet("Carida")
            end
            if self.Active_Planets["EOLSHA"] then
                Destroy_Planet("EolSha")
            end
            
        else
            self.DespawnList = {
                "Dummy_Regicide_Pellaeon",
                "Errant_Venture",
                "Gorgon",
				"Ardax_Vendetta",
                "Odosk",
				"Fredja",
                "Tol_Sivron"
            }
			
			Story_Event("REMOVE_ROGUE_SQUADRON")

            for _, object in pairs(self.DespawnList) do
                checkObject = Find_First_Object(object)
                if TestValid(checkObject) then
                    checkObject.Despawn()
                end
            end

            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraSevenProgressSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end
			
			crossplot:publish("CONQUER_NZOTH", "empty")

			crossplot:publish("ERA_SEVEN_TRANSITION", "empty")
        end

    end,
    on_update = function(self, state_context)

        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.TerrikApproach == false) then
            self.TerrikApproach = true
            crossplot:publish("TERRIK_UPGRADE_START", "empty")
        end
    end,
    on_exit = function(self, state_context)
    end
}
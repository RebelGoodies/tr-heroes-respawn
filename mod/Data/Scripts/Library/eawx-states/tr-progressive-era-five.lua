require("eawx-util/StoryUtil")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)

        GlobalValue.Set("CURRENT_ERA", 5)

        self.LeaderApproach = false
        
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")

        Find_Player("Empire").Lock_Tech(Find_Object_Type("Dummy_Regicide_Jax"))

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

        Story_Event("JAX_REQUEST_COMPLETED")

        if Find_Player("local") == Find_Player("Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_JAX_ERA", 15, nil, "Carnor_Loop", 0)
        elseif Find_Player("local") == Find_Player("Rebel") then
            StoryUtil.Multimedia("TEXT_CONQUEST_JAX_NR_INTRO_ONE", 15, nil, "Mon_Mothma_Loop", 0)
            Story_Event("NEWREP_JAX_STARTED")
        elseif Find_Player("local") == Find_Player("EmpireoftheHand") then
            StoryUtil.Multimedia("TEXT_CONQUEST_PALPATINE_EOTH_INTRO_ONE", 15, nil, "Parck_Loop", 0)
        end

        if self.entry_time <= 5 then
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFiveStartSet")
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

            self.DespawnList = {
                "Dummy_Regicide_Jax",
                "Emperor_Palpatine",
                "Sedriss",
                "Veers_AT_AT_Walker",
                "Praji_Secutor",
                "Umak_Leth",
                "Chimera_Pellaeon_Vice",
                "Cronal_Singularity",
                "Grath_Dark_Stormtrooper"
            }

            for _, object in pairs(self.DespawnList) do
                checkObject = Find_First_Object(object)
                if TestValid(checkObject) then
                    checkObject.Despawn()
                end
            end
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFiveProgressSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end

			crossplot:publish("ERA_FIVE_TRANSITION", "empty")
        end

    end,
    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.LeaderApproach == false) then
            self.LeaderApproach = true
            if Find_Player("local") == Find_Player("Empire") then
                StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_DAALA_CONTACT", 15, nil, "Daala_Loop", 0)
                Story_Event("DAALA_REQUEST_STARTED")
                Find_Player("Empire").Unlock_Tech(Find_Object_Type("Dummy_Regicide_Daala"))

            end
        end
    end,
    on_exit = function(self, state_context)
    end
}
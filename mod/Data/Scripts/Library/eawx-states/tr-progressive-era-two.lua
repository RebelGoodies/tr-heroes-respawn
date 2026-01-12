require("eawx-util/StoryUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)

        GlobalValue.Set("CURRENT_ERA", 2)

        self.LeaderApproach = false
        
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")

        Find_Player("Empire").Lock_Tech(Find_Object_Type("Project_Ambition_Dummy"))

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

        if self.Active_Planets["KESSEL"] then
            if FindPlanet("KESSEL").Get_Owner() == Find_Player("Warlords") then
                local spawn_list = {"Tigellinus_Avatar", "Hissa_Moffship"}
                SpawnList(spawn_list, FindPlanet("KESSEL"), Find_Player("Warlords"), true, false)
            end
        end

        if self.Active_Planets["KALIST"] then
            if FindPlanet("KALIST").Get_Owner() == Find_Player("Warlords") then
                local spawn_list = {"Whirlwind_Star_Destroyer"}
                SpawnList(spawn_list, FindPlanet("KALIST"), Find_Player("Warlords"), true, false)
            end
        end

        Story_Event("PROJECT_AMBITION_COMPLETED")

        if Find_Player("local") == Find_Player("Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_YSANNE_ERA", 15, nil, "Isard_Loop", 0)
        elseif Find_Player("local") == Find_Player("Rebel") then
            StoryUtil.Multimedia("TEXT_CONQUEST_ISARD_NR_INTRO_MOTHMA", 15, nil, "Mon_Mothma_Loop", 0)
            Story_Event("NEWREP_ISARD_STARTED")
        end

        if self.entry_time <= 5 then
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraTwoStartSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end

            if Find_Player("local") == Find_Player("EmpireoftheHand") then
                StoryUtil.Multimedia("TEXT_CONQUEST_THRAWN_EOTH_INTRO_ONE", 15, nil, "Thrawn_Loop", 0)
            end
    
        else

            self.DespawnList = {
                "Project_Ambition_Dummy",
                "Sate_Pestage",
                "Carvin",
                "Kermen_Belligerent",
                "Brashin_Inquisitor",
                "Okins_Allegiance"
            }

            for _, object in pairs(self.DespawnList) do
                local checkObject = Find_First_Object(object)
                if TestValid(checkObject) then
                    checkObject.Despawn()
                end
            end
            
            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraTwoProgressSet")
            for faction, herolist in pairs(self.Starting_Spawns) do
                for planet, spawnlist in pairs(herolist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, spawnlist)  
                end
            end

			crossplot:publish("ERA_TWO_TRANSITION", "empty")
        end

    end,
    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.LeaderApproach == false) then
            self.LeaderApproach = true
            if Find_Player("local") == Find_Player("Empire") then
                StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_THRAWN_CONTACT", 15, nil, "Thrawn_Loop", 0)
                Story_Event("THRAWN_REQUEST_STARTED")
                Find_Player("Empire").Unlock_Tech(Find_Object_Type("Dummy_Regicide_Thrawn"))
            end
        end
    end,
    on_exit = function(self, state_context)
    end
}
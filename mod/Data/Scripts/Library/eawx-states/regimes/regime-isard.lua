require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)

        self.LeaderApproach = false
        GlobalValue.Set("REGIME_INDEX", 2)
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
        self.progress = GlobalValue.Get("PROGRESS_REGIME")

        Find_Player("Empire").Lock_Tech(Find_Object_Type("Project_Ambition_Dummy"))
        Find_Player("Empire").Lock_Tech(Find_Object_Type("Dummy_Regicide_CCoGM"))

        if self.Active_Planets["KALIST"] then
            if FindPlanet("KALIST").Get_Owner() == Find_Player("Warlords") then
                local spawn_list = {"Whirlwind_Star_Destroyer"}
                SpawnList(spawn_list, FindPlanet("KALIST"), Find_Player("Warlords"), true, false)
            end
        end

        Story_Event("PROJECT_AMBITION_COMPLETED")

        if Find_Player("local") == Find_Player("Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_YSANNE_ERA", 15, nil, "Isard_Loop", 0)
        end

        if self.entry_time <= 5 then

            UnitUtil.SetLockList("EMPIRE", {
				"Generic_Praetor",
				"Eidolon",
				"Imperial_Boarding_Shuttle",
				"TaggeCo_HQ",
				"Incom_HQ",
				"SoroSuub_HQ",
				"Mekuun_HQ",
				"Cygnus_HQ",
				"Imperial_PX10_Company",
				-- Historical-only units
				"Imperial_Navy_Commando_Squad"
            }, false)
			
			if Find_Player("local") == Find_Player("Empire") then
				Story_Event("ISARD_WELCOME")
			end

            StoryUtil.SetPlanetRestricted("BYSS", 1)
            StoryUtil.SetPlanetRestricted("THE_MAW", 1)
            StoryUtil.SetPlanetRestricted("KATANA_SPACE", 1)
    
        else

            StoryUtil.SetPlanetRestricted("THYFERRA", 0)
            StoryUtil.SetPlanetRestricted("KESSEL", 0)

            if self.Active_Planets["THYFERRA"] then
                local planet = FindPlanet("Thyferra")
                if planet.Get_Owner() ~= Find_Player("Neutral") then
                        ChangePlanetOwnerAndReplace(planet, Find_Player("Empire"))
                end
            end

            self.IsardSpawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSets")
            for planet, spawnlist in pairs(self.IsardSpawns["ISARD"]) do
                StoryUtil.SpawnAtSafePlanet(planet, Find_Player("Empire"), self.Active_Planets, spawnlist)  
            end

            self.CCoGMSpawns = require("eawx-mod-icw/spawn-sets/EraTwoCCoGMProgressSetWarlord")
            if self.Active_Planets["KESSEL"] then
                for planet, spawnlist in pairs(self.CCoGMSpawns) do
                    SpawnList(spawnlist, FindPlanet("Kessel"), Find_Player("Warlords"), true, false)  
                end
            end


            UnitUtil.SetLockList("EMPIRE", {
				"Eidolon"
            }, false)
				
			UnitUtil.SetLockList("EMPIRE", {
				"Strike_Cruiser"
			})

            UnitUtil.DespawnList{
                "Project_Ambition_Dummy",
				"Sate_Pestage",
                "Carvin",
                "Kermen_Belligerent",
				"Reckoning_Star_Destroyer",
                "Okins_Allegiance"
            }
            
        end

    end,
    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.LeaderApproach == false) and (self.progress == true) then
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
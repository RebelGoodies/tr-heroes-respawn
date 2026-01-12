require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)
	
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
		GlobalValue.Set("REGIME_INDEX", 3)
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
        
        Find_Player("Empire").Lock_Tech(Find_Object_Type("Dummy_Regicide_Thrawn"))

        Story_Event("THRAWN_REQUEST_COMPLETED")
        if self.Active_Planets["CORUSCANT"] then
		    Story_Event("GC_DELTA_SOURCE_INIT")
        end
        if self.Active_Planets["KATANA_SPACE"] then
            Story_Event("GC_KATANA_FLEET")
        end
		
		Story_Event("THRAWN_REQUEST_COMPLETED")

		if Find_Player("local") == Find_Player("Empire") then
			StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_THRAWN_ERA", 15, nil, "Thrawn_Loop", 0)
		end

        if self.entry_time <= 5 then

            StoryUtil.SetPlanetRestricted("BYSS", 1)
            StoryUtil.SetPlanetRestricted("THE_MAW", 1)

            UnitUtil.SetLockList("EMPIRE", {
				"Generic_Executor",
				"Generic_Praetor",
				"Eidolon",
				"TaggeCo_HQ",
				"Incom_HQ",
				"SoroSuub_HQ",
				"Imperial_PX10_Company",
				-- Historical-only units
				"Imperial_Navy_Commando_Squad"
            }, false)
			
			UnitUtil.SetLockList("EMPIRE", {
				"Imperial_Boarding_Shuttle",
				"Mekuun_HQ",
				"Cygnus_HQ",
				"Ysalamiri_Stormtrooper_Squad",
				"Noghri_Assassin_Squad"
            })
			
			if Find_Player("local") == Find_Player("Empire") then
				Story_Event("THRAWN_WELCOME")
			end
              
        else
            StoryUtil.SetPlanetRestricted("KATANA_SPACE", 0)

            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSets")
            for planet, spawnlist in pairs(self.Starting_Spawns["THRAWN"]) do
                StoryUtil.SpawnAtSafePlanet(planet, Find_Player("Empire"), self.Active_Planets, spawnlist)  
            end

            UnitUtil.SetLockList("EMPIRE", {
				"Generic_Executor",
				"YE_4_Squadron",
				"Imperial_PX10_Company",
				"Imperial_TNT_Company"
            }, false)
			
            UnitUtil.SetLockList("EMPIRE", {
				"Imperial_Boarding_Shuttle",
				"Beta_ETR_3_Squadron",
				"Mekuun_HQ",
				"Cygnus_HQ",
				"Ysalamiri_Stormtrooper_Squad",
				"Noghri_Assassin_Squad",
				"Imperial_AT_PT_Company"
            })
            
            UnitUtil.DespawnList{
                "Dummy_Regicide_Thrawn",
                "Grey_Wolf",
				"Brashin_Inquisitor",
				"Tal_Ashen_AT_AT_Walker",
				"Ysanne_Isard",
                "Lusankya",
                "Corrupter_Star_Destroyer",   
				"Devlia_IEC",
                "Agonizer_Star_Destroyer",
				"Vorru",
                "Hissa_Moffship",
                "Tigellinus_Avatar",
				"Jedgar",
				"Kadann",
				"Trioculus",
				"Dunhausen_Espa",
				"Muzzer_Whaladon",
				"Thistleborn_DarkGreeter",
				"Lanox_Hazard",
            }
			Story_Event("REMOVE_DLARIT")
            
        end
    
    end,
    on_update = function(self, state_context)
    end,
    on_exit = function(self, state_context)
    end
}
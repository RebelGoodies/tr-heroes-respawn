require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)
	
		self.Active_Planets = StoryUtil.GetSafePlanetTable()
		self.entry_time = GetCurrentTime()
		self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
	
		if self.Active_Planets["CIUTRIC"] then
			if FindPlanet("CIUTRIC").Get_Owner() == Find_Player("Warlords") then
				local check_list = {"Krennel_Warlord","Phulik_Binder","Darron_Direption","Brothic_Team"}
				local spawn_list = {}
				
				for i, check_object in pairs(check_list) do
					if not Find_First_Object(check_object) then
						table.insert(spawn_list,check_object)
					end
				end
				
				SpawnList(spawn_list,FindPlanet("CIUTRIC"),Find_Player("Warlords"),true,false)
			end
		end
			
		UnitUtil.SetLockList("EMPIRE", {
			"Imperial_Boarding_Shuttle",
			"Mekuun_HQ",
			"Cygnus_HQ",
			"Ysalamiri_Stormtrooper_Squad",
			"Noghri_Assassin_Squad"
		}, false)
		
		self.despawn = GlobalValue.Get("REGIME_DESPAWN")
		if self.despawn then
			 UnitUtil.DespawnList{
				"Corellian_Gunboat_Ferrier",
				"Judicator_Star_Destroyer",
				"Relentless_Star_Destroyer",
				"Dezon_Constrainer",
				"Covell_AT_AT_Walker",
				"Joruus_Cboath",   
				"Drost",
				"Rukh",
				"Reckoning_Star_Destroyer",
			}
			Story_Event("REMOVE_PHENNIR")

			crossplot:publish("OMIT_RESPAWN_BULK","EMPIRE",{
					"Chimera", --Leader Thrawn
					"Corellian_Gunboat_Ferrier",
					"Judicator_Star_Destroyer",
					"Relentless_Star_Destroyer",
					"Dezon_Constrainer",
					"General_Covell_Team",
					"Joruus_Cboath_Team",
					"Drost_Team",
					"Rukh_Team",
					"Reckoning_Star_Destroyer",
					"181st_TIE_Interceptor_Squadron", --Squadron Turr_Phennir_TIE_Interceptor
				})
		end
		
		if Find_Player("local") == Find_Player("Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_THRAWN_DEATH", 15, nil, "Imperial_Naval_Officer_Loop", 0)
        end
		
    end,
    on_update = function(self, state_context)
    end,
    on_exit = function(self, state_context)
    end
}
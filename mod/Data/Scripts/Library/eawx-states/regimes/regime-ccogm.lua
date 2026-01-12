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
			StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_CCOGM_ERA", 15, nil, "Hissa_Loop", 0)
		end

		if self.entry_time <= 5 then

			StoryUtil.SetPlanetRestricted("BYSS", 1)
			StoryUtil.SetPlanetRestricted("THE_MAW", 1)
			StoryUtil.SetPlanetRestricted("KATANA_SPACE", 1)

			UnitUtil.SetLockList("EMPIRE", {
				"Generic_Praetor",
				"Eidolon",
				"Imperial_Boarding_Shuttle",
				"Beta_ETR_3_Squadron",
				"TaggeCo_HQ",
				"Incom_HQ",
				"SoroSuub_HQ",
				"Mekuun_HQ",
				"Cygnus_HQ",
				"Imperial_AT_PT_Company",
				-- Historical-only units
				"Imperial_Navy_Commando_Squad"
			}, false)
			
			UnitUtil.SetLockList("EMPIRE", {
				"YE_4_Squadron",
				"Imperial_PX10_Company",
				"Imperial_TNT_Company"
			})
	
		else

			StoryUtil.SetPlanetRestricted("THYFERRA", 0)
			StoryUtil.SetPlanetRestricted("KESSEL", 0)

			if self.Active_Planets["KESSEL"] then
				local planet = FindPlanet("Kessel")
				if planet.Get_Owner() ~= Find_Player("Neutral") then
					ChangePlanetOwnerAndReplace(planet, Find_Player("Empire"))
				end
			end

			self.IsardSpawns = require("eawx-mod-icw/spawn-sets/EraTwoIsardProgressSetWarlord")
			for planet, spawnlist in pairs(self.IsardSpawns) do
				StoryUtil.SpawnAtSafePlanet(planet, Find_Player("Warlords"), self.Active_Planets, spawnlist)  
			end

			self.CCoGMSpawns = require("eawx-mod-icw/spawn-sets/EraTwoCCoGMProgressSet")
			for planet, spawnlist in pairs(self.CCoGMSpawns) do
				StoryUtil.SpawnAtSafePlanet(planet, Find_Player("Empire"), self.Active_Planets, spawnlist)  
			end

			UnitUtil.SetLockList("EMPIRE", {
				"Eidolon",
				"Beta_ETR_3_Squadron",
				"Imperial_AT_PT_Company"
			}, false)
				
			UnitUtil.SetLockList("EMPIRE", {
				"Strike_Cruiser",
				"YE_4_Squadron",
				"Imperial_PX10_Company",
				"Imperial_TNT_Company"
			})

			UnitUtil.DespawnList{
				"Dummy_Regicide_CCoGM",
				"Sate_Pestage",
				"Carvin",
				"Kermen_Belligerent",
				"Tal_Ashen_AT_AT_Walker",
				"Reckoning_Star_Destroyer",
				"Brashin_Inquisitor",
				"Okins_Allegiance"
			}

			
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
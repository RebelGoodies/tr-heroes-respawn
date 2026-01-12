require("eawx-util/StoryUtil")
require("eawx-util/ChangeOwnerUtilities")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)

        self.LeaderApproach = false
        self.Leading_Empire = GlobalValue.Get("IMPERIAL_REMNANT")
        GlobalValue.Set("REGIME_INDEX", 6)
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
        self.progress = GlobalValue.Get("PROGRESS_REGIME")

        self.ImperialTable = {
            "Empire",
            "Greater_Maldrood",
            "Zsinj_Empire",
            "Eriadu_Authority",
            "Pentastar"
        }
        for _, faction in pairs(self.ImperialTable) do
            Find_Player(faction).Lock_Tech(Find_Object_Type("Dummy_Regicide_Daala"))
        end

        Story_Event("DAALA_REQUEST_COMPLETED")

		if Find_Player("local") == Find_Player(self.Leading_Empire) then
			StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_DAALA_ERA", 15, nil, "Daala_Loop", 0)
		end

        if self.entry_time <= 5 then

            UnitUtil.SetLockList("EMPIRE", {
				"Eidolon",
				"IPV1_System_Patrol_Craft",
                "Imperial_Boarding_Shuttle",
				"Ysalamiri_Stormtrooper_Squad",
				"Noghri_Assassin_Squad",
				"Imperial_PX10_Company",
                "SoroSuub_HQ",
				"Mekuun_HQ",
                "Cygnus_HQ",
                "TaggeCo_HQ",
				-- Historical-only units
				"Imperial_Navy_Commando_Squad"
            }, false) 
		
			UnitUtil.SetLockList("EMPIRE", {
				"Nebulon_B_Empire",
				"Crusader_Gunship",
				"Imperial_Dwarf_Spider_Droid_Company"
            })
			
			if Find_Player("local") == Find_Player("Empire") then
				Story_Event("DAALA_WELCOME")
			end

        else

            StoryUtil.SetPlanetRestricted("THE_MAW", 0)
			
			self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSets")
            for planet, spawnlist in pairs(self.Starting_Spawns["DAALA"]) do
                StoryUtil.SpawnAtSafePlanet(planet, Find_Player(self.Leading_Empire), self.Active_Planets, spawnlist)  
            end

            UnitUtil.SetLockList("EMPIRE", {
				"IPV1_System_Patrol_Craft",
            }, false)

            --Regular Imperial asset progression
            UnitUtil.SetLockList("EMPIRE", {
				"Generic_Executor",
                "Incom_HQ",
				"Nebulon_B_Empire",
				"Crusader_Gunship",
				"Imperial_Dwarf_Spider_Droid_Company"
            })

            if self.Active_Planets["THE_MAW"] then
                local planet = FindPlanet("The_Maw")
                if planet.Get_Owner() ~= Find_Player("Neutral") then
                    ChangePlanetOwnerAndRetreat(planet, Find_Player(self.Leading_Empire))
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
                SpawnList(spawn_list_Daala, planet, Find_Player(self.Leading_Empire), true, false)

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
                checkObject = Find_First_Object(object)
                if TestValid(checkObject) then
                    checkObject.Despawn()
                end
            end
		
			crossplot:publish("ERA_SIX_TRANSITION", "empty")

        end

    end,
    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.LeaderApproach == false) and (self.progress == true) then
            self.LeaderApproach = true
            if Find_Player("local") == Find_Player(self.Leading_Empire) then
                StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_PELLAEON_CONTACT", 15, nil, "Daala_Loop", 0)
                Story_Event("PELLAEON_REQUEST_STARTED")
                Find_Player(self.Leading_Empire).Unlock_Tech(Find_Object_Type("Dummy_Regicide_Pellaeon"))
            end
        end
    end,
    on_exit = function(self, state_context)
    end
}
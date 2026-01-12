require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)

        self.Leading_Empire = GlobalValue.Get("IMPERIAL_REMNANT")
        GlobalValue.Set("REGIME_INDEX", 7)
        self.LeaderApproach = false
   
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
        self.progress = GlobalValue.Get("PROGRESS_REGIME")

        --Interim(?) edge case handling: applies to era 4+ starts when Daala is killed while Green has no safe planets
		--and is in "leading empire" status because no legitimacy winner has been declared.
		--If GovernmentEmpire.WinnerDetermined == true, none of this applies. ~Mord
        if self.Leading_Empire == "EMPIRE" and not StoryUtil.FindFriendlyPlanet(Find_Player("Empire")) then
		    GlobalValue.Set("GOV_EMP_DISABLE_MULTIMEDIA_HOLO", 1)
			StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_PELLAEON_EMPIRE_DEFEATED", 15, nil, "Pellaeon_Loop", 0, nil, {r = 255, g = 255, b = 100})
        end

        self.ImperialTable = {
            "Empire",
            "Greater_Maldrood",
            "Zsinj_Empire",
            "Eriadu_Authority",
            "Pentastar"
        }
        for _, faction in pairs(self.ImperialTable) do
            Find_Player(faction).Lock_Tech(Find_Object_Type("Dummy_Regicide_Pellaeon"))
        end

        Story_Event("PELLAEON_REQUEST_COMPLETED")

        -- Historic GCs with Pellaeon tend to be more unique scripts (at least one of them). Should be redone longer-term.
        if self.progress == true then
            if Find_Player("local") == Find_Player(self.Leading_Empire) then
                StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_PELLAEON_ERA", 15, nil, "Pellaeon_Loop", 0)
            end
        end

        if self.entry_time <= 5 then

            UnitUtil.SetLockList("EMPIRE", {
				"Eidolon",
                "IPV1_System_Patrol_Craft",
                "Imperial_Boarding_Shuttle",
				"Ysalamiri_Stormtrooper_Squad",
				"Noghri_Assassin_Squad",
				"Imperial_PX10_Company",
				"Mekuun_HQ",
                "Cygnus_HQ",
				"TaggeCo_HQ",
				-- Historical-only units
				"Imperial_Navy_Commando_Squad"
            }, false)
			
			UnitUtil.SetLockList("EMPIRE", {
				"RogrissUpgrade",
				"PellaeonUpgrade2",
				"Nebulon_B_Empire",
				"Crusader_Gunship",
				"Imperial_Dwarf_Spider_Droid_Company"
            })
			
			if Find_Player("local") == Find_Player("Empire") then
				Story_Event("PELLAEON_WELCOME")
			end
            
        else
		
			UnitUtil.DespawnList{
                "Dummy_Regicide_Pellaeon",
                "Gorgon",
				"Daala_Knight_Hammer",
				"Ardax_Vendetta",
                "Odosk",
				"Fredja",
                "Tol_Sivron",
				"Agonizer_Star_Destroyer"
            }

            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSets")
            for planet, spawnlist in pairs(self.Starting_Spawns["PELLAEON"]) do
                StoryUtil.SpawnAtSafePlanet(planet, Find_Player(self.Leading_Empire), self.Active_Planets, spawnlist)  
            end

            UnitUtil.SetLockList("EMPIRE", {
				"SoroSuub_HQ",
				"Crusader_Gunship"
            })
			
			UnitUtil.SetLockList(self.Leading_Empire, {
                "RogrissUpgrade",
				"PellaeonUpgrade2"
            })
		
        end

    end,
    on_update = function(self, state_context)
    end,
    on_exit = function(self, state_context)
    end
}
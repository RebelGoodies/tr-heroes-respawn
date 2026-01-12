require("eawx-util/StoryUtil")
require("eawx-util/UnitUtil")
require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")

return {
    on_enter = function(self, state_context)

        self.LeaderApproach = false
        self.Leading_Empire = GlobalValue.Get("IMPERIAL_REMNANT")
        GlobalValue.Set("REGIME_INDEX", 5)
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
        self.progress = GlobalValue.Get("PROGRESS_REGIME")

        --Interim(?) edge case handling: applies to era 4+ starts when Palpy is killed while Green has no safe planets
		--and is in "leading empire" status because no legitimacy winner has been declared.
		--If GovernmentEmpire.WinnerDetermined == true, none of this applies. ~Mord
        if self.Leading_Empire == "EMPIRE" and not StoryUtil.FindFriendlyPlanet(Find_Player("Empire")) then
		    GlobalValue.Set("GOV_EMP_DISABLE_MULTIMEDIA_HOLO", 1)
			StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_JAX_EMPIRE_DEFEATED", 15, nil, "Carnor_Loop", 0, nil, {r = 255, g = 255, b = 100})
            StoryUtil.SetPlanetRestricted("THE_MAW", 0)
        end

        self.ImperialTable = {
            "Empire",
            "Greater_Maldrood",
            "Zsinj_Empire",
            "Eriadu_Authority",
            "Pentastar"
        }
        for _, faction in pairs(self.ImperialTable) do
            Find_Player(faction).Lock_Tech(Find_Object_Type("Dummy_Regicide_Jax"))
        end

        Story_Event("JAX_REQUEST_COMPLETED")

        if Find_Player("local") == Find_Player(self.Leading_Empire) then
            StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_JAX_ERA", 15, nil, "Carnor_Loop", 0)
        end

        if self.entry_time <= 5 then

            StoryUtil.SetPlanetRestricted("THE_MAW", 1)

            UnitUtil.SetLockList("EMPIRE", {
                "Generic_Executor",
				"Eidolon",
                "Imperial_Boarding_Shuttle",
				"Ysalamiri_Stormtrooper_Squad",
				"Noghri_Assassin_Squad",
				"Imperial_Dark_Jedi_Squad",
				"Imperial_PX10_Company",
                "Incom_HQ",
                "SoroSuub_HQ",
                "Mekuun_HQ",
                "Cygnus_HQ",
				-- Historical-only units
				"Imperial_Navy_Commando_Squad"             
            }, false)
			
			if Find_Player("local") == Find_Player("Empire") then
				Story_Event("CARNOR_WELCOME")
			end
            
        else

            self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EmpireProgressSets")
            for planet, spawnlist in pairs(self.Starting_Spawns["CARNOR"]) do
                StoryUtil.SpawnAtSafePlanet(planet, Find_Player(self.Leading_Empire), self.Active_Planets, spawnlist)  
            end

            UnitUtil.SetLockList(self.Leading_Empire, {
				"Eclipse_Star_Destroyer",
				"Sovereign",
				"Hunter_Killer_Probot",
				"Imperial_Chrysalide_Company",
				"Imperial_Dark_Jedi_Squad",
				"Imperial_Dark_Stormtrooper_Squad",
                "Imperial_Compforce_Assault_Squad"
            }, false)
			
            UnitUtil.DespawnList{
                "Dummy_Regicide_Jax",
                "Emperor_Palpatine",
                "Sedriss",
				"Veers_AT_AT_Walker",
				"Grath_Dark_Stormtrooper",
                "Praji_Secutor",
                "Umak_Leth",
                "Chimera_Pellaeon_Vice",
                "Cronal_Singularity",
				"Klev_Frigate_Devastator",
				"Klev_Capital_Devastator",
				"Klev_Battlecruiser_Devastator"
            }
        end
    end,
    on_update = function(self, state_context)
        self.current_time = GetCurrentTime() - self.entry_time
        if (self.current_time >= 60) and (self.LeaderApproach == false) and (self.progress == true) then
            self.LeaderApproach = true
            if Find_Player("local") == Find_Player(self.Leading_Empire) then
                StoryUtil.Multimedia("TEXT_CONQUEST_EVENT_IR_DAALA_CONTACT", 15, nil, "Daala_Loop", 0)
                Story_Event("DAALA_REQUEST_STARTED")
                Find_Player(self.Leading_Empire).Unlock_Tech(Find_Object_Type("Dummy_Regicide_Daala"))

            end
        end
    end,
    on_exit = function(self, state_context)
    end
}
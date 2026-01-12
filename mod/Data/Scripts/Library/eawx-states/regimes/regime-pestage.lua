require("eawx-util/StoryUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)

        self.IsardApproach = false
        self.HissaApproach = false
        GlobalValue.Set("REGIME_INDEX", 1)
        self.Active_Planets = StoryUtil.GetSafePlanetTable()
        self.entry_time = GetCurrentTime()
        self.plot = Get_Story_Plot("Conquests\\Events\\EventLogRepository.xml")
        self.progress = GlobalValue.Get("PROGRESS_REGIME")

        if Find_Player("local") == Find_Player("Empire") then
            StoryUtil.Multimedia("TEXT_CONQUEST_WARLORDS_IR_INTRO_PESTAGE", 15, nil, "Pestage_Loop", 0)
			Story_Event("PESTAGE_WELCOME")
        end

        StoryUtil.SetPlanetRestricted("BYSS", 1)
        StoryUtil.SetPlanetRestricted("THE_MAW", 1)
        StoryUtil.SetPlanetRestricted("THYFERRA", 1)
        StoryUtil.SetPlanetRestricted("KESSEL", 1)
        StoryUtil.SetPlanetRestricted("KATANA_SPACE", 1)

        UnitUtil.SetLockList("EMPIRE", {
            "Generic_Praetor",
            "Strike_Cruiser",
            "Imperial_Boarding_Shuttle",
            "TaggeCo_HQ",
            "Incom_HQ",
            "SoroSuub_HQ",
            "Mekuun_HQ",
            "Cygnus_HQ",
			"Imperial_PX10_Company",
            "Imperial_AT_AT_Refit_Company",
            "Imperial_AT_ST_A_Company",
			-- Historical-only units
			"Imperial_Navy_Commando_Squad"
        }, false)

    end,
    on_update = function(self, state_context)
        self.current_time = GetCurrentTime()
        
        if (self.current_time >= 60) and (self.IsardApproach == false) and (self.progress == true) then
            self.IsardApproach = true
            if Find_Player("local") == Find_Player("Empire") then
                StoryUtil.Multimedia("TEXT_STORY_IR_ERA_2_PROJECT_AMBITION", 15, nil, "Isard_Loop", 0)
            end
        end
        if (self.current_time >= 130) and (self.HissaApproach == false)  and (self.progress == true) then
            self.HissaApproach = true
            if Find_Player("local") == Find_Player("Empire") then
                StoryUtil.Multimedia("TEXT_STORY_IR_ERA_2_CCOGM", 15, nil, "Hissa_Loop", 0)
            end
        end
		if (self.current_time >= 170) and (self.HissaApproach == true)  and (self.progress == true) then
            if Find_Player("local") == Find_Player("Empire") then
                Story_Event("PROJECT_AMBITION_STARTED")
                Find_Player("Empire").Unlock_Tech(Find_Object_Type("Project_Ambition_Dummy"))
                Find_Player("Empire").Unlock_Tech(Find_Object_Type("Dummy_Regicide_CCoGM"))
            end
        end
    end,
    on_exit = function(self, state_context)
    end
}
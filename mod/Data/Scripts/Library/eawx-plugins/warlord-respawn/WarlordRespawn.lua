--**************************************************************************************************
--*    _______ __                                                                                  *
--*   |_     _|  |--.----.---.-.--.--.--.-----.-----.                                              *
--*     |   | |     |   _|  _  |  |  |  |     |__ --|                                              *
--*     |___| |__|__|__| |___._|________|__|__|_____|                                              *
--*    ______                                                                                      *
--*   |   __ \.-----.--.--.-----.-----.-----.-----.                                                *
--*   |      <|  -__|  |  |  -__|     |  _  |  -__|                                                *
--*   |___|__||_____|\___/|_____|__|__|___  |_____|                                                *
--*                                   |_____|                                                      *
--*                                                                                                *
--*                                                                                                *
--*       File:              WarlordRespawn.lua                                                     *
--*       File Created:      Monday, 24th February 2020 02:19                                      *
--*       Author:            [TR] Jorritkarwehr                                                             *
--*       Last Modified:     Monday, 24th February 2020 02:34                                      *
--*       Modified By:       [TR] Jorritkarwehr                                                             *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("PGSpawnUnits")
require("deepcore/std/class")
StoryUtil = require("eawx-util/StoryUtil")
require("PGDebug")

WarlordRespawn = class()

function WarlordRespawn:new(herokilled_finished_event, human_player)
    self.human_player = human_player
	self.Active_Planets = StoryUtil.GetSafePlanetTable()
	self.start_planet = nil
    herokilled_finished_event:attach_listener(self.on_galactic_hero_killed, self)
end

function WarlordRespawn:on_galactic_hero_killed(hero_name, owner)
	--Logger:trace("entering WarlordRespawn:on_galactic_hero_killed")
	if hero_name == "DELVARDUS_THALASSA" then
		if not Find_First_Object("Delvardus_Night_Hammer") then
			local p_eriadu = Find_Player("Eriadu_Authority")

			if self.Active_Planets["KAMPE"] then
				self.start_planet = FindPlanet("Kampe")
				if not StoryUtil.CheckFriendlyPlanet(self.start_planet,p_eriadu) then
					self.start_planet = StoryUtil.FindFriendlyPlanet(p_eriadu)
				end
			else
				self.start_planet = StoryUtil.FindFriendlyPlanet(p_eriadu)
			end
			if self.start_planet then
				SpawnList({"Delvardus_Brilliant"}, self.start_planet, p_eriadu, true, false)
				Story_Event("DELVARDUS_RETURNS")
			end
		end
    elseif hero_name == "TREUTEN_13X" then
		if owner == "GREATER_MALDROOD" then
			local p_maldrood = Find_Player("Greater_Maldrood")
			if self.Active_Planets["HAKASSI"] then
				self.start_planet = FindPlanet("Hakassi")
				if not StoryUtil.CheckFriendlyPlanet(self.start_planet,p_maldrood) then
					self.start_planet = StoryUtil.FindFriendlyPlanet(p_maldrood)
				end
			else
				self.start_planet = StoryUtil.FindFriendlyPlanet(p_maldrood)
			end
			if self.start_planet then
				SpawnList({"Treuten_Crimson_Sunrise"}, self.start_planet, p_maldrood, true, false)
				Story_Event("TERADOC_RETURNS")
			end
		end
	elseif hero_name == "TYBER_ZANN_TEAM" then
		if owner == "ZSINJ_EMPIRE" then
			local p_zsinj = Find_Player("Zsinj_Empire")
			if self.Active_Planets["DATHOMIR"] then
				self.start_planet = FindPlanet("Dathomir")
				if not StoryUtil.CheckFriendlyPlanet(self.start_planet,p_zsinj) then
					self.start_planet = StoryUtil.FindFriendlyPlanet(p_zsinj)
				end
			else
				self.start_planet = StoryUtil.FindFriendlyPlanet(p_zsinj)
			end
			if self.start_planet then
				SpawnList({"TYBER_ZANN_TEAM2"}, self.start_planet, p_zsinj, true, false)
				Story_Event("TYBER_ZANN_RETURNS")
			end
		end
    elseif hero_name == "BRASHIN_TRMB_TEAM" then
		local Empire = Find_Player("Empire")
		if Empire.Is_Human() then
			GlobalValue.Set("BRASHIN_TRMB_DEAD", true)
			local assign_unit = Find_Object_Type("Rebuild_Brashin")
			Empire.Unlock_Tech(assign_unit)
			
			StoryUtil.ShowScreenText("General Brashin's TR-MB has been destroyed and must be replaced.", 5, nil, {r = 244, g = 244, b = 0})
		else
			Empire.Give_Money(-1000)
		end
	elseif hero_name == "GRODIN_TIERCE_TEAM" then
		GlobalValue.Set("DEPLOYED_GRODIN_TIERCE_DEAD", true)
		local Empire = Find_Player("Empire")
		if Empire.Is_Human() then
			StoryUtil.ShowScreenText("Grodin Tierce has been wounded and can no longer fight on land.", 5, nil, {r = 244, g = 244, b = 0})
		end
	elseif hero_name == "JAG_127TH_TEAM" then
		local p_zsinj = Find_Player("Zsinj_Empire")
		if p_zsinj.Is_Human() then
			local assign_unit = Find_Object_Type("Reform_127th")
			p_zsinj.Unlock_Tech(assign_unit)
			UnitUtil.SetBuildable(p_zsinj, "Jag_127th_Location_Set", false)
			Clear_Fighter_Hero("JAG_127TH_SQUADRON")
			StoryUtil.ShowScreenText("The 127th has taken crippling casualties and must be reformed.", 5, nil, {r = 244, g = 244, b = 0})
		else
			p_zsinj.Give_Money(-1000)
		end
	elseif hero_name == "JENN_TEAM" then
		crossplot:publish("JENN_SMEEL_DEATH", "empty")
	end

end
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
--*       File:              BountyHunters.lua                                                     *
--*       File Created:      Monday, 24th February 2020 02:19                                      *
--*       Author:            [TR] Kiwi                                                             *
--*       Last Modified:     After Friday, 9th April 2021 21:16                                    *
--*       Modified By:       Not [TR] Kiwi                                                         *
--*       Copyright:         Thrawns Revenge Development Team                                      *
--*       License:           This code may not be used without the author's explicit permission    *
--**************************************************************************************************

require("deepcore/std/class")
require("eawx-util/StoryUtil")

BountyHunters = class()

function BountyHunters:new(gc)
	--Table With bounty hunters
	self.BountyHunterHeroes = {
		"Boba_Fett_Team",
		"Dengar_Team",
		"Bossk_Team",
		"Menndo_Team",
		"Snoova_Team",
		"Labansat_Team",
		"Dej_Vennor_Team",
		"Moxin_Tark_Team",
		"Dyzz_Nataz_Team",
	}
	self.PossibleRecruiters = {
		"EMPIRE",
		"ERIADU_AUTHORITY",
		"GREATER_MALDROOD",
		"PENTASTAR",
		"ZSINJ_EMPIRE",
		"CORPORATE_SECTOR",
		"HUTT_CARTELS",
	}
	self.gc = gc
	self.gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	
	self.tech_name = "RANDOM_BOUNTY_HUNTER"
	if Find_Object_Type("RANDOM_BOUNTY_HUNTER_2") then
		for _, faction in pairs(self.PossibleRecruiters) do
			Find_Player(faction).Lock_Tech(Find_Object_Type("RANDOM_BOUNTY_HUNTER"))
			Find_Player(faction).Unlock_Tech(Find_Object_Type("RANDOM_BOUNTY_HUNTER_2"))
		end
		self.tech_name = "RANDOM_BOUNTY_HUNTER_2"
	end
end

function BountyHunters:on_production_finished(planet, object_type_name)
	--Logger:trace("entering BountyHunters:on_production_finished")
	if object_type_name ~= self.tech_name then
		return
	end

	local RandomBountyHunter = Find_First_Object(self.tech_name)
	if TestValid(RandomBountyHunter) and table.getn(self.BountyHunterHeroes) > 0 then
	
		local bountyHunterIndex = GameRandom.Free_Random(1,table.getn(self.BountyHunterHeroes))
		local bounty_hunter_to_spawn = self.BountyHunterHeroes[bountyHunterIndex]
		table.remove(self.BountyHunterHeroes, bountyHunterIndex)
		
		local BountyHunterOwner = RandomBountyHunter.Get_Owner()
		local BountyHunterLocation = RandomBountyHunter.Get_Planet_Location()
		local BountyHunterUnit = Find_Object_Type(bounty_hunter_to_spawn)
		Spawn_Unit(BountyHunterUnit, BountyHunterLocation, BountyHunterOwner)

		if table.getn(self.BountyHunterHeroes) == 0 then
			StoryUtil.ShowScreenText("All bounty hunters have been hired.", 5, nil, {r = 244, g = 244, b = 0})
			for _, faction in pairs(self.PossibleRecruiters) do
				Find_Player(faction).Lock_Tech(Find_Object_Type(self.tech_name))
			end
			self.gc.Events.GalacticProductionFinished:detach_listener(self.on_production_finished, self)
		end
	end
	RandomBountyHunter.Despawn()
end
--require("deepcore/crossplot/crossplot")
require("eawx-util/StoryUtil")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)

		self.entry_time = GetCurrentTime()
		self.Active_Planets = StoryUtil.GetSafePlanetTable()
		
		local era = GlobalValue.Get("CURRENT_ERA")
		
		if era == 1 then
			self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraOneStartSet")
		elseif era == 2 then
			self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraTwoStartSet")
		elseif era == 3 then
			self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraThreeStartSet")
		elseif era == 4 then
			self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFourStartSet")
		elseif era == 5 then
			self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraFiveStartSet")
		elseif era == 6 then
			self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraSixStartSet")
		elseif era == 7 then
			self.Starting_Spawns = require("eawx-mod-icw/spawn-sets/EraSevenStartSet")
		end
		
		if self.entry_time <= 5 and self.Starting_Spawns then
			for faction, spawnlist in pairs(self.Starting_Spawns) do
				local player = Find_Player(faction)
				for planet, herolist in pairs(spawnlist) do
				
					for _, hero in pairs(herolist) do
						local random_planet = StoryUtil.FindFriendlyPlanet(player)
						if not random_planet then
							break
						end
						SpawnList({hero}, random_planet, player, true, false)
					end
				end
			end
		end
    end,
    on_update = function(self, state_context)
    end,
    on_exit = function(self, state_context)
    end
}
--require("deepcore/crossplot/crossplot")
require("eawx-util/StoryUtil")
require("eawx-util/StoryUtil2")
require("PGStoryMode")
require("PGSpawnUnits")

return {
    on_enter = function(self, state_context)
		crossplot:publish("INITIALIZE_AI", "empty")

		self.entry_time = GetCurrentTime()
		--self.Active_Planets = StoryUtil.GetSafePlanetTable()
		
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
		
		for faction, spawnlist in pairs(self.Starting_Spawns) do
			--StoryUtil.ShowScreenText(faction, 120, nil, {r = 244, g = 244, b = 0})
			local player = Find_Player(faction)
			for planet, herolist in pairs(spawnlist) do
				for _, hero in pairs(herolist) do
					local random_planet = StoryUtil2.FindFriendlyPlanet(player)
					if random_planet then
						SpawnList({hero}, random_planet, player, true, false)
					end
				end
			end
		end
    end,
    on_update = function(self, state_context)
    end,
    on_exit = function(self, state_context)
        local placeholder_table = Find_All_Objects_Of_Type("Placement_Dummy")
        for i, unit in pairs(placeholder_table) do
            unit.Despawn()
        end
    end
}
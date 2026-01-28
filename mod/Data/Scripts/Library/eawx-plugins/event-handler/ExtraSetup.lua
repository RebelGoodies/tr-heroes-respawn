require("deepcore/std/class")
require("eawx-events/GenericResearch")
require("eawx-events/GenericSwap")
require("eawx-events/GenericConquer")
require("eawx-events/GenericPopup")
require("eawx-events/FelChildren")
StoryUtil = require("eawx-util/StoryUtil")
StoryUtil2 = require("eawx-util/StoryUtil2")

---@class EventManagerExtra
EventManagerExtra = class()

---@param galactic_conquest GalacticConquest
---@param human_player PlayerObject
---@param planets table<string, Planet>
---@param id string
function EventManagerExtra:new(galactic_conquest, human_player, planets, id)
    self.id = id
    self.galactic_conquest = galactic_conquest
    self.human_player = human_player
    self.planets = planets
    self.Active_Planets = StoryUtil.GetSafePlanetTable()

    self.events_fired = false
    self.spawn_heroes = false
    if id == "FTGU" or id == "CUSTOM" then
        self.spawn_heroes = true
    end

    crossplot:subscribe("INITIALIZE_AI", self.init_events, self)
    crossplot:subscribe("STARTING_SIZE_PICK", self.check_spawn_heroes, self) --For Custom GC
    crossplot:subscribe("CUSTOM_FULL_HEROES", self.heroes_spawned_already, self)
    crossplot:subscribe("CUSTOM_GC_HERO_DEFAULT", self.heroes_spawned_already, self)
    crossplot:subscribe("CUSTOM_GC_HERO_FACTIONAL_DEFAULT", self.heroes_spawned_already, self)
end

function EventManagerExtra:init_events()
    if not self.events_fired then
        if self.id == "FTGU" then
            crossplot:publish("REPUBLIC_ADMIRAL_DECREMENT", {-3,-2,0}, 0)
        end
        self:hero_era_unlocks()
        if self.spawn_heroes then
            self:spawn_regime_heroes()
            self:spawn_era_heroes()
            StoryUtil.ShowScreenText("Done", 5, nil, {r = 0, g = 222, b = 0})
        end
        self.events_fired = true
    end
end

-- Heores for everyone except the Empire
function EventManagerExtra:spawn_era_heroes()
    local path = "eawx-mod-icw/spawn-sets/"
    local num = {"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven"}
    local era = GlobalValue.Get("CURRENT_ERA")
    local start_set = "Era"..num[era].."StartSet"
    local warlord_set = "Era"..num[era].."WarlordStartSet"
    
    local success, starting_spawns = pcall(require, path..warlord_set)
    if success then
        for planet, herolist in pairs(starting_spawns) do
            StoryUtil.SpawnAtSafePlanet(planet, Find_Player("Warlords"), self.Active_Planets, herolist)
        end
    end
    
    -- All factions except Empire
    local success, starting_spawns = pcall(require, path.."FTGU_"..start_set)
    if not success then
        success, starting_spawns = pcall(require, path..start_set)
    end
    
    if success then
        StoryUtil.ShowScreenText("Spawning heroes", 5, nil, {r = 0, g = 190, b = 0})
        for faction, spawnlist in pairs(starting_spawns) do
            if StoryUtil2.FindFriendlyPlanet(Find_Player(faction)) then
                for planet, herolist in pairs(spawnlist) do
                    StoryUtil.SpawnAtSafePlanet(planet, Find_Player(faction), self.Active_Planets, herolist)
                end
            end
        end
    end
end

-- Regime heroes for the Empire
function EventManagerExtra:spawn_regime_heroes()
    local path = "eawx-mod-icw/spawn-sets/"
    local era = GlobalValue.Get("CURRENT_ERA")
    local regimes = {"PESTAGE", "ISARD", "THRAWN", "PALPATINE", "CARNOR", "DAALA", "PELLAEON"}
    local regime = regimes[era]
    if era == 2 and GameRandom.Free_Random(1,2) == 2 then
        regime = "CCOGM"
    end
    
    local success, starting_spawns = pcall(require, path.."EmpireProgressSet")
    local Leading_Empire = Find_Player("Empire") --GlobalValue.Get("IMPERIAL_REMNANT")
    local planet = StoryUtil2.FindFriendlyPlanet(Leading_Empire)
    
    if success and planet then
        StoryUtil.ShowScreenText("Spawning Regime heroes", 5, nil, {r = 0, g = 180, b = 0})
        for _, herolist in pairs(starting_spawns[regime]) do
            for _, hero_table in pairs(herolist) do
                StoryUtil.SpawnAtSafePlanet(planet, Leading_Empire, self.Active_Planets, {hero_table.object})
            end
        end
    end
end

function EventManagerExtra:hero_era_unlocks()
    local era = GlobalValue.Get("CURRENT_ERA")
    if era >= 3 then
        crossplot:publish("REPUBLIC_RESEARCH_FINISHED", "empty")
        crossplot:publish("NCMP_RESEARCH_FINISHED", "empty")
    end
    if era >= 4 then
        crossplot:publish("CORONA_RESEARCH_FINISHED", "empty")
        crossplot:publish("NCMP2_RESEARCH_FINISHED", "empty")
    end
    if era >= 7 then
        crossplot:publish("GORATH_RESEARCH_FINISHED", "empty")
        --crossplot:publish("VISCOUNT_RESEARCH", "empty")
    end
end

---@param choice string
function EventManagerExtra:check_spawn_heroes(choice)
    if choice == "CUSTOM_GC_SMALL_START" then
        self.spawn_heroes = false
    end
end

function EventManagerExtra:heroes_spawned_already()
    self.spawn_heroes = false
    if not self.events_fired then
        -- Empire regime hero spawns were not included
        self:spawn_regime_heroes()
    end
end

return EventManagerExtra
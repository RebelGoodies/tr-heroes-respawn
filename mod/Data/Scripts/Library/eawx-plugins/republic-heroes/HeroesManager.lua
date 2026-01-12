require("deepcore/std/class")
require("HeroSystem")
require("eawx-plugins/republic-heroes/RepublicHeroes")

---@class HeroesManager
HeroesManager = class()

---@param gc GalacticConquest
---@param id string
---@param human_player PlayerObject
---@param RepHeroes RepublicHeroes
function HeroesManager:new(gc, id, human_player, RepHeroes)
    self.gc = gc
    self.id = id
    self.human_player = human_player
    self.RepHeroes = RepHeroes

    gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
	gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)

    self:define_remnant_data()

    UnitUtil.SetLockList(self.human_player.Get_Faction_Name(), {
        "Krennel_R2W", "Krennel_W2R", "Cronus_Upgrade", "Harrsk_W2S", "Harrsk_S2W"
    }, true)

    if self.id ~= "HISTORICAL" and self.id ~= "DEFAULT" then
        if self.human_player == Find_Player("Rebel") then
            UnitUtil.SetLockList("Rebel", {"Ackbar_Guardian_Upgrade", "Ackbar_Guardian_Upgrade2"}, true)
            self:add_rep_heroes()
        end
        if TestValid(Find_Object_Type("VIEW_REMNANT")) and remnant_data.active_player.Is_Human() then
            remnant_data.active_player.Unlock_Tech(Find_Object_Type("VIEW_REMNANT"))
        end
    end
end

---@param planet Planet
---@param object_type_name string
function HeroesManager:on_production_finished(planet, object_type_name)
    if not self.inited then
		self.inited = true
        init_hero_system(remnant_data)
    end

    if self:handle_custom_upgrades(planet, object_type_name) then
        return
    end

    if object_type_name == "VIEW_REMNANT" then
        remnant_data.disabled = not remnant_data.disabled
        if remnant_data.disabled then
            Disable_Hero_Options(remnant_data)
        else
            Enable_Hero_Options(remnant_data)
            Show_Hero_Info(remnant_data)
        end
    else
        Handle_Build_Options(object_type_name, remnant_data)
	end
end

---@param hero_name string
---@param owner_name string
---@param killer_name string
function HeroesManager:on_galactic_hero_killed(hero_name, owner_name, killer_name)
    Handle_Hero_Killed(hero_name, owner_name, remnant_data)
end

---@param planet any
---@param object_type_name any
---@return boolean was_upgrade
function HeroesManager:handle_custom_upgrades(planet, object_type_name)
    custom_upgrades = {
        ["ACKBAR_GUARDIAN_UPGRADE"] = {"Ackbar", "Ackbar_Guardian", 1},
        ["ACKBAR_GUARDIAN_UPGRADE2"] = {"Ackbar", "Ackbar_Guardian", 1},
        ["CRONUS_UPGRADE"] = {"Cronus", "Night_Hammer", 0},
        ["KRENNEL_R2W"] = {"Krennel", "Krennel_Warlord", 0},
        ["KRENNEL_W2R"] = {"Krennel", "Krennel_Reckoning", 0},
        ["HARRSK_W2S"] = {"Harrsk", "Harrsk_Shockwave", 0},
        ["HARRSK_S2W"] = {"Harrsk", "Harrsk_Whirlwind", 0},
    }

    for upgrade_type, replacement in pairs(custom_upgrades) do
        if object_type_name == string.upper(upgrade_type) then
            local tag = replacement[1]
            local upgrade_unit = replacement[2]
            local set = replacement[3]
            
            if set == 0 then
                Handle_Hero_Exit(tag, remnant_data)
            else
               self.RepHeroes:admiral_exit({tag}, set)
            end
            StoryUtil.SpawnAtSafePlanet(planet:get_name(), planet:get_owner(), StoryUtil.GetSafePlanetTable(), {upgrade_unit})
            return true
        end
    end
    return false
end

---Regional and Historical
function HeroesManager:define_remnant_data()
    remnant_data = {
		total_slots = 25,			--Max slot number. Set at the start of the GC and never change
		free_hero_slots = 25,		--Slots open to buy
		vacant_hero_slots = 0,	    --Slots that need another action to move to free
		vacant_limit = 3,           --Number of times a lost slot can be reopened
		initialized = false,
		full_list = { --All options for reference operations
            ["Krennel"] = {"KRENNEL_ASSIGN",{"KRENNEL_RETIRE","KRENNEL_RETIRE2"},{"KRENNEL_RECKONING","KRENNEL_WARLORD"},"Delak Krennel"},
            ["Lanox"] = {"LANOX_ASSIGN",{"LANOX_RETIRE"},{"LANOX_HAZARD"},"Sergus Lanox"},
            ["Yonka"] = {"YONKA_EMPIRE_ASSIGN",{"YONKA_EMPIRE_RETIRE"},{"YONKA_AVARICE"},"Sair Yonka"},
            ["Brothic"] = {"BROTHIC_ASSIGN",{"BROTHIC_RETIRE"},{"BROTHIC"},"Brothic", ["Companies"] = {"BROTHIC_TEAM"}},
            ["Darron"] = {"DARRON_ASSIGN",{"DARRON_RETIRE"},{"DARRON_DIREPTION"},"Vict Darron"},
            ["Phulik"] = {"PHULIK_ASSIGN",{"PHULIK_RETIRE"},{"PHULIK_BINDER"},"Phulik"},
            ["Luke"] = {"LUKE_DARKSIDE_ASSIGN",{"LUKE_DARKSIDE_RETIRE"},{"LUKE_SKYWALKER_DARKSIDE"},"Luke Skywalker", ["Companies"] = {"LUKE_SKYWALKER_DARKSIDE_TEAM"}},
            ["Cronus"] = {"CRONUS_ASSIGN",{"CRONUS_RETIRE"},{"CRONUS_13X"},"Ivan Cronus"},
            ["Norym"] = {"NORYM_KIM_ASSIGN",{"NORYM_KIM_RETIRE"},{"NORYM_KIM_BLOOD_GAINS"},"Norym Kim"},
            ["Golanda"] = {"GOLANDA_ASSIGN",{"GOLANDA_RETIRE"},{"GOLANDA_MPTL"},"Golanda", ["Companies"] = {"GOLANDA_MPTL_TEAM"}},
            ["Noils"] = {"NOILS_ASSIGN",{"NOILS_RETIRE"},{"NOILS"},"Noils", ["Companies"] = {"NOILS_TEAM"}},
            ["Brusc"] = {"BRUSC_ASSIGN",{"BRUSC_RETIRE"},{"BRUSC_MANTICORE"},"Brusc"},
            ["Mullinore"] = {"MULLINORE_ASSIGN",{"MULLINORE_RETIRE"},{"MULLINORE_BASILISK"},"Mullinore"},
            ["Vit"] = {"VIT_ASSIGN",{"VIT_RETIRE"},{"VIT"},"Vit", ["Companies"] = {"VIT_TEAM"}},
            ["Vilim"] = {"VILIM_ASSIGN",{"VILIM_RETIRE"},{"VILIM_DISRA"},"Vilim Disra", ["Companies"] = {"VILIM_DISRA_TEAM"}},
            ["Flim"] = {"FLIM_TIERCE_ASSIGN",{"FLIM_TIERCE_RETIRE"},{"FLIM_TIERCE_IRONHAND"},"Grodin Tierce & Flim"},
            ["Desanne"] = {"DESANNE_ASSIGN",{"DESANNE_RETIRE"},{"DESANNE_REDEMPTION"},"Desanne"},
            ["Agamar"] = {"AGAMAR_ASSIGN",{"AGAMAR_RETIRE"},{"AGAMAR_MENISCUS"},"Gareth Agamar"},
            ["Harrsk"] = {"HARRSK_ASSIGN",{"HARRSK_RETIRE", "HARRSK_RETIRE2"},{"HARRSK_WHIRLWIND", "HARRSK_SHOCKWAVE"},"Blitzer Harrsk"},
            ["Tethys"] = {"TETHYS_ASSIGN",{"TETHYS_RETIRE"},{"TETHYS_CALLOUS"},"Jmanuel Tethys"},
            ["Shargael"] = {"SHARGAEL_ASSIGN",{"SHARGAEL_RETIRE"},{"SHARGAEL_AT_TE"},"Bliss Shargael", ["Companies"] = {"SHARGAEL_TEAM"}},
            ["Prost"] = {"PROST_ASSIGN",{"PROST_RETIRE"},{"PROST_VICTORY"},"Prost"},
            ["Cathers"] = {"CATHERS_ASSIGN",{"CATHERS_RETIRE"},{"CATHERS"},"Cathers", ["Companies"] = {"CATHERS_TEAM"}},
            ["Fouc"] = {"FOUC_ASSIGN",{"FOUC_RETIRE"},{"FOUC_IMPOUNDER"},"Mandus Fouc"},
            ["Sarhl"] = {"SARHL_ASSIGN",{"SARHL_RETIRE"},{"FENRIS_SARHL"},"Fenris Sarhl", ["Companies"] = {"SARHL_TEAM"}},
		},
		available_list = {},
		story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
		active_player = Find_Player("Empire"),
		extra_name = "EXTRA_REMNANT_SLOT",
		random_name = "RANDOM_REMNANT_ASSIGN",
		global_display_list = "REMNANT_LIST", --Name of global array used for documention of currently active heroes
		disabled = true
	}
    -- Fill the available_list
    for tag, _ in pairs(remnant_data.full_list) do
        table.insert(remnant_data.available_list, tag)
    end
end

function HeroesManager:add_rep_heroes()
    Add_Fighter_Set("TalDira_Location_Set")

    if admiral_data and admiral_data.full_list and admiral_data.available_list then
        for tag, entry in pairs({
            ["Rogriss"] = {"ROGRISS_ASSIGN",{"ROGRISS_RETIRE"},{"ROGRISS_ASSUAGER"},"Rogriss"}, --
            ["Aves"] = {"AVES_ASSIGN",{"AVES_RETIRE"},{"AVES_ETHERWAY"},"Aves"},
            ["Faughn"] = {"FAUGHN_ASSIGN",{"FAUGHN_RETIRE"},{"FAUGHN_STARRY_ICE"},"Faughn"},
            ["Gillespee"] = {"GILLESPEE_ASSIGN",{"GILLESPEE_RETIRE"},{"GILLESPEE_KERNS_PRIDE"},"Gillespee"},
            ["Clyngunn"] = {"CLYNGUNN_ASSIGN",{"CLYNGUNN_RETIRE"},{"CLYNGUNN_LADY_SUNFIRE"},"Clyngunn"},
            ["Yonka"] = {"YONKA_ASSIGN",{"YONKA_RETIRE"},{"YONKA_FREEDOM"},"Yonka"}, --
            ["Slixike"] = {"SLIXIKE_ASSIGN",{"SLIXIKE_RETIRE"},{"SLIXIKE"},"Slixike"}, --
            ["Standish"] = {"STANDISH_ASSIGN",{"STANDISH_RETIRE"},{"ANTON_STANDISH"},"Anton Standish"}, --
        }) do
            admiral_data.full_list[tag] = entry
            table.insert(admiral_data.available_list, tag)
        end
    end
    if general_data and general_data.full_list and general_data.available_list then
        for tag, entry in pairs({
            ["Mirax"] = {"MIRAX_ASSIGN",{"MIRAX_RETIRE"},{"MIRAX"},"Mirax", ["Companies"] = {"MIRAX_TEAM"}}, --
            ["Alinda"] = {"ALINDA_ASSIGN",{"ALINDA_RETIRE"},{"ALINDA_SOLARIS"},"Alinda", ["Companies"] = {"SOLARIS_TEAM"}}, --
        }) do
            general_data.full_list[tag] = entry
            table.insert(general_data.available_list, tag)
        end
    end
    if council_data and council_data.full_list and council_data.available_list then
        council_data.full_list["Mander"] = {"MANDER_ASSIGN",{"MANDER_RETIRE"},{"MANDER_ZUMA"},"Mander Zuma", ["Companies"] = {"ZUMA_TEAM"}} --
        table.insert(council_data.available_list, "Mander")
    end
end

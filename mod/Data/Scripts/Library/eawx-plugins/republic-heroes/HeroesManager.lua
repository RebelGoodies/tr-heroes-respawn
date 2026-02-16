---@License: MIT

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
    self.human_faction = human_player.Get_Faction_Name()
    self.RepHeroes = RepHeroes

    gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
    -- gc.Events.GalacticHeroKilled:attach_listener(self.on_galactic_hero_killed, self)

    self:define_remnant_data()

    UnitUtil.SetLockList(self.human_faction, {
        "Krennel_R2W", "Krennel_W2R", "Cronus_Upgrade", "Harrsk_W2S", "Harrsk_S2W"
    }, true)

    if self.id ~= "HISTORICAL" and self.id ~= "DEFAULT" then
        if self.human_player == Find_Player("Rebel") then
            -- UnitUtil.SetLockList("Rebel", {
            --     "Ackbar_Guardian_Upgrade",
            --     "Ackbar_Guardian_Upgrade2"
            -- }, true)
            self:add_rep_heroes()
        end
        if self.remnant_data.active_player.Is_Human() then
            local remnant_faction = self.remnant_data.active_player.Get_Faction_Name()
            UnitUtil.SetLockList(remnant_faction, {"VIEW_REMNANT"}, true)
        end
    end
end

---@param planet Planet
---@param object_type_name string
function HeroesManager:on_production_finished(planet, object_type_name)
    if not self.inited then
        self.inited = true
        self.locked_increase = true
        init_hero_system(self.remnant_data)
    end

    if self:handle_custom_upgrades(planet, object_type_name) then
        return
    end

    if self.RepHeroes.viewers and self.RepHeroes.viewers[object_type_name] then
        self:check_available_staff()
    end
    if object_type_name == "OPTION_INCREASE_REP_STAFF" then
        self:rep_staff_increase(1)
        return
    end

    if object_type_name == "VIEW_REMNANT" then
        self.remnant_data.disabled = not self.remnant_data.disabled
        if self.remnant_data.disabled then
            Disable_Hero_Options(self.remnant_data)
        else
            Enable_Hero_Options(self.remnant_data)
            Show_Hero_Info(self.remnant_data)
        end
    else
        Handle_Build_Options(object_type_name, self.remnant_data)
    end
end

---@param hero_name string
---@param owner_name string
---@param killer_name string
function HeroesManager:on_galactic_hero_killed(hero_name, owner_name, killer_name)
    Handle_Hero_Killed(hero_name, owner_name, self.remnant_data)
end

function HeroesManager:check_available_staff()
    if not self.RepHeroes.library or not self.locked_increase then
        return
    end
    for set_name, hero_data in pairs(self.RepHeroes.library) do
        if hero_data then
            if table.getn(hero_data.available_list) > hero_data.free_hero_slots then
                UnitUtil.SetLockList(self.human_faction, {"OPTION_INCREASE_REP_STAFF"}, true)
                self.locked_increase = false
            end
        end
    end
end

---@param amount integer
function HeroesManager:rep_staff_increase(amount)
    if not amount then
        amount = 1
    end

    if not self.RepHeroes.library then
        return
    end

    no_more_free_slots = true
    for set_name, hero_data in pairs(self.RepHeroes.library) do
        if table.getn(hero_data.available_list) > hero_data.free_hero_slots then
            StoryUtil.ShowScreenText("Total "..set_name.." Slots: "..hero_data.total_slots+1, 3, nil, {r = 88, g = 222, b = 44})
            self.RepHeroes:CommandStaff_Slot_Adjust(amount, set_name)
            Lock_Hero_Options(hero_data)
            Unlock_Hero_Options(hero_data)
            Get_Active_Heroes(false, hero_data)
            if table.getn(hero_data.available_list) > hero_data.free_hero_slots then
                no_more_free_slots = false
            end
        else
            StoryUtil.ShowScreenText("Total "..set_name.." Slots: "..hero_data.total_slots, 3, nil, {r = 244, g = 190, b = 33})
        end
    end
    if no_more_free_slots then
        UnitUtil.SetLockList(self.human_faction, {"OPTION_INCREASE_REP_STAFF"}, false)
        self.locked_increase = true
    end
end

---@param planet any
---@param object_type_name any
---@return boolean was_upgrade
function HeroesManager:handle_custom_upgrades(planet, object_type_name)
    custom_upgrades = {
        ["ACKBAR_GUARDIAN_UPGRADE"] = {"Ackbar", "Ackbar_Guardian", "SUPCOM"},
        ["ACKBAR_GUARDIAN_UPGRADE2"] = {"Ackbar", "Ackbar_Guardian", "SUPCOM"},
        ["CRONUS_UPGRADE"] = {"Cronus", "Night_Hammer"},
        ["KRENNEL_R2W"] = {"Krennel", "Krennel_Warlord"},
        ["KRENNEL_W2R"] = {"Krennel", "Krennel_Reckoning"},
        ["HARRSK_W2S"] = {"Harrsk", "Harrsk_Shockwave"},
        ["HARRSK_S2W"] = {"Harrsk", "Harrsk_Whirlwind"},
    }

    for upgrade_type, replacement in pairs(custom_upgrades) do
        if object_type_name == string.upper(upgrade_type) then
            local tag = replacement[1]
            local upgrade_unit = replacement[2]
            local set = replacement[3]

            if not set then
                Handle_Hero_Exit(tag, self.remnant_data)
            else
                self.RepHeroes:CommandStaff_Exit({tag}, set)
            end
            StoryUtil.SpawnAtSafePlanet(planet:get_name(), planet:get_owner(), StoryUtil.GetSafePlanetTable(), {upgrade_unit})
            return true
        end
    end
    return false
end

---Regional and Historical
function HeroesManager:define_remnant_data()
    self.remnant_data = {
        total_slots = -1,           --Max slot number. Set at the start of the GC and never change
        free_hero_slots = -1,       --Slots open to buy
        vacant_hero_slots = 0,      --Slots that need another action to move to free
        vacant_limit = 3,           --Number of times a lost slot can be reopened
        initialized = false,
        retire_object = "RETIRE_REMNANT",
        full_list = { --All options for reference operations
            ["Yonka"] = {"YONKA_EMPIRE_ASSIGN",{"YONKA_AVARICE"},"Sair Yonka"},
            ["Brothic"] = {"BROTHIC_ASSIGN",{"BROTHIC"},"Brothic", ["Companies"] = {"BROTHIC_TEAM"}},
            ["Darron"] = {"DARRON_ASSIGN",{"DARRON_DIREPTION"},"Vict Darron"},
            ["Phulik"] = {"PHULIK_ASSIGN",{"PHULIK_BINDER"},"Phulik"},
            -- ["Rogriss"] = {"ROGRISS_EMPIRE_ASSIGN",{"ROGRISS_AURORA"},"Teren Rogriss"},
            ["Ars"] = {"ARS_ASSIGN",{"ARS_DANGOR"},"Ars Dangor", ["Companies"] = {"ARS_DANGOR_TEAM"}},
            -- ["Pestage"] = {"PESTAGE_CLONE_ASSIGN",{"PESTAGE_CLONE"},"Pestage Clone", ["Companies"] = {"PESTAGE_CLONE_TEAM"}},
            ["Luke"] = {"LUKE_DARKSIDE_ASSIGN",{"LUKE_SKYWALKER_DARKSIDE"},"Luke Skywalker", ["Companies"] = {"LUKE_SKYWALKER_DARKSIDE_TEAM"}},
            ["Cronus"] = {"CRONUS_ASSIGN",{"CRONUS_13X"},"Ivan Cronus"},
            ["Norym"] = {"NORYM_KIM_ASSIGN",{"NORYM_KIM_BLOOD_GAINS"},"Norym Kim"},
            ["Banjeer"] = {"BANJEER_ASSIGN",{"BANJEER_NEUTRON"},"Llon Banjeer"},
            ["Golanda"] = {"GOLANDA_ASSIGN",{"GOLANDA_MPTL"},"Golanda", ["Companies"] = {"GOLANDA_MPTL_TEAM"}},
            ["Brusc"] = {"BRUSC_ASSIGN",{"BRUSC_MANTICORE"},"Brusc"},
            ["Mullinore"] = {"MULLINORE_ASSIGN",{"MULLINORE_BASILISK"},"Mullinore"},
            ["Vit"] = {"VIT_ASSIGN",{"VIT_SPMAG_WALKER"},"Vit", ["Companies"] = {"VIT_SPMAG_WALKER_TEAM"}},
            ["Vilim"] = {"VILIM_ASSIGN",{"VILIM_DISRA"},"Vilim Disra", ["Companies"] = {"VILIM_DISRA_TEAM"}},
            ["Flim"] = {"FLIM_TIERCE_ASSIGN",{"FLIM_TIERCE_IRONHAND"},"Grodin Tierce & Flim"},
            ["Noils"] = {"NOILS_ASSIGN",{"NOILS_AT_AT_WALKER"},"Noils", ["Companies"] = {"NOILS_AT_AT_WALKER_TEAM"}},
            ["Desanne"] = {"DESANNE_ASSIGN",{"DESANNE_REDEMPTION"},"Desanne"},
            ["Agamar"] = {"AGAMAR_ASSIGN",{"AGAMAR_MENISCUS"},"Gareth Agamar"},
            ["Harrsk"] = {"HARRSK_ASSIGN",{"HARRSK_WHIRLWIND", "HARRSK_SHOCKWAVE"},"Blitzer Harrsk"},
            ["Qua"] = {"QUA_ASSIGN",{"QUA"},"Qua", ["Companies"] = {"QUA_TEAM"}},
            ["Tethys"] = {"TETHYS_ASSIGN",{"TETHYS_CALLOUS"},"Jmanuel Tethys"},
            ["Shargael"] = {"SHARGAEL_ASSIGN",{"SHARGAEL_AT_TE"},"Bliss Shargael", ["Companies"] = {"SHARGAEL_TEAM"}},
            ["Jedgar"] = {"JEDGAR_ASSIGN",{"JEDGAR"},"Jedgar", ["Companies"] = {"JEDGAR_TEAM"}},
            ["Kadann"] = {"KADANN_ASSIGN",{"KADANN"},"Kadann", ["Companies"] = {"KADANN_TEAM"}},
            ["Prost"] = {"PROST_ASSIGN",{"PROST_VICTORY"},"Prost"},
            ["Cathers"] = {"CATHERS_ASSIGN",{"CATHERS"},"Cathers", ["Companies"] = {"CATHERS_TEAM"}},
            ["Fouc"] = {"FOUC_ASSIGN",{"FOUC_IMPOUNDER"},"Mandus Fouc"},
            ["Wermis"] = {"WERMIS_ASSIGN",{"WERMIS_EMPIRE"},"Osted Wermis"},
            ["Pitta"] = {"PITTA_ASSIGN",{"PITTA_TORPEDO_SPHERE"},"Danetta Pitta"},
            ["Thanas"] = {"THANAS_ASSIGN",{"THANAS_DOMINANT"},"Pter Thanas"},
            ["Wilek"] = {"WILEK_NEREUS_ASSIGN",{"WILEK_NEREUS"},"Wilek Nereus", ["Companies"] = {"WILEK_NEREUS_TEAM"}},
            ["Ragez"] = {"RAGEZ_DASTA_ASSIGN",{"RAGEZ_DASTA_MARAUDER"},"Ragez D'Asta"},
            ["MNista"] = {"MNISTA_ASSIGN",{"MNISTA_QUASAR"},"M'Nista"},
            ["Feena"] = {"FEENA_DASTA_ASSIGN",{"FEENA_DASTA"},"Feena D'Asta", ["Companies"] = {"FEENA_DASTA_TEAM"}},
            ["Kuras"] = {"KURAS_ASSIGN",{"KURAS_CHARIOT"},"Thichis Kuras", ["Companies"] = {"KURAS_TEAM"}},
            ["Kendel"] = {"KENDEL_ASSIGN",{"KENDEL_LUMINOUS"},"Kendel"},
            ["Kateel"] = {"KATEEL_ASSIGN",{"KATEEL"},"Kateel of Kuhlvult", ["Companies"] = {"KATEEL_TEAM"}},
            ["Phillip"] = {"PHILLIP_SANTHE_ASSIGN",{"PHILLIP_SANTHE"},"Phillip Santhe", ["Companies"] = {"PHILLIP_SANTHE_TEAM"}},
            ["Imre"] = {"IMRE_ASSIGN",{"IMRE_TALBERENINA_BALLISTA"},"Imre Talberenina"},
            ["Worhven"] = {"WORHVEN_ASSIGN",{"WORHVEN_DOMINATOR"},"Worhven"},
        },
        available_list = {},
        story_locked_list = {},--Heroes not accessible, but able to return with the right conditions
        active_player = Find_Player("Empire"),
        extra_name = "EXTRA_REMNANT_SLOT",
        random_name = "RANDOM_REMNANT_ASSIGN",
        global_display_list = "REMNANT_LIST", --Name of global array used for documention of currently active heroes
        disabled = true
    }

    self:validate_hero_data_table(self.remnant_data)

    -- Fill the available_list
    for tag, _ in pairs(self.remnant_data.full_list) do
        table.insert(self.remnant_data.available_list, tag)
    end

    if self.remnant_data.total_slots == -1 then
        self.remnant_data.total_slots = table.getn(self.remnant_data.available_list)
    end
    if self.remnant_data.free_hero_slots == -1 then
        self.remnant_data.free_hero_slots = self.remnant_data.total_slots
    end
end

function HeroesManager:add_rep_heroes()
    if not self.RepHeroes.library then
        return
    end

    local admiral_data = self.RepHeroes.library["ADMIRAL"]
    if admiral_data and admiral_data.full_list and admiral_data.available_list then
        for tag, entry in pairs({
            ["Karrde"] = {"TALON_KARRDE_ASSIGN", {"TALON_KARRDE_WILD_KARRDE"}, "Talon Karrde"}, --Smugglers' Alliance
            ["Slixike"] = {"SLIXIKE_ASSIGN", {"SLIXIKE"}, "S'lixike"},
            ["Standish"] = {"STANDISH_ASSIGN", {"STANDISH_AAF2"}, "Anton Standish"},
            ["Rogriss"] = {"ROGRISS_ASSIGN", {"ROGRISS_ASSUAGER"}, "Teren Rogriss"},
            ["Yonka"] = {"YONKA_ASSIGN", {"YONKA_FREEDOM"}, "Sair Yonka"},
        }) do
            admiral_data.full_list[tag] = entry
            table.insert(admiral_data.available_list, tag)
            self:validate_hero_data_table(admiral_data)
        end
    end

    local army_data = self.RepHeroes.library["ARMY"]
    if army_data and army_data.full_list and army_data.available_list then
        for tag, entry in pairs({
            ["Alinda"] = {"ALINDA_ASSIGN",{"ALINDA_SOLARIS"},"Alinda", ["Companies"] = {"SOLARIS_TEAM"}},
            ["Mirax"] = {"MIRAX_ASSIGN",{"MIRAX"},"Mirax", ["Companies"] = {"MIRAX_TEAM"}},
        }) do
            army_data.full_list[tag] = entry
            table.insert(army_data.available_list, tag)
            self:validate_hero_data_table(army_data)
        end
    end

    local jedi_data = self.RepHeroes.library["JEDI"]
    if jedi_data and jedi_data.full_list and jedi_data.available_list then
        jedi_data.full_list["Mander"] = {"ZUMA_ASSIGN",{"MANDER_ZUMA"},"Mander Zuma", ["Companies"] = {"ZUMA_TEAM"},["Locked"] = false}
        table.insert(jedi_data.available_list, "Mander")
        self:validate_hero_data_table(jedi_data)
    end
end

---Checks if all hero tags in the table have valid XML entries
---@param hero_data HeroData
function HeroesManager:validate_hero_data_table(hero_data)
    if not hero_data or not hero_data.full_list then
        return
    end
    for tag, data in pairs(hero_data.full_list) do
        local debug_text = ""
        local assign = data[1] or {}
        local units = data[2] or {}

        if not TestValid(Find_Object_Type(assign)) then
            debug_text = debug_text .. ", Assign: " .. assign
        end
        for i, unit in ipairs(units) do
            if not TestValid(Find_Object_Type(unit)) then
                debug_text = debug_text .. ", Unit" .. i .. ": " .. unit
            end
        end
        if data["Companies"] then
            for i, company in ipairs(data["Companies"]) do
                if not TestValid(Find_Object_Type(company)) then
                    debug_text = debug_text .. ", Company" .. i .. ": " .. company
                end
            end
        end

        if debug_text ~= "" then
            debug_text = "BadTag: " .. tag .. debug_text
            StoryUtil.ShowScreenText(debug_text, 15, nil, {r=225, g=150, b=20})
        end
    end
end

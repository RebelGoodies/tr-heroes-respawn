--******************************************************************************
--     _______ __
--    |_     _|  |--.----.---.-.--.--.--.-----.-----.
--      |   | |     |   _|  _  |  |  |  |     |__ --|
--      |___| |__|__|__| |___._|________|__|__|_____|
--     ______
--    |   __ \.-----.--.--.-----.-----.-----.-----.
--    |      <|  -__|  |  |  -__|     |  _  |  -__|
--    |___|__||_____|\___/|_____|__|__|___  |_____|
--                                    |_____|
--*   @Author:              [TR]Jorritkarwehr
--*   @Date:                2021-03-20T01:27:01+01:00
--*   @Project:             Imperial Civil War
--*   @Filename:            HeroSystem.lua
--*   @Last modified by:    Jorritkarwehr
--*   @Last modified time:  
--*   @License:             This source code may only be used with explicit permission from the developers
--*   @Copyright:           © TR: Imperial Civil War Development Team
--******************************************************************************


require("PGStoryMode")
require("PGSpawnUnits")
require("eawx-util/ChangeOwnerUtilities")
StoryUtil = require("eawx-util/StoryUtil")

require("deepcore/std/class")

--Full list entry structure
--["Tag"] = {"Assign_unit",{"Retire1","Retire2"},{"Unit1","Unit2"},"Hero text ID", ["no_random"] = true, ["Companies"] = {"Company1","Company2"}, ["required_unit"] = "Unit", ["required_team"] = "team", ["Units"] = {{"Team1Unit1","Team1Unit2"},{"Team2Unit1","Team2Unit2"}}}
--no_random is optional and prevents the entry from being bought with the random entry
--Companies is optional and appears on ground units/squadrons within the system
--required_unit is optional and holds the object to despawn when the system hero is spawned (e.g. the Millenium Falcon for Mon Remonda)
--required_team is optional and holds the object to spawn when the system hero is edspawned (e.g. Han Team for Mon Remonda)
--Units is optional and holds multiple heroes within the team. Put the teams in the Unit1,Unit2... slots in this case

function init_hero_system(hero_data)
	hero_data.free_hero_slots = hero_data.free_hero_slots - Get_Active_Heroes(true, hero_data)
	hero_data.initialized = true
	Lock_Hero_Options(hero_data)
	Unlock_Hero_Options(hero_data)
end

function Handle_Build_Options(built_object, hero_data)
	if built_object == hero_data.random_name then
		spawn_random_option(hero_data)
	elseif built_object == hero_data.extra_name then
		Handle_New_Hero_Slot(hero_data)
	else
		for index, entry in pairs(hero_data.full_list) do
			if entry[1] == built_object then
				Handle_Hero_Spawn(index, hero_data)
			end
			for _, retire in pairs(entry[2]) do
				if retire == built_object then
					Handle_Hero_Despawn(index, hero_data)
				end
			end
		end
	end
end

function Lock_Hero_Options(hero_data)
	for index, entry in pairs(hero_data.full_list) do
		local assign_unit = Find_Object_Type(entry[1])
		hero_data.active_player.Lock_Tech(assign_unit)
	end
	local assign_unit = Find_Object_Type(hero_data.random_name)
	hero_data.active_player.Lock_Tech(assign_unit)
end

function Unlock_Hero_Options(hero_data)
	if hero_data.initialized and not hero_data.disabled then
		local random_count = 0
		if hero_data.free_hero_slots > 0 then
			for index, adm in pairs(hero_data.available_list) do
				local entry = hero_data.full_list[adm]
				local assign_unit = Find_Object_Type(entry[1])
				hero_data.active_player.Unlock_Tech(assign_unit)
				if not entry.no_random then
					random_count = random_count + 1
				end
			end
			if random_count > 0 then
				local assign_unit = Find_Object_Type(hero_data.random_name)
				hero_data.active_player.Unlock_Tech(assign_unit)
			end
		end
	end
	if hero_data.vacant_hero_slots > 0 and hero_data.vacant_limit > 0 then
		local assign_unit = Find_Object_Type(hero_data.extra_name)
		hero_data.active_player.Unlock_Tech(assign_unit)
	end
end

function Get_Active_Heroes(init, hero_data)
	local admiral_count = 0
	local text_list = {}
	for index, entry in pairs(hero_data.full_list) do
		if hero_data.full_list[index].unit_id == nil then
			hero_data.full_list[index].unit_id = 1
		end
		for index2, ship in pairs(entry[3]) do
			local find_it = Find_First_Object(ship)
			if entry.Units then
				for units_id=1,table.getn(entry.Units[index2]) do
					check_hero = Find_First_Object(entry.Units[index2][units_id])
					if TestValid(check_hero) then
						find_it = check_hero
						break
					end
				end
			end
			if TestValid(find_it) then
				if find_it.Get_Owner() == hero_data.active_player then
					admiral_count = admiral_count + 1
					if init == true then
						remove_hero_entry(index, hero_data)
					end
					local postfix = ""
					if hero_data.full_list[index].Locked then
						 postfix = " [Locked]"
					end
					table.insert(text_list, entry[4] .. postfix)
					hero_data.full_list[index].unit_id = index2 --Set the unit index to the version found
				end
				break
			end
		end
	end
	if init == true then
		hero_data.free_hero_slots = hero_data.total_slots - hero_data.vacant_hero_slots - admiral_count
	end
	
	DebugMessage("Admiral check count: %s vacant: %s total: %s", tostring(admiral_count), tostring(hero_data.vacant_hero_slots), tostring(hero_data.total_slots))
	for id=1,hero_data.free_hero_slots do
		table.insert(text_list, "OPEN")
	end
	for id=1,hero_data.vacant_hero_slots do
		table.insert(text_list, "VACANT (requires purchase)")
	end

	GlobalValue.Set(hero_data.global_display_list, text_list)
	return admiral_count
end

function remove_hero_entry(entry, hero_data)
	for index, obj in pairs(hero_data.available_list) do
		if obj == entry then
			table.remove(hero_data.available_list, index)
			return true
		end
	end
	return false
end

function check_hero_entry(entry, hero_data)
	for index, obj in pairs(hero_data.available_list) do
		if obj == entry then
			return true
		end
	end
	return false
end

function Handle_Hero_Despawn(hero_tag, hero_data)
	local hero_entry = hero_data.full_list[hero_tag]
	for flagship_id=1,table.getn(hero_entry[3]) do
		local hero_retire = hero_entry[2][flagship_id]
		local hero_unit = hero_entry[3][flagship_id]
		
		local check_hero = Find_First_Object(hero_retire)
		local planet
		if TestValid(check_hero) then
			planet = check_hero.Get_Planet_Location()
			check_hero.Despawn()
		end
		local bypassflag = false
		if hero_entry.Units then
			for units_id=1,table.getn(hero_entry.Units[flagship_id]) do
				check_hero = Find_First_Object(hero_entry.Units[flagship_id][units_id])
				if TestValid(check_hero) then
					check_hero.Despawn()
					bypassflag = true
				end
			end
		else
			check_hero = Find_First_Object(hero_unit)
		end
		if TestValid(check_hero) or bypassflag then
			hero_data.full_list[hero_tag].unit_id = flagship_id
			if not hero_entry.Units then
				check_hero.Despawn()
			end
			if hero_entry.required_team then
				if not TestValid(planet) then
					planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
				end
				SpawnList({hero_entry.required_team}, planet, hero_data.active_player, true, false)
			end
			if not check_hero_entry(hero_tag, hero_data) then --Don't double add to list if already in it.
				hero_data.free_hero_slots = hero_data.free_hero_slots + 1
				table.insert(hero_data.available_list, hero_tag)
			end
			Unlock_Hero_Options(hero_data)
			Get_Active_Heroes(false, hero_data)
			return true
			 --You could do the insert here so the retiree isn't immediately unlocked, but that makes it awkward to get them back if they're the only one in the pool
		end
	end
	return false
end

function Handle_Hero_Spawn(hero_tag, hero_data, planet)
	local hero_entry = hero_data.full_list[hero_tag]
	local corenne = false
	
	local hero_assign = hero_entry[1]
	local hero_unit 
	if hero_entry.Companies then
		hero_unit = hero_entry.Companies[hero_entry.unit_id]
	else
		hero_unit = hero_entry[3][hero_entry.unit_id]
	end
	
	local check_hero = Find_First_Object(hero_assign)
    if TestValid(check_hero) then
		planet = check_hero.Get_Planet_Location()
        check_hero.Despawn()
	else
		check_hero = Find_First_Object(hero_data.random_name)
		if TestValid(check_hero) then
			planet = check_hero.Get_Planet_Location()
			check_hero.Despawn()
		else
			if not planet then
				planet = StoryUtil.FindFriendlyPlanet(hero_data.active_player)
			end
		end
    end
	if hero_data.free_hero_slots > 0 then
		hero_data.free_hero_slots = hero_data.free_hero_slots - 1
		remove_hero_entry(hero_tag, hero_data)
		SpawnList({hero_unit}, planet, hero_data.active_player, true, false)
		if hero_entry.required_unit then
			local normal_form = Find_First_Object(hero_entry.required_unit)
			if TestValid(normal_form) then
				normal_form.Despawn()
			end
		end
		corenne = true
	end
	
	Lock_Hero_Options(hero_data)
	Unlock_Hero_Options(hero_data)
	Get_Active_Heroes(false,hero_data)
	return corenne
end

--Call this for deaths detected by Gamescoring
function Handle_Hero_Killed(killed_object, owner, hero_data)
	if hero_data.initialized then
		if Find_Player(owner) == hero_data.active_player then
			for index, entry in pairs(hero_data.full_list) do
				for j, variant in pairs(entry[3]) do
					local killing = false
					if variant == killed_object then
						killing = true
					end

					if entry.Companies then
						if entry.Companies[j] == killed_object then
							killing = true
						end
					end
					if killing then
						if hero_data.total_slots > 0 then
							if hero_data.active_player.Is_Human() then
								hero_data.vacant_hero_slots = hero_data.vacant_hero_slots + 1
								if hero_data.vacant_limit > 0 then
									local assign_unit = Find_Object_Type(hero_data.extra_name)
									hero_data.active_player.Unlock_Tech(assign_unit)
									StoryUtil.ShowScreenText("Be more careful with our heroes, Commander. We can only replace " .. hero_data.vacant_limit .. " more such loss(es).", 5, nil, {r = 244, g = 244, b = 0})
								else
									if hero_data.vacant_hero_slots >= hero_data.total_slots then
										StoryUtil.ShowScreenText("Your have spent enough lives of our heroes, Commander. There will be no more for you to spend.", 5, nil, {r = 244, g = 244, b = 0})
									else
										StoryUtil.ShowScreenText("We can no longer sustain these losses among our leadership, Commander. No more command positions will be opened if you lose what remains.", 5, nil, {r = 244, g = 244, b = 0})
									end
								end
								hero_data.vacant_limit = hero_data.vacant_limit - 1
								local text_list = GlobalValue.Get(hero_data.global_display_list)
								for i, text in pairs(text_list) do
									if text == entry[4] then
										table.remove(text_list,i)
										if hero_data.vacant_limit >= 0 then
											table.insert(text_list, "VACANT (requires purchase)")
										end
										GlobalValue.Set(hero_data.global_display_list, text_list)
										break
									end
								end
							else
								hero_data.free_hero_slots = hero_data.free_hero_slots + 1
								Unlock_Hero_Options(hero_data)
							end
							return index
						end
					end
				end
			end
		end
	end
	return nil
end

--Call this for deaths detected via XML
function Handle_Hero_Death(hero_data)
	--You'd think you could simply increment hero_data.vacant_hero_slots when someone dies, but two+ deaths in the same battle will only register one
	--On the plus side, calculating this from scratch means the distinction between death, retirement, and flagship swap is found here instead of through a bunch of disable events
	local active_heroes = Get_Active_Heroes(false,hero_data)
	hero_data.vacant_hero_slots = hero_data.total_slots - hero_data.free_hero_slots - active_heroes
	if hero_data.total_slots <= 0 then
		hero_data.vacant_hero_slots = 0
	end
	if hero_data.vacant_hero_slots > 0 then
		local assign_unit = Find_Object_Type(hero_data.extra_name)
		hero_data.active_player.Unlock_Tech(assign_unit)
	end
end

function Handle_New_Hero_Slot(hero_data)
	local new_slot = Find_First_Object(hero_data.extra_name)
	if TestValid(new_slot) then
		new_slot.Despawn()
	end
	if hero_data.vacant_limit >= 0 then
		if hero_data.active_player.Is_Human() then
			StoryUtil.ShowScreenText(hero_data.vacant_limit .. " more hero replacement(s) remain", 5, nil, {r = 244, g = 244, b = 0})
		end
		hero_data.vacant_hero_slots = hero_data.vacant_hero_slots - 1
		hero_data.free_hero_slots = hero_data.free_hero_slots + 1
		Unlock_Hero_Options(hero_data)
		if hero_data.vacant_hero_slots == 0 then
			local assign_unit = Find_Object_Type(hero_data.extra_name)
			hero_data.active_player.Lock_Tech(assign_unit)
		end
		Get_Active_Heroes(false,hero_data)
	else
		local assign_unit = Find_Object_Type(hero_data.extra_name)
		hero_data.active_player.Lock_Tech(assign_unit)
	end
end

--Handle the permanent removal of an option for story purposes
function Handle_Hero_Exit(hero_tag, hero_data, story_locked)
	local entry = hero_data.full_list[hero_tag]
	
	if entry == nil then
		return
	end
	
	local hero_found = false
	for flagship_id=1,table.getn(entry[3]) do
		if entry.Units then
			for units_id=1,table.getn(entry.Units[flagship_id]) do
				check_hero = Find_First_Object(entry.Units[flagship_id][units_id])
				if TestValid(check_hero) then
					check_hero.Despawn()
					hero_found = true
				end
			end
		else
			local find_it = Find_First_Object(entry[3][flagship_id])
			if TestValid(find_it) then
				find_it.Despawn()
				hero_found = true
				break
			end
		end
	end
	
	if hero_found then
		hero_data.free_hero_slots = hero_data.free_hero_slots + 1
		Lock_Hero_Options(hero_data)
		Unlock_Hero_Options(hero_data)
		Get_Active_Heroes(false,hero_data)
		if story_locked then
			hero_data.story_locked_list[hero_tag] = true
		end
		return true
	end
	
	if remove_hero_entry(hero_tag, hero_data) and story_locked then
		hero_data.story_locked_list[hero_tag] = true
	end
	Lock_Hero_Options(hero_data)
	Unlock_Hero_Options(hero_data)
	Get_Active_Heroes(false,hero_data)
	return false
end

--Handle the addition of an admiral to the pool
function Handle_Hero_Add(hero_tag, hero_data)
	--Don't add if the ship already exists
	if check_hero_entry(hero_tag, hero_data) then
		return
	end
	hero_data.story_locked_list[hero_tag] = false
	local entry = hero_data.full_list[hero_tag]
	for index, ship in pairs(entry[3]) do
		local find_it = Find_First_Object(ship)
		if TestValid(find_it) then
			return
		end
	end
	table.insert(hero_data.available_list, hero_tag)
	Unlock_Hero_Options(hero_data)
end

function Decrement_Hero_Amount(amount, hero_data)
	hero_data.total_slots = hero_data.total_slots - amount
	hero_data.free_hero_slots = hero_data.free_hero_slots - amount
	if hero_data.free_hero_slots <= 0 then
		Lock_Hero_Options(hero_data)
	end
	Get_Active_Heroes(false, hero_data)
end

function spawn_random_option(hero_data)
	local bound = table.getn(hero_data.available_list)
	local retry = true
	local rando
	while retry do
		retry = false
		rando = hero_data.available_list[GameRandom.Free_Random(1, bound)]
		if hero_data.full_list[rando].no_random then
			retry = true
		end
	end
	Handle_Hero_Spawn(rando, hero_data)
end

function set_unit_index(hero_tag, id, hero_data)
	local entry = hero_data.full_list[hero_tag]
	entry.unit_id = id
end

function lock_retires(hero_list, hero_data)
	for _, hero_tag in pairs(hero_list) do
		local entry = hero_data.full_list[hero_tag]

		if entry == nil then
			return
		end
		
		hero_data.full_list[hero_tag].Locked = true

		for _, retire in pairs(entry[2]) do
			local retire_unit = Find_Object_Type(retire)
			hero_data.active_player.Lock_Tech(retire_unit)
		end
	end
end

function check_hero_exists(hero_tag, hero_data)
	if hero_data.story_locked_list[hero_tag] then
		return true
	end
	if check_hero_entry(hero_tag, hero_data) then
		return true
	end
	local hero_entry = hero_data.full_list[hero_tag]
	for index, ship in pairs(hero_entry[3]) do
		local find_it = Find_First_Object(ship)
		if TestValid(find_it) then
			return true
		end
	end
	return false
end

function Show_Hero_Info(hero_data)
	local text_list = GlobalValue.Get(hero_data.global_display_list)
	local active_string = ""
	for i, text in pairs(text_list) do
		if i > 1 then
			active_string = active_string .. ", "
		end
		active_string = active_string .. text
	end
	StoryUtil.ShowScreenText("Active heroes: " .. hero_data.total_slots - hero_data.vacant_hero_slots - hero_data.free_hero_slots .. "     Total slots: " .. hero_data.total_slots, 5, nil, {r = 244, g = 244, b = 0})
	StoryUtil.ShowScreenText(active_string, 5, nil, {r = 244, g = 244, b = 0})
	StoryUtil.ShowScreenText("Remaining category hero losses: " .. hero_data.vacant_limit, 5, nil, {r = 244, g = 244, b = 0})
end

function Disable_Hero_Options(hero_data)
	hero_data.disabled = true
	Lock_Hero_Options(hero_data)
end

function Enable_Hero_Options(hero_data)
	hero_data.disabled = false
	Unlock_Hero_Options(hero_data)
end

function Set_Locked_Slots(hero_data, quantity)
	hero_data.vacant_hero_slots = hero_data.vacant_hero_slots + quantity
	hero_data.free_hero_slots = hero_data.free_hero_slots - quantity
	Unlock_Hero_Options(hero_data)
	Get_Active_Heroes(false, hero_data)
end
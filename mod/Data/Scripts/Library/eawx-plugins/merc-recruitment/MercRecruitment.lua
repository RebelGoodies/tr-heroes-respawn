require("deepcore/std/class")
require("eawx-util/StoryUtil")
require("deepcore/crossplot/crossplot")
require("PGStoryMode")
require("eawx-util/Sort")
require("deepcore/std/class")

MercRecruitment = class()

function MercRecruitment:new(gc)
	self.RecruitmentTables = require("MercRecruitmentLibrary")

	gc.Events.GalacticProductionFinished:attach_listener(self.on_production_finished, self)
end

function MercRecruitment:update()
	self.year = GlobalValue.Get("GALACTIC_YEAR")
	if self.year == nil then
		self.year = 0.0
	end

	for hireling_type,_ in pairs(self.RecruitmentTables) do
		self:candidate_pool_refresh(hireling_type)
	end
end

function MercRecruitment:candidate_pool_refresh(pool_name)
	local ValidUnitList = {}

	for k,v in pairs(self.RecruitmentTables[pool_name].BuildableOptions) do
		local stop_checking = false
		self.RecruitmentTables[pool_name].BuildableOptions[k].available = true

		if self.RecruitmentTables[pool_name].BuildableOptions[k].hired == true then
			self.RecruitmentTables[pool_name].BuildableOptions[k].available = false
			stop_checking = true
		end

		if stop_checking == false and not ((v.StartYear == nil or self.year >= v.StartYear) and (v.EndYear == nil or self.year <= v.EndYear)) then
			self.RecruitmentTables[pool_name].BuildableOptions[k].available = false
			stop_checking = true
		end

		local disablingevent = v.DisablingEvent
		if stop_checking == false and disablingevent ~= nil then
			local disablingevent = GlobalValue.Get(disablingevent)
			if disablingevent == true then
				self.RecruitmentTables[pool_name].BuildableOptions[k].available = false
				stop_checking = true
			end
		end

		local requiredhero = v.RequiredHero
		if stop_checking == false and requiredhero ~= nil then
			if not TestValid(Find_First_Object(requiredhero)) then
				self.RecruitmentTables[pool_name].BuildableOptions[k].available = false
				stop_checking = true
			end
		end

		local excludinghero = v.ExcludingHero
		if stop_checking == false and excludinghero ~= nil then
			if TestValid(Find_First_Object(excludinghero)) then
				self.RecruitmentTables[pool_name].BuildableOptions[k].available = false
				stop_checking = true
			end
		end

		if self.RecruitmentTables[pool_name].BuildableOptions[k].available == true then
			table.insert(ValidUnitList,v.key)
		end
	end

	if table.getn(ValidUnitList) > 0 then
		return
	end

	for _, faction in pairs(self.RecruitmentTables[pool_name].RecruiterOptions) do
		Find_Player(faction).Lock_Tech(Find_Object_Type(self.RecruitmentTables[pool_name].BuildDummyName))
	end
end

function MercRecruitment:on_production_finished(planet, object_type_name)
	if object_type_name ~= "RANDOM_MERCENARY" and object_type_name ~= "RANDOM_BOUNTY_HUNTER" then
		return
	end
	
	local object = Find_First_Object(object_type_name)

	local RecruiterFaction = object.Get_Owner()
	object.Despawn()

	local CurrentList = {}
	for k,entry in pairs(self.RecruitmentTables[object_type_name].BuildableOptions) do
		if entry.available == true then
			table.insert(CurrentList,entry.key)
		end
	end

	local option_count = table.getn(CurrentList)

	if option_count == 0 then
		StoryUtil.ShowScreenText("[No options available. Your investment has been returned to your budget.]", 15)
		if RecruiterFaction.Is_Human() then
			RecruiterFaction.Give_Money(3000)
			RecruiterFaction.Lock_Tech(Find_Object_Type(object_type_name))
		end
		return
	end

	if option_count == 1 then
		for _, faction in pairs(self.RecruitmentTables[object_type_name].RecruiterOptions) do
			Find_Player(faction).Lock_Tech(Find_Object_Type(object_type_name))
		end
	end

	local RandomEntry = GameRandom.Free_Random(1, option_count)
	local SelectedBuildableOption = CurrentList[RandomEntry]
	self.RecruitmentTables[object_type_name].BuildableOptions[SelectedBuildableOption].hired = true
	self.RecruitmentTables[object_type_name].BuildableOptions[SelectedBuildableOption].available = false

	local entry = self.RecruitmentTables[object_type_name].BuildableOptions[SelectedBuildableOption]

	SpawnList({entry.TeamName}, planet:get_game_object(), RecruiterFaction, true, true)

	if RecruiterFaction.Is_Human() then
		StoryUtil.ShowScreenText(entry.HireSpeech, 15)
	end
end

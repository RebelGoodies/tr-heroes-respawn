require("deepcore/std/class")
require("deepcore/crossplot/crossplot")
require("SetFighterResearch")
StoryUtil = require("eawx-util/StoryUtil")

---@class GovernmentNewRepublic
GovernmentNewRepublic = class()

---@param dummy_lifecycle_handler KeyDummyLifeCycleHandler
function GovernmentNewRepublic:new(id, dummy_lifecycle_handler)
    self.RepublicPlayer = Find_Player("Rebel")
	self.mediator = false
    self.planets = {}
    self.id = id
	
	crossplot:subscribe("BLUE_DIVER_RESEARCH", self.Mediator_Research, self)

    self.dummy_lifecycle_handler = dummy_lifecycle_handler

    self.chief_of_state = GlobalValue.Get("ChiefOfState")

    if self.chief_of_state == nil then
        self.chief_of_state = "DUMMY_CHIEFOFSTATE_MOTHMA"

        if GlobalValue.Get("CURRENT_ERA") >= 6 then
            self.chief_of_state = "DUMMY_CHIEFOFSTATE_LEIA"
        end

        GlobalValue.Set("ChiefOfState", self.chief_of_state)
    end

    GlobalValue.Set("ChiefOfStatePreference", self.chief_of_state)

    self.dummy_lifecycle_handler:add_to_dummy_set(
        self.RepublicPlayer,
        {
            [self.chief_of_state] = 1
        }
    )
    self.CoSOptions = {
        ["DUMMY_CHIEFOFSTATE_LEIA"] = "Leia_Loop",
        ["DUMMY_CHIEFOFSTATE_FEYLYA"] = "Borsk_Loop",
        ["DUMMY_CHIEFOFSTATE_MOTHMA"] = "Mon_Mothma_Loop",
        ["DUMMY_CHIEFOFSTATE_GAVRISOM"] = "Gavrisom_Loop",
        ["DUMMY_CHIEFOFSTATE_TEVV"] = "Sian_Tevv_Loop",
        ["DUMMY_CHIEFOFSTATE_SOBILLES"] = "Sobilles_Loop",
        ["DUMMY_CHIEFOFSTATE_NAVIK"] = "Navik_Loop",
        ["DUMMY_CHIEFOFSTATE_SHESH"] = "Viqi_Loop"
    }

    -- starting at -1 so the beginning of the first week doesn't count as a completed week
    self.LastElectionTime = -1

    if self.RepublicPlayer.Is_Human() then
        crossplot:subscribe("UPDATE_GOVERNMENT", self.UpdateDisplay, self)
    end

    self.Events = {}
    self.Events.ElectionHeld = Observable()	
end

function GovernmentNewRepublic:Mediator_Research()
    --Logger:trace("entering GovernmentNewRepublic:Mediator_Research")
	self.mediator = true
end

function GovernmentNewRepublic:Update()
    --Logger:trace("entering GovernmentNewRepublic:Update")
    DebugMessage("GovernmentNewRepublic Update Started")
    self.LastElectionTime = self.LastElectionTime + 1
    if self.LastElectionTime >= 10 then
        self:ElectionHeld()
        self.LastElectionTime = 0
    end

    DebugMessage("GovernmentNewRepublic Update Finished")
end

function GovernmentNewRepublic:ElectionHeld()
    --Logger:trace("entering GovernmentNewRepublic:ElectionHeld")
    DebugMessage("GovernmentNewRepublic ElectionHeld Started")

    if self.RepublicPlayer.Is_Human() == false then
        local ai_preference = GameRandom(1, 7)

        for cos_object_name, stats in pairs(self.CoSOptions) do
            --the AI will never elect Viqi Shesh ~Mord
            if cos_object_name ~= "DUMMY_CHIEFOFSTATE_SHESH" then
                ai_preference = ai_preference - 1
            end 
            
            if ai_preference == 0 then
                ai_preference = cos_object_name
                break
            end
        end
        
        GlobalValue.Set("ChiefOfStatePreference",ai_preference)
    end

    self.dummy_lifecycle_handler:remove_from_dummy_set(
        self.RepublicPlayer,
        {
            [self.chief_of_state] = 1
        }
    )

    self.chief_of_state = GlobalValue.Get("ChiefOfStatePreference")

    self.dummy_lifecycle_handler:add_to_dummy_set(
        self.RepublicPlayer,
        {
            [self.chief_of_state] = 1
        }
    )
	
	if self.chief_of_state ~= GlobalValue.Get("ChiefOfState") then
		local Bulwark = Find_Object_Type("Bulwark_III")
		local HomeOne = Find_Object_Type("Home_One_Type")
		local NewRep = Find_Player("Rebel")
		if self.chief_of_state == "DUMMY_CHIEFOFSTATE_TEVV" then
			Set_Fighter_Research("CoS_Tevv")
			if not self.mediator then
				NewRep.Unlock_Tech(Bulwark)
				NewRep.Lock_Tech(HomeOne)
			end
		else
			Clear_Fighter_Research("CoS_Tevv")
			if not self.mediator then
				NewRep.Lock_Tech(Bulwark)
				NewRep.Unlock_Tech(HomeOne)
			end
		end
		if self.chief_of_state == "DUMMY_CHIEFOFSTATE_SHESH" then
			Set_Fighter_Research("CoS_Shesh")
            crossplot:publish("MON_MOTHMA_RESEARCH", "empty")
		else
			Clear_Fighter_Research("CoS_Shesh")
		end
		if self.chief_of_state == "DUMMY_CHIEFOFSTATE_FEYLYA" then
            if GlobalValue.Get("CURRENT_ERA") >= 3 then
			    crossplot:publish("NR_ADMIRAL_STORYLOCK", {"Ackbar"}, 1)
                crossplot:publish("BAC_RESEARCH", "empty")
            else
                crossplot:publish("NR_ADMIRAL_STORYLOCK", {"Ackbar"}, 1)
            end
		else
			crossplot:publish("NR_ADMIRAL_RETURN", {"Ackbar"}, 1)
		end
	end

    GlobalValue.Set("ChiefOfState", self.chief_of_state)

    if self.RepublicPlayer.Is_Human() == true then
        self.Events.ElectionHeld:notify {
            winner = self.chief_of_state
        }

        StoryUtil.Multimedia("", 5, nil, self.CoSOptions[self.chief_of_state], 0)
    end

    DebugMessage("GovernmentNewRepublic ElectionHeld Finished")
end

function GovernmentNewRepublic:UpdateDisplay()
    --Logger:trace("entering GovernmentNewRepublic:UpdateDisplay")
    local plot = Get_Story_Plot("Conquests\\Player_Agnostic_Plot.xml")
    local government_display_event = plot.Get_Event("Government_Display")

    if self.RepublicPlayer.Is_Human() then
        government_display_event.Clear_Dialog_Text()

        government_display_event.Set_Reward_Parameter(1, "REBEL")

        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")

        government_display_event.Add_Dialog_Text(
            "TEXT_GOVERNMENT_CURRENT_COS",
            Find_Object_Type(GlobalValue.Get("ChiefOfState"))
        )
        government_display_event.Add_Dialog_Text(
            "TEXT_GOVERNMENT_SUPPORTED_COS",
            Find_Object_Type(GlobalValue.Get("ChiefOfStatePreference"))
        )
		if self.id == "FTGU" then
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_COMMAND_STAFF_FTGU")
		else
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_ADMIRAL_LIST")
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			local admiral_list = GlobalValue.Get("NR_ADMIRAL_LIST")
			if admiral_list ~= nil then
				for index, obj in pairs(admiral_list) do
					government_display_event.Add_Dialog_Text(obj)
				end
			end
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_COUNCIL_LIST")
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			local admiral_list = GlobalValue.Get("NR_JEDI_LIST")
			if admiral_list ~= nil then
				for index, obj in pairs(admiral_list) do
					government_display_event.Add_Dialog_Text(obj)
				end
			end
		end
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        
        government_display_event.Add_Dialog_Text("TEXT_NONE")
        
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_OVERVIEW_HEADER")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_OVERVIEW")
        
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_CANDIDATES")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        -- Always options
        government_display_event.Add_Dialog_Text("TEXT_HERO_LEIA")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REQUIREMENTS_NONE")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_LEIA_EFFECT")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_HERO_MON_MOTHMA")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REQUIREMENTS_NONE")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_MOTHMA_EFFECT")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_HERO_BORSK")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REQUIREMENTS_NONE")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_FEYLYA_EFFECT")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_HERO_GAVRISOM")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REQUIREMENTS_NONE")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_GAVRISOM_EFFECT")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_HERO_TEVV")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REQUIREMENTS_NONE")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_TEVV_EFFECT")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_HERO_SOBILLES")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REQUIREMENTS_NONE")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_SOBILLES_EFFECT")
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_HERO_NAVIK")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REQUIREMENTS_NONE")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NAVIK_EFFECT")
        -- Not always options
        government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
        government_display_event.Add_Dialog_Text("TEXT_HERO_SHESH")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_REQUIREMENTS_KUAT")
        government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_SHESH_EFFECT")
        
        government_display_event.Add_Dialog_Text("TEXT_NONE")
		
		if self.id == "FTGU" then

		else
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_HERO_SYSTEM_HEADER")
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_HERO_SYSTEM")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_HERO_SYSTEM_0")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_HERO_SYSTEM_1")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_HERO_SYSTEM_2")
				
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_LIST")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_ACKBAR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_NANTZ")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_SOVV")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_HAN")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_HAN2")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_LANDO")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_GARM")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_DRAYSON")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_TALLON")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_BURKE")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_MASSA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_DORAT")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_RAGAB")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_SNUNB")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_KALBACK")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_VANTAI")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_GRANT")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_BELL")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_BRAND")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_ABAHT")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_KREFEY")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_NAMMO")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_ADMIRAL_ACKDOOL")
			
			government_display_event.Add_Dialog_Text("TEXT_DOCUMENTATION_BODY_SEPARATOR")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_COUNCIL_LIST")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_COUNCIL_KYLE")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_COUNCIL_MARA")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_COUNCIL_CILGHAL")
			government_display_event.Add_Dialog_Text("TEXT_GOVERNMENT_NEW_REPUBLIC_COUNCIL_CORRAN")
		
		end
		
        Story_Event("GOVERNMENT_DISPLAY")
	end
end


return GovernmentNewRepublic
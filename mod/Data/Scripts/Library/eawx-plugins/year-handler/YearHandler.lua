require("deepcore/std/class")
CONSTANTS = ModContentLoader.get("GameConstants")

---@class YearHandler
YearHandler = class()

---@param start_year integer
---@param id string
function YearHandler:new(start_year, start_month, id)
    self.start_year = start_year
    self.suffix = CONSTANTS.YEAR_SUFFIX
    self.events = true
    if id == "FTGU" then
        self.events = false
    end
    if start_year == nil then
        self.start_year = CONSTANTS.START_YEAR
    end
    self.current_year = self.start_year
    GlobalValue.Set("GALACTIC_YEAR", self.current_year)
    if self.suffix == "BBY" then
        GlobalValue.Set("GALACTIC_YEAR", 0 - self.current_year)
    else
        GlobalValue.Set("GALACTIC_YEAR", self.current_year)
    end
    if start_month then
        self.month = start_month
    else
        self.month = 1
    end

    self.cycle = -1 --for FotR

    self.current_year_text = tostring(self.current_year) .." ".. self.suffix.. " month "..tostring(self.month)
    self.isFotR = Find_Object_Type("fotr")
    if self.isFotR then
        if self.start_year == 22 then
            self.month = 6
        end
		GlobalValue.Set("ACTIVE_MOD", 1) -- 0 = TR; 1 = FotR; 2 = RevRev
    end
    self.EventLibrary = require("YearlyEventLibrary")
end

function YearHandler:update()
    self.cycle = self.cycle + 1
    if self.isFotR then
        if self.cycle >= 2 then
            self.month = self.month + 1
            self.cycle = 0
        end
    else
        if self.cycle > 0 then
            self.month = self.month + 1
            self.cycle = 0
        end
    end

    if self.month == 13 then
        if self.suffix == "BBY" then
            self.current_year = self.current_year - 1
            GlobalValue.Set("GALACTIC_YEAR", 0 - self.current_year)
        else
            self.current_year = self.current_year + 1
            GlobalValue.Set("GALACTIC_YEAR", self.current_year)
        end
        self.month = 1
        if self.current_year == 0 then
            if self.suffix == "BBY" then
                self.suffix = "ABY"
            end
        end
        crossplot:publish("ENTER_"..self.current_year..self.suffix, "empty")
    end
    self.current_year_text = tostring(self.current_year) .." ".. self.suffix.. " month "..tostring(self.month)
    local year_only_text = tostring(self.current_year) .." ".. self.suffix
    if self.EventLibrary[year_only_text] then
        for _, event in pairs(self.EventLibrary[year_only_text]) do
            if event.month == self.month and self.cycle == 0 and self.events then
                crossplot:publish(event.name, "empty")
            end
        end
    end
end

return YearHandler
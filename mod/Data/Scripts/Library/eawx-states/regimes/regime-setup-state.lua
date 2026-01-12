require("deepcore/crossplot/crossplot")

return {
    on_enter = function(self, state_context)
        GlobalValue.Set("REGIME_INDEX", 1)
    end,
    on_update = function(self, state_context)
    end,
    on_exit = function(self, state_context)
    end
}
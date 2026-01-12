require("eawx-statemachine/EawXState")
require("deepcore/statemachine/DeepCoreState")

---@param dsl dsl
return function(dsl)
    local policy = dsl.policy
    local effect = dsl.effect
    local owned_by = dsl.conditions.owned_by

    local initialize = DeepCoreState.with_empty_policy()
    local setup = DeepCoreState(require("eawx-states/ftgu-setup-state"))

    dsl.transition(initialize)
        :to(setup)
        :when(policy:timed(2))
        :end_()
    
    return initialize
end

require("deepcore/statemachine/DeepCoreState")

---@param dsl dsl
return function(dsl)
    local policy = dsl.policy

    local initialize = DeepCoreState.with_empty_policy()
    local setup = DeepCoreState(require("eawx-states/tr-setup-state"))
    local era_one = DeepCoreState(require("eawx-states/ftgu/tr-ftgu-era-one"))
    local era_two = DeepCoreState(require("eawx-states/ftgu/tr-ftgu-era-two"))
    local era_three = DeepCoreState(require("eawx-states/ftgu/tr-ftgu-era-three"))
    local era_four = DeepCoreState(require("eawx-states/ftgu/tr-ftgu-era-four"))
    local era_five = DeepCoreState(require("eawx-states/ftgu/tr-ftgu-era-five"))
    local era_six = DeepCoreState(require("eawx-states/ftgu/tr-ftgu-era-six"))
    local era_seven = DeepCoreState(require("eawx-states/ftgu/tr-ftgu-era-seven"))

    dsl.transition(initialize)
        :to(setup)
        :when(policy:timed(2))
        :end_()

    dsl.transition(setup)
        :to(era_two)
        :when(policy:global_era(2))
        :end_()

    dsl.transition(setup)
        :to(era_three)
        :when(policy:global_era(3))
        :end_()

    dsl.transition(setup)
        :to(era_four)
        :when(policy:global_era(4))
        :end_()

    dsl.transition(setup)
        :to(era_five)
        :when(policy:global_era(5))
        :end_()
        
    dsl.transition(setup)
        :to(era_six)
        :when(policy:global_era(6))
        :end_()

    dsl.transition(setup)
        :to(era_seven)
        :when(policy:global_era(7))
        :end_()

    return initialize
end

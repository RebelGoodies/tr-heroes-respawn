require("PGStoryMode")
require("RandomGCSpawn")
require("deepcore/crossplot/crossplot")

function Definitions()

    DebugMessage("%s -- In Definitions", tostring(Script))
    StoryModeEvents = {
		Delayed_Initialize = Initialize
	}
	
end		

function Initialize(message)
    if message == OnEnter then
		crossplot:galactic()
		p_newrep = Find_Player("Rebel")
		if p_newrep.Is_Human() then
			crossplot:publish("NR_ADMIRAL_DECREMENT", 10)
			crossplot:publish("NR_ADMIRAL_LOCKIN", {"Bell"})
		end
	else
		crossplot:update()
    end
end
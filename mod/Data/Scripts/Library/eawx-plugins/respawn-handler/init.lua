---@License: MIT

require("deepcore/std/plugintargets")
require("eawx-plugins/respawn-handler/RespawnHandler")

return {
    type = "plugin",
    target = PluginTargets.never(),
    init = function(self, ctx)
        local gc = ctx.galactic_conquest
        return RespawnHandler(gc, ctx.id)
    end
}

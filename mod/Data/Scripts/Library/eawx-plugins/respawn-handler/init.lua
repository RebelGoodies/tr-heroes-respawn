require("deepcore/std/plugintargets")
require("eawx-plugins/respawn-handler/RespawnHandler")

return {
    type = "plugin",
    target = PluginTargets.never(),
    init = function(self, ctx)
        local galactic_conquest = ctx.galactic_conquest
        return RespawnHandler(galactic_conquest, ctx.id)
    end
}
 
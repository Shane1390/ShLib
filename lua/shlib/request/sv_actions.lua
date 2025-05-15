SHLIB.Actions = SHLIB.Actions or {}
SHLIB.Net.Types = SHLIB.Net.Types or {}

local actionStr = SHLIB.Config.ActionString
util.AddNetworkString(actionStr)

function SHLIB.Net:RegisterAction(name, argType)
    SHLIB.Actions[name] = function(_, ply, arg)
        net.Start(actionStr)
            net.WriteString(name)
            if argType then argType.Write(arg) end
        -- Broadcast if no ply provided
        if IsValid(ply) then net.Send(ply)
        else net.Broadcast() end
    end
end
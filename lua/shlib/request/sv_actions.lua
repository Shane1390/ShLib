SHLIB.Actions = SHLIB.Actions or {}
SHLIB.Net.Types = SHLIB.Net.Types or {}

util.AddNetworkString(SHLIB.Net.ActionString)

function SHLIB.Net:RegisterAction(name, argType)
    SHLIB.Actions[name] = function(_, ply, arg)
        net.Start(SHLIB.Net.ActionString)
            net.WriteString(name)
            if argType then argType.Write(arg) end
        -- Broadcast if no ply provided
        if IsValid(ply) then net.Send(ply)
        else net.Broadcast() end
    end
end
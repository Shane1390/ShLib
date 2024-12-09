SHLIB.Actions = SHLIB.Actions or {}
SHLIB.Net.Trans = SHLIB.Net.Trans or {}

local actions = SHLIB.Actions
local trans = SHLIB.Net.Trans

function SHLIB.Net:RegisterAction(name, argType)
    actions[name] = {
        ArgType = argType
    }
end

function SHLIB.Net:ImplementAction(name, impl)
    actions[name].Implementation = impl
end

net.Receive(SHLIB.Net.ActionString, function()
    local actionName = net.ReadString()
    local action = actions[actionName]
    local arg = action.ArgType and action.ArgType.Read()

    if not action.Implementation then error("No implementation found for request: " .. actionName) end
    action.Implementation(arg)
end)
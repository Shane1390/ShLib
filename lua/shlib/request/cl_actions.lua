SHLIB.Actions = SHLIB.Actions or {}

local actions = SHLIB.Actions
local actionStr = SHLIB.Config.ActionString

function SHLIB.Net:RegisterAction(name, argType)
    actions[name] = actions[name] or {}
    actions[name].ArgType = argType
end

function SHLIB.Net:ImplementAction(name, impl)
    actions[name] = actions[name] or {}
    actions[name].Implementation = impl
end

net.Receive(actionStr, function()
    local actionName = net.ReadString()

    local action = actions[actionName]
    if not action then error("No action registered for request: " .. actionName) end

    local arg = action.ArgType and action.ArgType.Read()
    if not action.Implementation then error("No implementation found for request: " .. actionName) end

    action.Implementation(arg)
end)
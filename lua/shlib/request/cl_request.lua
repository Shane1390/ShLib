SHLIB.Net.Requests = SHLIB.Net.Requests or {}
SHLIB.Net.Endpoints = SHLIB.Net.Endpoints or {}
SHLIB.Net.Trans = SHLIB.Net.Trans or {}
SHLIB.Net.Types = SHLIB.Net.Types or {}
SHLIB.Net.SyncVar = SHLIB.Net.SyncVar or 0

SHLIB.Client = SHLIB.Client or {}

local requests = SHLIB.Net.Requests
local endpoints = SHLIB.Net.Endpoints
local trans = SHLIB.Net.Trans

local requestStr = SHLIB.Config.RequestString
local timeout = SHLIB.Config.Timeout

local function CreateThreadTimeout(id)
    timer.Create(requestStr .. id, timeout, 1, function()
        local request = requests[id]
        requests[id] = nil

        if request.Thread then
            print("Request timed out.")
            SHLIB:ResumeThread(request.Thread, false)
        end
    end)
end

local function GetSyncVar()
    SHLIB.Net.SyncVar = SHLIB.Net.SyncVar + 1
    return tostring(SHLIB.Net.SyncVar)
end

-- MUST be run async
function SHLIB:SendRequest(name, ...)
    local syncVar = GetSyncVar()
    local endpoint = endpoints[name]

    net.Start(requestStr)
        trans:WriteClientHeader(name, syncVar)
        if endpoint.ArgType then endpoint.ArgType.Write(...) end
    net.SendToServer()

    requests[syncVar] = { Thread = coroutine.running(), ReturnFunc = endpoint.RetType and endpoint.RetType.Read }
    CreateThreadTimeout(syncVar)
    return coroutine.yield()
end

net.Receive(requestStr, function()
    local request = trans.ReadResponseHeader()
    local tbl = requests[request.Id]

    if request then
        local success = request.Status == trans.Status.Success
        local ret = success and tbl.ReturnFunc and tbl.ReturnFunc()
        SHLIB:ResumeThread(tbl.Thread, success, ret)
    end

    timer.Remove(requestStr .. request.Id)
end)

function SHLIB.Net:RegisterRequest(name, accessLevel, argType, retType)
    endpoints[name] = {
        ArgType = argType,
        RetType = retType
    }

    -- We're disposing the table param here, so we can invoke with a colon instead
    SHLIB.Client[name] = function(_, arg)
        if not trans.Access[accessLevel](LocalPlayer()) then return end
        return SHLIB:SendRequest(name, arg)
    end
end
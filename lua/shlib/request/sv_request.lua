SHLIB.Net.Requests = SHLIB.Net.Requests or {}
SHLIB.Net.Trans = SHLIB.Net.Trans or {}

util.AddNetworkString(SHLIB.Net.RequestString)

local requests = SHLIB.Net.Requests
local trans = SHLIB.Net.Trans

local function HandleRequest(ply)
    local header = trans:ReadClientHeader()
    local tbl = requests[header.Name]

    if trans.Access[tbl.AccessLevel](ply) then
        local request = tbl.ArgType and tbl.ArgType.Read()
        local status, response = tbl.Implementation(ply, request)

        net.Start(SHLIB.Net.RequestString)
            trans:WriteResponseHeader(header.ClID, status and trans.Status.Success or trans.Status.ServerError)
            -- Don't network DB errors to the client
            if status and response and tbl.RetType then tbl.RetType.Write(response) end
        net.Send(ply)
    else
        net.Start(SHLIB.Net.RequestString)
            trans:WriteResponseHeader(header.ClID, trans.Status.Unauthorized)
        net.Send(ply)
    end
end

net.Receive(SHLIB.Net.RequestString, function(_, ply)
    SHLIB:Async(function() HandleRequest(ply) end)()
end)

function SHLIB.Net:RegisterRequest(name, accessLevel, argType, retType)
    requests[name] = requests[name] or {}

    requests[name].AccessLevel = accessLevel
    requests[name].ArgType = argType
    requests[name].RetType = retType
end

function SHLIB.Net:ImplementRequest(name, impl)
    requests[name] = requests[name] or {}
    requests[name].Implementation = impl
end
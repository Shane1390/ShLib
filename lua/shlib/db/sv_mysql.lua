require("mysqloo")

local SQL = {}
local dbConnection

function SQL:Connect()
    local running = coroutine.running()
    local dbConfig = SHLIB.Config.SQL
    local db = mysqloo.connect(dbConfig.Host, dbConfig.Username, dbConfig.Password, dbConfig.Database, dbConfig.Port)

    function db:onConnected()
        dbConnection = self
        SHLIB:ResumeThread(running, true)
    end

    function db:onConnectionFailed(err)
        SHLIB:ResumeThread(running, false, err)
    end

    db:connect()
    return coroutine.yield()
end

local function HandleAsync(dbObj)
    local running = coroutine.running()

    function dbObj:onSuccess(data)
        SHLIB:ResumeThread(running, true, data)
    end

    function dbObj:onError(err)
        print("[ShLib] DB Error: " .. err)
        SHLIB:ResumeThread(running, false, err)
    end

    dbObj:start()
    return coroutine.yield()
end

local function CreateQueryObj(query)
    return dbConnection:query(query)
end

function SQL:Query(query)
    local queryObj = CreateQueryObj(query)
    return HandleAsync(queryObj)
end

function SQL:QueryInsert(query)
    local dbObj = CreateQueryObj(query)

    local result, data = HandleAsync(dbObj)
    if not result then return result, data end

    dbObj:getNextResults()
    return result, dbObj:getData()[1]["LAST_INSERT_ID()"]
end

function SQL:Escape(query)
    return dbConnection:escape(query)
end

return SQL
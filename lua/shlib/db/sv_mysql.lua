require("mysqloo")

local SQL = {}
local dbConnection

function SQL:Connect()
    local running = coroutine.running()
    local dbConfig = SHLIB.SQL.Config
    local db = mysqloo.connect(dbConfig.Host, dbConfig.Username, dbConfig.Password, dbConfig.Database, dbConfig.Port)

    function db:onConnected()
        dbConnection = self
        coroutine.resume(running, true)
    end

    function db:onConnectionFailed(err)
        coroutine.resume(running, false, err)
    end

    db:connect()
    return coroutine.yield()
end

local function HandleAsync(dbObj)
    local running = coroutine.running()

    function dbObj:onSuccess(data)
        coroutine.resume(running, true, data)
    end

    function dbObj:onError(err)
        print("DB Error: " .. err)
        coroutine.resume(running, false, err)
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

local function GetID(idData)
    return idData[2][1].InsertID
end

function SQL:QueryInsert(query)
    local transObj = dbConnection:createTransaction()
    transObj:addQuery(CreateQueryObj(query))
    transObj:addQuery(CreateQueryObj([[SELECT LAST_INSERT_ID() AS InsertID]]))

    local result, idData = HandleAsync(transObj)
    return result, result and GetID(idData)
end

function SQL:Escape(query)
    return dbConnection:escape(query)
end

return SQL
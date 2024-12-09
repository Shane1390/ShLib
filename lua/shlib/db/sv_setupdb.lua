SHLIB.SQL.Tables = SHLIB.SQL.Tables or {}
local tables = SHLIB.SQL.Tables

local function AttemptDBConnect(dbIf)
    local status, err = dbIf:Connect()

    if not status then
        ErrorNoHalt("DB connection failed, falling back to SQLite: " .. err)
    end

    return status
end

function SHLIB:InitializeDatabase()
    local dbIf, dbConnectStatus
    
    if SHLIB.SQL.Config.UseMySQL then
        dbIf = include("shlib/db/sv_mysql.lua")
        dbConnectStatus = AttemptDBConnect(dbIf)
    end

    if dbConnectStatus then
        print("Connected to MySQL successfully!")
    else
        dbIf = include("shlib/db/sv_sqlite.lua")
        AttemptDBConnect(dbIf)

        print("Connected to SQLite successfully!")
    end

    table.Merge(SHLIB.SQL.Connector, dbIf)
end

function SHLIB:SetupDatabaseTables()
    for _, tbl in ipairs(tables) do
        local status, err = self.SQL.Connector:Query(tbl.Query)

        if status then
            print("Successfully registered table: " .. tbl.Name)
        else
            print("Error registering table " .. tbl.Name .. ": " .. err)
        end
    end
end

function SHLIB:AddDatabaseTable(name, query)
    table.insert(tables, { Name = name, Query = query })
end

local function Initialize()
    SHLIB:Async(function()
        hook.Run("SHLIB_RegisterDatabaseTables")

        SHLIB:InitializeDatabase()
        SHLIB:SetupDatabaseTables()
    end)()
end
hook.Add("Initialize", "SHLIB::Initialize", Initialize)
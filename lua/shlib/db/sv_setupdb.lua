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

    if SHLIB.Config.SQL.UseMySQL then
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

function SHLIB:CreateDatabaseTable(name, def)
    local status, err = self.SQL.Connector:Query(def)

    if status then
        print("Successfully registered table: " .. name)
    else
        print("Error registering table " .. name .. ": " .. err)
    end
end

function SHLIB:SetupDatabaseTables()
    for _, tbl in ipairs(tables) do
        self:CreateDatabaseTable(tbl.Name, tbl.Query)
    end
end

function SHLIB:AddDatabaseTable(name, query)
    table.insert(tables, { Name = name, Query = query })
end
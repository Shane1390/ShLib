SHLIB = SHLIB or {}
SHLIB.Config = SHLIB.Config or {}

SHLIB.SQL = SHLIB.SQL or {}
SHLIB.SQL.Connector = SHLIB.SQL.Connector or {}

function SHLIB:IncludeFolder(path)
    local files, folders = file.Find(path .. "/*", "LUA")

    for _, fileName in ipairs(files) do
        if not fileName:EndsWith(".lua") then continue end

        if SERVER and not fileName:StartWith("sv_") then
            AddCSLuaFile(path .. "/" .. fileName)

            if fileName:StartWith("cl_") then continue end
        end

        include(path .. "/" .. fileName)
    end

    for _, folderName in ipairs(folders) do
        self:IncludeFolder(path .. "/" .. folderName)
    end
end

SHLIB:IncludeFolder("shlib_config")
SHLIB:IncludeFolder("shlib")

local function Initialize()
    hook.Run("SHLIB_Initialize")
    if CLIENT then return end

    SHLIB:Async(function()
        hook.Run("SHLIB_RegisterDatabaseTables")

        SHLIB:InitializeDatabase()
        SHLIB.ORM:ParseDatabaseTables()
        SHLIB:SetupDatabaseTables()

        hook.Run("SHLIB_DatabaseInitialized")
    end)()
end
hook.Add("Initialize", "SHLIB::Initialize", Initialize)
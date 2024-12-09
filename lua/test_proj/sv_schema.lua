hook.Add("SHLIB_RegisterDatabaseTables", "TestProj::RegisterDatabaseTables", function()
    SHLIB:AddDatabaseTable("SHLIB_Test", [[
        CREATE TABLE IF NOT EXISTS SHLIB_Players (
        PlayerID INT NOT NULL AUTO_INCREMENT,
        Name VARCHAR(64),

        PRIMARY KEY (PlayerID)
    )
    ]])
end)
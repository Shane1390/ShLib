local connector = SHLIB.SQL.Connector

SHLIB.Net:ImplementRequest("AddPlayer", function(_, name)
    local query = ([[
        INSERT INTO SHLIB_Players (Name)
        VALUES ('%s')
    ]]):format(name)

    return connector:QueryInsert(query)
end)

SHLIB.Net:ImplementRequest("RemovePlayer", function(_, ID)
    local query = ([[
        DELETE FROM SHLIB_Players
        WHERE PlayerID = %d
    ]]):format(ID)

    return connector:Query(query)
end)

SHLIB.Net:ImplementRequest("GetPlayers", function()
    return connector:Query([[
        SELECT PlayerID, Name
        FROM SHLIB_Players
    ]])
end)
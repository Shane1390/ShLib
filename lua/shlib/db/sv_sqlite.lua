local SQL = {}
local dbConnection

function SQL:Connect()
    return true
end

function SQL:Query(query)
    local result = sql.Query(query)

    if result == false then
        return false, sql.LastError()
    elseif result == nil then
        return true, {}
    else
        return true, result
    end
end

function SQL:Escape(query)
    return sql.SQLStr(query)
end

function SQL:QueryInsert(query)
    local result, data = self:Query(query)
    if not result then return result, data end

    local rowId = sql.Query([[SELECT LAST_INSERT_ROWID()]])
    return result, rowId and rowId[1]["LAST_INSERT_ROWID()"]
end

return SQL
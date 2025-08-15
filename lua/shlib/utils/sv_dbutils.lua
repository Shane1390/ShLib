local function FormatForSQL(tbl)
    return "(" .. table.concat(tbl, ", ") .. ")"
end

function SHLIB:SQLFormat(values, formatter)
    local tbl = {}
    local formattedValues = formatter and formatter(values) or values

    for _, value in ipairs(formattedValues) do
        if isstring(value) then table.insert(tbl, string.format("'%s'", value))
        else table.insert(tbl, value) end
    end

    return FormatForSQL(tbl)
end

function SHLIB:SQLFormatList(valueList, formatter)
    local values = {}

    for _, value in ipairs(valueList) do
        table.insert(values, self:SQLFormat(value, formatter))
    end

    return table.concat(values, ", ")
end

function SHLIB:SQLFormatIDs(values, idKey)
    local listID = {}

    for _, value in ipairs(values) do
        table.insert(listID, value[idKey])
    end

    return FormatForSQL(listID)
end
SHLIB.DbContext = SHLIB.DbContext or {}
SHLIB.QueryBuilder = SHLIB.QueryBuilder or {}
SHLIB.QueryBuilder.Builders = SHLIB.QueryBuilder.Builders or {}
SHLIB.QueryBuilder.UpdateCache = SHLIB.QueryBuilder.UpdateCache or {}
SHLIB.QueryBuilder.InsertCache = SHLIB.QueryBuilder.InsertCache or {}

local connector = SHLIB.SQL.Connector
local queryBuilder = SHLIB.QueryBuilder
local updateCache = queryBuilder.UpdateCache
local insertCache = queryBuilder.InsertCache
local dbContext = SHLIB.DbContext

local baseBuilder = {}
baseBuilder.__index = baseBuilder

local selectTemplate = [[
SELECT
    %s
FROM %s
%s%s
]]

function baseBuilder:BuildSelect()
    return selectTemplate:format(
        table.concat(self.SelectArgs, ",\n    "),
        self.Table,
        table.concat(self.JoinArgs, "\n"),
        next(self.WhereArgs) and "WHERE " .. table.concat(self.WhereArgs, "\nAND ") or ""
    )
end

function baseBuilder:Select(arg)
    table.insert(self.SelectArgs, tostring(arg))
    self.BuildQuery = self.BuildSelect

    return self
end

local deleteTemplate = [[
DELETE FROM %s
WHERE %s IN (%s)
]]

function baseBuilder:BuildDelete()
    return deleteTemplate:format(
        self.Table,
        self.Context.Constraints.PrimaryKey,
        table.concat(self.DeleteIds, ", ")
    )
end

function baseBuilder:IsListOfObjects(objs)
    local id, obj = next(objs)
    return (id == 1 and istable(obj)), obj
end

function baseBuilder:Delete(items)
    self.DeleteIds = {}

    -- Singular int id delete
    if not istable(items) then
        table.insert(self.DeleteIds, items)
    -- Will only succeed if each item contains the pkey - otherwise we catch lists of ints later
    elseif self:IsListOfObjects(items) then
        for _, item in ipairs(items) do
            table.insert(self.DeleteIds, item[self.Context.Constraints.PrimaryKey])
        end
    -- Think we've only got 1 object, make sure it matches the schema by checking for the pkey
    elseif items[self.Context.Constraints.PrimaryKey] then
        table.insert(self.DeleteIds, items[self.Context.Constraints.PrimaryKey])
    -- If the pkey isn't present, then the object is probably just a list of ids
    else
        for _, item in ipairs(items) do
            table.insert(self.DeleteIds, item)
        end
    end

    self.BuildQuery = self.BuildDelete
    return self
end

local insertTemplate = [[
INSERT INTO %s (%s)
VALUES (%s);

SELECT LAST_INSERT_ID()
]]

function baseBuilder:CanColumnBeInsertOrUpdated(column, allColumns)
    return self.Context.Columns[column] ~= nil
        and (allColumns or self.Context.Constraints.PrimaryKey ~= column)
end

function baseBuilder:GetObjTemplate(obj, allColumns)
    local columns = {}

    for key in pairs(obj) do
        if not self:CanColumnBeInsertOrUpdated(key, allColumns) then continue end
        table.insert(columns, key)
    end

    return columns
end

function baseBuilder:GetListTypeAndTemplate(objList, allColumns)
    local isListType, obj = self:IsListOfObjects(objList)

    local template = isListType
        and self:GetObjTemplate(obj, allColumns)
        or self:GetObjTemplate(objList, allColumns)

    return isListType, template
end

function baseBuilder:GetValuesArg(obj, template)
    local value = {}

    for _, column in ipairs(template) do
        local str = self.Context.Columns[column].IsString and "'%s'" or "%d"
        table.insert(value, str:format(obj[column]))
    end

    return table.concat(value, ", ")
end

function baseBuilder:GetValueString(obj, template)
    return self:GetValuesArg(obj, template)
end

function baseBuilder:GetValuesString(items, template)
    local values = {}

    for _, obj in ipairs(items) do
        table.insert(values, self:GetValueString(obj, template))
    end

    return table.concat(values, "), (")
end

function baseBuilder:GetKey(key)
    return ("%p_%s%s"):format(debug.getinfo(3).func, self.Table, key or "")
end

function baseBuilder:GenerateInsertQuery(items)
    local isListType, objTemplate = self:GetListTypeAndTemplate(items, false)

    insertCache[self.InsertKey] = {
        IsListType = isListType,
        ObjectTemplate = objTemplate
    }

    return insertCache[self.InsertKey]
end

function baseBuilder:GetDynamicInsertQuery(items)
    local insertData = insertCache[self.InsertKey] or self:GenerateInsertQuery(items)

    local insert = table.concat(insertData.ObjectTemplate, ", ")
    local data = insertData.IsListType
        and self:GetValuesString(items, insertData.ObjectTemplate)
        or self:GetValueString(items, insertData.ObjectTemplate)

    return insertTemplate:format(self.Table, insert, data)
end

function baseBuilder:BuildInsert()
    return self:GetDynamicInsertQuery(self.InsertItems)
end

function baseBuilder:InsertQuery()
    local query = self:BuildQuery()

    local result, insertId = connector:QueryInsert(query)
    if not result then return end

    local cache = insertCache[self.InsertKey]
    local pkey = self.Context.Constraints.PrimaryKey

    if cache.IsListType then
        for id, obj in ipairs(self.InsertItems) do
            obj[pkey] = insertId + id - 1
        end
    else
        self.InsertItems[pkey] = insertId
    end

    return result, self.InsertItems
end

function baseBuilder:Insert(items, key)
    self.InsertItems = items
    self.BuildQuery = self.BuildInsert
    self.InsertKey = self:GetKey(key)
    self.Query = self.InsertQuery

    return self
end

local updateTemplate = [[
DROP TABLE IF EXISTS InsertTemplate;

CREATE TEMPORARY TABLE InsertTemplate
(
    %s
) ENGINE = MEMORY;

INSERT INTO InsertTemplate (%s)
VALUES (%s);

UPDATE %s
INNER JOIN InsertTemplate
    ON InsertTemplate.%s = %s.%s
SET
    %s;

DROP TABLE InsertTemplate;
]]

local function GetTempTableDef(columns)
    local ret = {}

    for _, column in pairs(columns) do
        table.insert(ret, ("%s %s"):format(column.ColumnName, column.Type))
    end

    return table.concat(ret, ",\n    ")
end

local setTemplate = "%s.%s = InsertTemplate.%s"

local function GetSetConditions(template, tableName, pKey)
    local ret = {}

    for _, column in ipairs(template) do
        if column == pKey then continue end
        table.insert(ret, setTemplate:format(tableName, column, column))
    end

    return table.concat(ret, ",\n    ")
end

function baseBuilder:GenerateUpdateQuery(items, key)
    local context = self.Context
    local tempTable = GetTempTableDef(context.Columns)
    local isListType, objTemplate = self:GetListTypeAndTemplate(items, true)
    local setConditions = GetSetConditions(objTemplate, self.Table, context.Constraints.PrimaryKey)

    local queryTemplate = updateTemplate:format(
        tempTable,
        table.concat(objTemplate, ", "),
        "%s",
        self.Table,
        context.Constraints.PrimaryKey,
        self.Table,
        context.Constraints.PrimaryKey,
        setConditions
    )

    updateCache[self.UpdateKey] = {
        QueryTemplate = queryTemplate,
        ObjectTemplate = objTemplate,
        IsListType = isListType
    }

    return updateCache[self.UpdateKey]
end

function baseBuilder:BuildUpdate()
    local updateData = updateCache[self.UpdateKey] or self:GenerateUpdateQuery(self.UpdateItems, self.UpdateKey)

    local values = updateData.IsListType
        and self:GetValuesString(self.UpdateItems, updateData.ObjectTemplate)
        or self:GetValueString(self.UpdateItems, updateData.ObjectTemplate)

    return updateData.QueryTemplate:format(values)
end

function baseBuilder:Update(items, key)
    self.UpdateItems = items
    self.UpdateKey = self:GetKey(key)
    self.BuildQuery = self.BuildUpdate

    return self
end

function baseBuilder:Where(arg)
    table.insert(self.WhereArgs, tostring(arg))
    return self
end

function baseBuilder:AddJoin(tbl, info)
    table.insert(self.JoinArgs, info.Join)
end

function baseBuilder:BuildQuery()
    error("BuildQuery not implemented")
end

function baseBuilder:Query()
    local query = self:BuildQuery()
    return connector:Query(query)
end

local columnMeta = {}
columnMeta.__index = columnMeta

function columnMeta:__tostring()
    return self.Name
end

function columnMeta:Comparitor(val, comparitor)
    return table.concat({ self.Name, comparitor, isstring(val) and ("'%s'"):format(val) or val }, " ")
end

function columnMeta:Equals(val)
    return self:Comparitor(val, "=")
end

function columnMeta:GreaterThan(val)
    return self:Comparitor(val, ">")
end

function columnMeta:GreaterThanOrEqual(val)
    return self:Comparitor(val, ">=")
end

function columnMeta:LessThan(val)
    return self:Comparitor(val, "<")
end

function columnMeta:LessThanOrEqual(val)
    return self:Comparitor(val, "<=")
end

local function CreateColumnContext(columnName)
    local column = { Name = columnName }
    setmetatable(column, columnMeta)

    return column
end

function queryBuilder:RegisterType(name, info)
    local newBuilder = { Table = name, Context = info }
    setmetatable(newBuilder, baseBuilder)

    -- Create column methods
    for column in pairs(info.Columns) do
        newBuilder[column] = function()
            return CreateColumnContext(column)
        end
    end

    -- Cache, so we can use it for JOIN's later
    self.Builders[name] = table.Copy(newBuilder)
    newBuilder.__index = newBuilder

    -- Create JOIN options
    for fkeyName, fkeyInfo in pairs(info.Constraints.ForeignKeys) do
        newBuilder[fkeyName] = function(inst)
            local joinTbl = self.Builders[fkeyName]
            inst:AddJoin(joinTbl.Table, fkeyInfo)

            return joinTbl
        end
    end

    -- Register method to invoke table from dbContext
    dbContext[name] = function()
        local instance = {
            SelectArgs = {},
            WhereArgs = {},
            JoinArgs = {},
            UpdateCache = {}
        }
        setmetatable(instance, newBuilder)

        return instance
    end
end
SHLIB.DbContext = SHLIB.DbContext or {}
SHLIB.ORM = SHLIB.ORM or {}
SHLIB.ORM.TableDefinitions = SHLIB.ORM.TableDefinitions or {}

local orm = SHLIB.ORM

local types = {
    INT = "INT",
    VARCHAR = function(alloc) return ("VARCHAR(%d)"):format(alloc) end,
    CHAR = function(alloc) return ("CHAR(%d)"):format(alloc) end,
    FLOAT = "FLOAT",
    BIT = "BIT",
    DATETIME = "DATETIME"
}

local tableDefinition = {}
tableDefinition.__index = tableDefinition

function tableDefinition:New(name)
    local instance = { Name = name, Constraints = { ForeignKeys = {}, Unique = {} } }
    setmetatable(instance, tableDefinition)
    orm.TableDefinitions[name] = instance

    return instance
end

function tableDefinition:AddColumn(name)
    self.Columns = self.Columns or {}
    self.Columns[name] = {
        ColumnName = name,
        Constraints = {},
        Order = table.Count(self.Columns) + 1
    }

    self.TargetColumn = self.Columns[name]
    return self
end

function tableDefinition:PrimaryKey()
    self.Constraints.PrimaryKey = self.TargetColumn.ColumnName
    return self
end

local join = [[
INNER JOIN %s
    ON %s.%s = %s.%s
]]

function tableDefinition:ForeignKey(tbl, column, deleteCascade)
    self.Constraints.ForeignKeys[tbl] = {
        LocalColumn = self.TargetColumn.ColumnName,
        ForeignColumn = column,
        DeleteOnCascade = deleteCascade,
        Join = join:format(tbl, tbl, column, self.Name, self.TargetColumn.ColumnName)
    }

    return self
end

function tableDefinition:Unique(...)
    local unique = table.Pack(...)
    table.insert(self.Constraints.Unique, unique)

    return self
end

function tableDefinition:NotNull()
    self.TargetColumn.Constraints.NotNull = true
    return self
end

function tableDefinition:AutoIncrement()
    self.TargetColumn.Constraints.AutoIncrement = true
    return self
end

for columnType, impl in pairs(types) do
    tableDefinition[columnType] = function(tblDef, ...)
        local column = isfunction(impl) and impl(...) or impl
        tblDef.TargetColumn.Type = column
        tblDef.TargetColumn.IsString = (column:find("CHAR") ~= nil)

        return tblDef
    end
end

local function GetColumnStr(col)
    return ("%s %s%s%s"):format(col.ColumnName, col.Type,
        col.Constraints.NotNull and " NOT NULL" or "",
        col.Constraints.AutoIncrement and " AUTO_INCREMENT" or "")
end

local function GetDefHeader(name)
    return ("CREATE TABLE IF NOT EXISTS %s (\n\t"):format(name)
end

local function GetColumns(def)
    local cols = {}

    for name, column in SortedPairsByMemberValue(def, "Order") do
        table.insert(cols, GetColumnStr(column))
    end

    table.insert(cols, "\n\t")
    return table.concat(cols, ",\n\t")
end

local function GetConstraints(def)
    local constraints = def.Constraints
    local ret = {}

    table.insert(ret, ("PRIMARY KEY (%s)"):format(constraints.PrimaryKey))

    for tbl, fkey in pairs(constraints.ForeignKeys) do
        local constr = ("FOREIGN KEY (%s) REFERENCES %s(%s)"):format(fkey.LocalColumn, tbl, fkey.ForeignColumn)
            .. (fkey.DeleteOnCascade and " ON DELETE CASCADE" or "")

        table.insert(ret, constr)
    end

    for _, uniq in ipairs(constraints.Unique) do
        table.insert(ret, ("UNIQUE(%s)"):format(table.concat(uniq, ", ")))
    end

    return table.concat(ret, ",\n\t")
end

function orm:AddTable(name, info)
    return tableDefinition:New(name)
end

local function HasUnRegisteredDependencies(dependencies, register)
    for dep in pairs(dependencies) do
        if not register[dep] then return true end
    end
end

local function RegisterTable(tbl, register)
    SHLIB:CreateDatabaseTable(tbl.Name, tbl.Definition)
    SHLIB.QueryBuilder:RegisterType(tbl.Name, tbl.Config)

    register[tbl.Name] = true
end

function orm:ParseDatabaseTables()
    local tbls = {}
    local register = {}

    for name, info in pairs(self.TableDefinitions) do
        table.insert(tbls, {
            Name = name,
            Dependencies = info.Constraints.ForeignKeys,
            Definition = table.concat({ GetDefHeader(name), GetColumns(info.Columns), GetConstraints(info), "\n)" }),
            Config = info
        })
    end

    while true do
        for _, tbl in ipairs(tbls) do
            if register[tbl.Name] then continue end

            if table.IsEmpty(tbl.Dependencies) then
                RegisterTable(tbl, register)
                continue
            end

            if HasUnRegisteredDependencies(tbl.Dependencies, register) then continue end
            RegisterTable(tbl, register)
        end

        if table.Count(register) == #tbls then break end
    end
end
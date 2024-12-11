SHLIB.Net.Trans = SHLIB.Net.Trans or {}
SHLIB.Net.Types = SHLIB.Net.Types or {}

local trans = SHLIB.Net.Trans
local types = SHLIB.Net.Types

-- Access Flags

trans.Access = {
    All = function() return true end,
    Admin = function(ply) return ply:IsAdmin() end,
    SuperAdmin = function(ply) return ply:IsSuperAdmin() end
}

-- Status Codes

trans.Status = {
    Success = 200,
    Unauthorized = 401,
    ServerError = 500
}

-- Util

local function ReadUserInput()
    return SHLIB.SQL.Connector:Escape(net.ReadString())
end

local function ReadUInt(bits)
    return function() return net.ReadUInt(bits) end
end

local function WriteUInt(bits)
    return function(int) net.WriteUInt(int, bits) end
end

-- Type registering

local typeLookup = {
    ID = { Read = ReadUInt(32), Write = WriteUInt(32) },
    UInt32 = { Read = ReadUInt(32), Write = WriteUInt(32) },
    UInt16 = { Read = ReadUInt(16), Write = WriteUInt(16) },
    UInt8 = { Read = ReadUInt(8), Write = WriteUInt(8) },
    UInt4 = { Read = ReadUInt(4), Write = WriteUInt(4) },

    Angle = { Read = net.ReadAngle, Write = net.WriteAngle },
    Bit = { Read = net.ReadBit, Write = net.WriteBit },
    Color = { Read = net.ReadColor, Write = net.WriteColor },
    Float = { Read = net.ReadFloat, Write = net.WriteFloat },
    Entity = { Read = net.ReadEntity, Write = net.WriteEntity },
    String = { Read = SERVER and ReadUserInput or net.ReadString, Write = net.WriteString },
    Vector = { Read = net.ReadVector, Write = net.WriteVector }
}

local function ReadList(readFunc)
    local size = net.ReadUInt(32)
    local ret = {}

    for i = 1, size do
        ret[i] = readFunc()
    end

    return ret
end

-- The provided table MUST use sequential keys
local function WriteList(tbl, writeFunc)
    net.WriteUInt(#tbl, 32)

    for _, obj in ipairs(tbl) do
        writeFunc(obj)
    end
end

local function GetType(typeof)
    return typeLookup[typeof] or types[typeof]
end

local function GetKeys(schema)
    local keys = {}

    for key in pairs(schema) do
        table.insert(keys, key)
    end

    table.sort(keys)
    return keys
end

local function ReadSchema(keys, schema)
    local obj = {}
    for _, key in ipairs(keys) do
        obj[key] = GetType(schema[key]).Read()
    end

    return obj
end

local function WriteSchema(keys, schema, obj)
    for _, key in ipairs(keys) do
        GetType(schema[key]).Write(obj[key])
    end
end

local function CreateType(name, read, write)
    local readList = function() return ReadList(read) end
    local writeList = function(tbl) WriteList(tbl, write) end

    types[name] = { Read = read, Write = write }
    types[name .. "List"] = { Read = readList, Write = writeList }
end

function trans:RegisterType(name, schema)
    local keys = GetKeys(schema)

    local read = function() return ReadSchema(keys, schema) end
    local write = function(obj) WriteSchema(keys, schema, obj) end

    CreateType(name, read, write)
end

function trans:RegisterPrimitiveType(name)
    local read = typeLookup[name].Read
    local write = typeLookup[name].Write

    CreateType(name, read, write)
end

-- Request Headers

function trans:WriteClientHeader(name, clID)
    net.WriteString(name)
    net.WriteString(clID)
end

function trans:ReadClientHeader()
    return { Name = ReadUserInput(), ClID = ReadUserInput() }
end

function trans:WriteResponseHeader(clID, status)
    net.WriteString(clID)
    trans:WriteStatus(status)
end

function trans:ReadResponseHeader()
    return { Id = net.ReadString(), Status = trans:ReadStatus() }
end

-- Request Status

function trans:WriteStatus(status)
    net.WriteUInt(status, 10)
end

function trans:ReadStatus()
    return net.ReadUInt(10)
end

-- Basic Types

for typeof, _ in pairs(typeLookup) do
    trans:RegisterPrimitiveType(typeof)
end
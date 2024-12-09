SHLIB.Detours = SHLIB.Detours or {}
SHLIB.Detours.Cache = SHLIB.Detours.Cache or {}

local cache = SHLIB.Detours.Cache

local function GetOriginalFunc(name, parentTbl)
    if cache[name] then return cache[name] end
    cache[name] = parentTbl[name]

    return cache[name]
end

function SHLIB.Detours:Add(name, parentTbl, func)
    local originalFunc = GetOriginalFunc(name, parentTbl)

    parentTbl[name] = function(...)
        return originalFunc(func(...))
    end
end
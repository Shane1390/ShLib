SHLIB.SpawnedEntities = SHLIB.SpawnedEntities or {}

function SHLIB:CreateEntity(class)
    local ent = ents.Create(class)
    table.insert(SHLIB.SpawnedEntities, ent)
    
    return ent
end

function SHLIB:CleanupEntities()
    for _, ent in ipairs(self.SpawnedEntities) do
        if IsValid(ent) then ent:Remove() end
    end

    self.SpawnedEntities = {}
end
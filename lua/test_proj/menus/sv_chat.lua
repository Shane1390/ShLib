local phrase = "!players"

local function PlayerSay(ply, text)
    if text ~= phrase then return end
    
    SHLIB.Actions:OpenPlayerMenu(ply)
    return ""
end

hook.Add("PlayerSay", "SHLIB::PlayerSay", PlayerSay)
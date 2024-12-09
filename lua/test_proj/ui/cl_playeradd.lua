local PANEL = {}

function PANEL:OnEnter(txt)
    if txt == "" then return end

    print(txt)
    local result, plyID = SHLIB.Client:AddPlayer(txt)
    if result then
        local pnl = SHLIB:GetSingletonPanel("SHLIB_ScrollPanel")
        pnl:AddPlayer({
            PlayerID = plyID,
            Name = txt
        })
    end
end

SHLIB:RegisterPanel("SHLIB_PlayerAdd", PANEL, "DTextEntry")
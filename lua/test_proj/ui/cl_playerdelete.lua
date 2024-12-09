local PANEL = {}

function PANEL:Init()
    self:SetText("x")
    self:SetWide(25)
end

function PANEL:DoClick()
    local pnl = self:GetParent()

    local result = SHLIB.Client:RemovePlayer(pnl.ID)
    if result then pnl:Remove() end
end

SHLIB:RegisterPanel("SHLIB_PlayerDelete", PANEL, "DButton")
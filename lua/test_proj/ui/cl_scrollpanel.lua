local PANEL = {}

function PANEL:Init()
    local result, players = SHLIB.Client:GetPlayers()

    for _, ply in ipairs(players) do
        self:AddPlayer(ply)
    end

    SHLIB:RegisterSingletonPanel(self)
end

function PANEL:AddPlayer(ply)
    local pnl = vgui.Create("SHLIB_PlayerPanel", self)
    pnl:Dock(TOP)
    pnl:SetData(ply)
end

SHLIB:RegisterPanel("SHLIB_ScrollPanel", PANEL, "DScrollPanel")
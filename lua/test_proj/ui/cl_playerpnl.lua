local PANEL = {}

function PANEL:Init()
    self:DockPadding(5, 0, 0, 0)

    self.Label = vgui.Create("DLabel", self)
    self.Label:Dock(LEFT)
    self.Label:SetTextColor(Color(0, 0, 0))

    local delete = vgui.Create("SHLIB_PlayerDelete", self)
    delete:Dock(RIGHT)
end

function PANEL:SetData(data)
    self.ID = data.PlayerID
    self.Label:SetText(data.Name)
end

SHLIB:RegisterPanel("SHLIB_PlayerPanel", PANEL, "DPanel")
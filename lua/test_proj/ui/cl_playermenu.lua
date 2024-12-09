local PANEL = {}

function PANEL:Init()
    self:SetTitle("Player Menu")

    local text = vgui.Create("SHLIB_PlayerAdd", self)
    text:Dock(TOP)

    local scroll = vgui.Create("SHLIB_ScrollPanel", self)
    scroll:Dock(FILL)
end

SHLIB:RegisterPanel("SHLIB_PlayerMenu", PANEL, "DFrame")

function OpenPlayerMenu()
    if IsValid(PLAYER_MENU) then PLAYER_MENU:Remove() end

    PLAYER_MENU = vgui.Create("SHLIB_PlayerMenu")
    PLAYER_MENU:SetSize(300, 200)
    PLAYER_MENU:MakePopup()
    PLAYER_MENU:Center()
end
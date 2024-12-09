SHLIB.Panels = SHLIB.Panels or {}

-- List of methods to make async
local asyncMethods = {
    "Init",
    "DoClick",
    "OnRemove",
    "OnChange",
    "OnEnter"
}

local function SetPanelLoading(pnl, isLoading)
    if not pnl.SetDisabled then return end
    pnl:SetDisabled(isLoading)
end

local function OverrideMethod(tbl, method)
    local func = tbl[method]
    if not func then return end

    tbl[method] = function(pnl, ...)
        SHLIB:Async(function(pnl, ...)
            SetPanelLoading(pnl, true)

            func(pnl, ...)

            SetPanelLoading(pnl, false)
        end)(pnl, ...)
    end
end

function SHLIB:RegisterPanel(class, tbl, base)
    for _, method in ipairs(asyncMethods) do
        OverrideMethod(tbl, method)
    end

    vgui.Register(class, tbl, base)
end

function SHLIB:CursorInPanel(pnl)
    local relativeX, relativeY = pnl:ScreenToLocal(gui.MouseX(), gui.MouseY())
    local w, h = pnl:GetSize()

    return relativeX > 0 and relativeX < w and relativeY > 0 and relativeY < h
end

function SHLIB:RegisterSingletonPanel(pnl)
    local name = pnl:GetName()

    if IsValid(self.Panels[name]) then
        self.Panels[name]:Remove()
    end

    self.Panels[name] = pnl
end

function SHLIB:GetSingletonPanel(name)
    return self.Panels[name]
end
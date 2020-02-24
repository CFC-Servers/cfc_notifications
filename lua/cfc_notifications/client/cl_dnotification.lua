local PANEL = {}

local function solidColorPaint( self, w, h )
    surface.SetDrawColor( self:GetBackgroundColor() )
    surface.DrawRect( 0, 0, w, h )
end

local function secondsAsTime( s )
    return string.FormattedTime( s, "%02i:%02i" )
end

function PANEL:Init()
    self:SetDisplayTime( nil )
    self:SetBackgroundColor( Color( 100, 100, 100, 100 ) )
end

function PANEL:SetDisplayTime( t )
    if t then
        self._showTimer = true
        self._maxTime = t
        self._curTime = 0
    else
        self._showTimer = false
    end
end

CFCNotifications.contextHelpers.addField( PANEL, "title", "Notification", "string" )
CFCNotifications.contextHelpers.addField( PANEL, "ignoreable", true, "boolean" )
CFCNotifications.contextHelpers.addField( PANEL, "closeable", true, "boolean" )

function PANEL:GetCanvas()
    return self._canvas
end

function PANEL:Paint( w, h )
    solidColorPaint( self, w, h )
    local ct = SysTime()
    local pt = self._prevPaintTime or 0
    local dt = ct - pt
    self._prevPaintTime = ct
    if dt > 0.5 then
        -- Too much time passed between paint, probably wasn't visible
        dt = 0
    end

    -- Incrementing time here so the timer doesn't decrement when the notification isnt visible (aka, when there's a lot of notifications at once)
    self._curTime = self._curTime + dt

    if self._curTime > self._maxTime then
        self._curTime = self._maxTime
        if not self._timeoutCalled then
            self._timeoutCalled = true
            if self.OnTimeout then
                self:OnTimeout()
            end
        end
    end

    if self._showTimer then
        local frac = self._curTime / self._maxTime
        surface.SetDrawColor( Color( 180, 180, 180, 150 ) )
        surface.DrawRect( 0, 0, w, 5 )
        surface.SetDrawColor( Color( 240, 40, 40 ) )
        surface.DrawRect( 0, 0, w * frac, 5 )

        local remaining = math.Clamp( self._maxTime - self._curTime, 0, 100000 )
        local remainingStr = secondsAsTime( remaining )
        draw.DrawText( remainingStr, "DebugFixed", w - 60, h - 30, Color( 180, 180, 180 ) )
    end
end

local function makeTitleBarButton( self, text, cbName, ... )
    local btn = vgui.Create( "DButton", self )
    btn:SetText( text )
    btn:SetTextColor( Color( 200, 200, 200 ) )
    btn.Paint = nil
    function btn:DoClick()
        if btn[cbName] then
            btn[cbName]( self, ... )
        end
    end
    function btn:Think()
        local x, y = self:LocalCursorPos()
        local w, h = self:GetSize()
        local isHovered = x >= 0 and x <= w and y >= 0 and y <= h -- Not using panel:IsHovered as that often gets it wrong due to using vgui.GetHoveredPanel()
        if isHovered ~= self.wasHovered then
            if isHovered then
                self:SetTextColor( Color( 255, 255, 255 ) )
            else
                self:SetTextColor( Color( 200, 200, 200 ) )
            end
        end
        self.wasHovered = isHovered
    end
    btn:SizeToContents()
    btn:InvalidateLayout( true )
    return btn
end

local function makeTitleBar( self )
    local bar = vgui.Create( "DPanel", self )
    bar:SetSize( self:GetWide(), 30 )
    bar:Dock( TOP )
    bar:SetBackgroundColor( Color( 220, 220, 220, 150 ) )
    bar.Paint = solidColourPaint

    local title = vgui.Create( "DLabel", bar )
    title:SetText( self:GetTitle() )
    title:SetTextColor( Color( 255, 255, 255 ) )
    title:SizeToChildren()

    local btnTexts = {}
    if self:GetCloseable() then
        table.insert( btnTexts, "discard", "OnClose")
    end
    if self:GetIgnoreable() then
        table.insert( btnTexts, "mute", "OnIgnore", true )
        table.insert( btnTexts, "temporary mute", "OnIgnore" )
    end

    local offset = 10
    local barWidth = self:GetWide()
    for k = 1, #btnTexts do
        local text = btnTexts[k]
        local btn = makeTitleBarButton( bar, text )
        local w, h = btn:GetSize()
        offset = offset + w
        btn:SetPos( barWidth - offset, 0 )
        local splitBar = vgui.Create( "DLabel", bar )
        splitBar:SetText( "|" )
        splitBar:SetTextColor( Color( 200, 200, 200 ) )
        splitBar:SizeToChildren()
        splitBar:SetPos( barWidth - (offset + 8), 0 )
        offset = offset + 20
    end

    return bar
end

function PANEL:Populate()
    self._titleBar = makeTitleBar( self )

    self._canvas = vgui.Create( "DPanel", self )
    self._canvas:Dock( FILL )
    self._canvas:DockMargin( 5, 5, 5, 5 )
end

vgui.Register( "DNotification", PANEL, "DPanel" )
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
    self:SetBackgroundColor( Color( 50, 50, 50, 220 ) )
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
CFCNotifications.contextHelpers.addField( PANEL, "buttonsDisabled", false, "boolean" )
CFCNotifications.contextHelpers.addField( PANEL, "alwaysTiming", false, "boolean" )
CFCNotifications.contextHelpers.addField( PANEL, "titleBarColor", Color( 140, 140, 140, 150 ), "Color" )

function PANEL:GetCanvas()
    return self._canvas
end

function PANEL:Think()
    local currentTime = SysTime()
    local previousTime = self._prevThinkTime or 0
    local deltaTime = currentTime - previousTime
    self._prevThinkTime = currentTime
    if deltaTime > 0.5 then
        -- Too much time passed between paint, probably wasn't visible
        deltaTime = 0
    end
    self._thinkDeltaTime = deltaTime

    -- Incrementing time here so the timer doesn't decrement when the notification isnt visible ( aka, when there's a lot of notifications at once )
    if not self._showTimer then return end
    if self:GetAlwaysTiming() or self:IsVisible() then
        self._curTime = self._curTime + deltaTime
    end

    if self._curTime > self._maxTime then
        self._curTime = self._maxTime
        if not self._timeoutCalled then
            self._timeoutCalled = true
            if self.OnTimeout then
                self:OnTimeout()
            end
        end
    end

    local remaining = math.ceil( math.Clamp( self._maxTime - self._curTime, 0, 100000 ) )
    local previousRemaining = self._prevRemaining or 0
    self._prevRemaining = remaining

    if remaining ~= previousRemaining then
        self._remainingStr = secondsAsTime( remaining )
    end

    self._timerFraction = self._curTime / self._maxTime
end

function PANEL:Paint( w, h )
    solidColorPaint( self, w, h )
    if not self._showTimer then return end

    local frac = self._timerFraction
    local barHeight = 4
    surface.SetDrawColor( Color( 180, 180, 180, 150 ) )
    surface.DrawRect( 0, h - barHeight, w, barHeight )
    surface.SetDrawColor( Color( 240, 40, 40 ) )
    surface.DrawRect( 0, h - barHeight, w * frac, barHeight )

    draw.DrawText( self._remainingStr, "CFC_Notifications_Mono", w - 44, h - 16, Color( 180, 180, 180 ) )
end

function PANEL:_makeTitleBarButton( bar, text, cbName, ... )
    local btn = vgui.Create( "DButton", bar )
    btn:SetText( text )
    btn:SetFont( "CFC_Notifications_Normal" )
    btn:SetTextColor( Color( 210, 210, 210 ) )
    btn.Paint = nil

    local this = self
    local data = { ... }
    function btn:DoClick()
        if not this:GetButtonsDisabled() and this[cbName] then
            this[cbName]( this, unpack( data ) )
        end
    end
    function btn:Think()
        local x, y = self:LocalCursorPos()
        local w, h = self:GetSize()

        -- Using this over panel:IsHovered(), as IsHovered simply checks the result of vgui.GetHoveredPanel()
        -- GetHoveredPanel only returns the inner most hovered element, so IsHovered returns false if an element within it is hovered.
        -- Solution: Base hover purely on size and mouse position
        local isHovered = x >= 0 and x <= w and y >= 0 and y <= h
        if isHovered ~= self.wasHovered then
            if isHovered then
                self:SetTextColor( Color( 255, 255, 255 ) )
            else
                self:SetTextColor( Color( 210, 210, 210 ) )
            end
        end
        self.wasHovered = isHovered
    end
    btn:SizeToContents()
    btn:InvalidateLayout( true )
    return btn
end

function PANEL:_makeTitleBar()
    local bar = vgui.Create( "DPanel", self )
    bar:SetSize( self:GetWide(), 20 )
    bar:Dock( TOP )
    bar:SetBackgroundColor( self:GetTitleBarColor() )
    bar.Paint = solidColorPaint

    local title = vgui.Create( "DLabel", bar )
    title:SetText( self:GetTitle() )
    title:SetFont( "CFC_Notifications_Title" )
    title:SetTextColor( Color( 255, 255, 255 ) )
    title:SizeToContents()
    title:Dock( LEFT )
    title:DockMargin( 5, 0, 0, 0 )

    local btnTexts = {}
    if self:GetCloseable() then
        table.insert( btnTexts, { "discard", "OnClose" } )
        if self:GetIgnoreable() then
            table.insert( btnTexts, { "mute", "OnIgnore", true } )
            table.insert( btnTexts, { "temporary mute", "OnIgnore" } )
        end
    end

    local offset = 2
    local barWidth = self:GetWide()
    local splitBarWidth = 5
    local splitBarOffset = 4
    for k = 1, #btnTexts do
        local textData = btnTexts[k]
        local text = table.remove( textData, 1 )
        local cbName = table.remove( textData, 1 )
        local btn = self:_makeTitleBarButton( bar, text, cbName, unpack( textData ) )
        local w, h = btn:GetSize()
        offset = offset + w
        btn:SetPos( barWidth - offset, ( 20 - h ) / 2 )

        if k ~= #btnTexts then
            local splitBar = vgui.Create( "DLabel", bar )
            splitBar:SetText( "|" )
            splitBar:SetTextColor( Color( 200, 200, 200 ) )
            splitBar:SizeToChildren()
            splitBar:SetPos( barWidth - ( offset + splitBarOffset ), 0 )
            offset = offset + splitBarWidth
        end
    end

    return bar
end

function PANEL:Populate()
    self._titleBar = self:_makeTitleBar()

    self._canvas = vgui.Create( "DPanel", self )
    self._canvas.Paint = nil
    self._canvas:Dock( FILL )
    self._canvas:DockMargin( 5, 5, 5, 5 )
end

vgui.Register( "DNotification", PANEL, "DPanel" )

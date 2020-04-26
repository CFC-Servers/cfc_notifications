CFCNotifications._popups = {}
CFCNotifications._popupIDCounter = 0
CFCNotifications._animationSpeed = 5000
local notifSpacing = 5

local priorityColors = {
    [CFCNotifications.PRIORITY_HIGH] = Color( 255, 140, 0, 150 ),
    [CFCNotifications.PRIORITY_MAX] = Color( 255, 20, 20, 150 ),
}

include( "cl_customalphato.lua" )

surface.CreateFont( "CFC_Notifications_Title", {
    font = "Roboto",
    size = 17,
    weight = 500
} )

surface.CreateFont( "CFC_Notifications_Big", {
    font = "Roboto",
    size = 19,
    weight = 500
} )

surface.CreateFont( "CFC_Notifications_Normal", {
    font = "Roboto",
    size = 14,
    weight = 500
} )

surface.CreateFont( "CFC_Notifications_Mono", {
    font = "Lucida Console",
    size = 12,
    weight = 500
} )

local clickerEnabled = false
local lastClick = 0

local bindTranslation = {}
bindTranslation["slot1"] = 1
bindTranslation["slot2"] = 2
bindTranslation["slot3"] = 3
bindTranslation["slot4"] = 4
bindTranslation["slot5"] = 5
bindTranslation["slot6"] = 6
bindTranslation["slot7"] = 7
bindTranslation["slot8"] = 8
bindTranslation["slot9"] = 9
bindTranslation["slot0"] = 0

hook.Add( "PlayerButtonDown", "CFCNotifications_render_keydown", function( ply, key )
    if ply ~= LocalPlayer() then return end
    -- PlayerButtonDown is called multiple times because gmod is bad
    local ct = SysTime()
    if ct - lastClick < 0.2 then return end
    lastClick = ct

    local x, _ = input.GetCursorPos()
    local wide = CFCNotifications.getSetting( "size_x" )

    local shouldToggle = key == KEY_F3 or ( clickerEnabled and key == MOUSE_LEFT and x < ( ScrW() - wide ) )
    shouldToggle = shouldtoggle and not DarkRP

    if shouldToggle then
        clickerEnabled = not clickerEnabled
        local adjustCursor = CFCNotifications.getSetting( "adjust_cursor" )
        if adjustCursor and clickerEnabled then
            gui.SetMousePos( ScrW() - wide - 50, ScrH() / 2 )
        end
        gui.EnableScreenClicker( clickerEnabled )
    end

    if input.IsButtonDown( KEY_LALT ) and key == KEY_R then
        if #CFCNotifications._popups == 0 then return end
        local popup = CFCNotifications._popups[1]
        popup.panel:OnClose()
    end
end )

hook.Add( "PlayerBindPress", "CFCNotifcations_render_numdown", function( _, bind )
    local v = bindTranslation[bind]
    if not v then return end
    if #CFCNotifications._popups == 0 then return end
    local notif = CFCNotifications._popups[1].notification
    if notif.OnAltNum then
        return notif:OnAltNum( v )
    end
end )

local function solidColorPaint( col )
    return function( self, w, h )
        surface.SetDrawColor( col )
        surface.DrawRect( 0, 0, w, h )
    end
end

hook.Add( "CFC_Notifications_init", "render_init", function()
    local wide = CFCNotifications.getSetting( "size_x" )
    local h = CFCNotifications.getSetting( "start_y_fraction" ) * ScrH()

    local container = vgui.Create( "DPanel" )
    container.Paint = nil
    container:SetSize( wide, h )
    container:SetPos( ScrW() - wide, 0 )

    local freeCursorLabel = vgui.Create( "DLabel" )
    freeCursorLabel:SetPos( ScrW() - wide, h )
    freeCursorLabel:SetText( "Press f3/open chat to free your mouse!" )
    freeCursorLabel:SetTextColor( Color( 40, 200, 200 ) )
    freeCursorLabel.Paint = solidColorPaint( Color( 100, 100, 100, 100 ) )
    freeCursorLabel:SetFont( "CFC_Notifications_Title" )
    freeCursorLabel:SetSize( wide, 20 )
    freeCursorLabel:SetContentAlignment( 5 )
    freeCursorLabel:SetAlpha( 0 )

    local othersLabel = vgui.Create( "DLabel" )
    othersLabel:SetTextColor( Color( 255, 255, 255 ) )
    othersLabel:SetFont( "CFC_Notifications_Title" )
    othersLabel:SetSize( wide, 20 )
    othersLabel:SetContentAlignment( 5 )
    othersLabel:SetAlpha( 0 )

    function othersLabel:Think()
        local maxNotif = CFCNotifications.getSetting( "max_notifications" )
        if #CFCNotifications._popups > maxNotif then
            local count = -1
            for k = #CFCNotifications._popups, 1, -1 do
                count = count + 1
                local panel = CFCNotifications._popups[k].panel
                if panel:IsVisible() then
                    if count > 0 then
                        self:SetText( "+ " .. count .. " other" .. ( count == 1 and "" or "s" ) )
                        local _, y = panel:GetPos()
                        self:SetPos( ScrW() - wide, y - 25 )
                    end
                    break
                end
            end
            if not self._prevShow then
                self._prevShow = true
                self:CustomAlphaTo( 255, 0.3 )
            end
        else
            if self._prevShow then
                self._prevShow = false
                self:CustomAlphaTo( 0, 0.3 )
            end
        end
    end

    CFCNotifications.container = container
    CFCNotifications.freeCursorLabel = freeCursorLabel
    CFCNotifications.othersLabel = othersLabel
end )

hook.Add( "CFC_Notifications_stop", "render_stop", function()
    if CFCNotifications.container then
        CFCNotifications.container:Remove()
        CFCNotifications.container = nil
        CFCNotifications.freeCursorLabel:Remove()
        CFCNotifications.freeCursorLabel = nil
        CFCNotifications.othersLabel:Remove()
        CFCNotifications.othersLabel = nil
    end
end )

local function addData( data )
    local p = data.notification:GetPriority()
    for k, v in ipairs( CFCNotifications._popups ) do
        if v.notification:GetPriority() <= p then
            return table.insert( CFCNotifications._popups, k, data )
        end
    end
    return table.insert( CFCNotifications._popups, data )
end

local function addNotifHooks( panel, popupID )
    -- panel:SetPos rounds values, so that getpos doesn't return the exact previous setpos
    -- This messes up animations, these fix that
    local oldSetPos = panel.SetPos
    local oldGetPos = panel.GetPos
    function panel:SetPos( x, y )
        self._x = x
        self._y = y
        oldSetPos( self, x, y )
    end
    function panel:GetPos()
        if not self._x then
            return oldGetPos( self )
        end
        return self._x, self._y
    end
    panel._targetAlpha = 255
    local oldThink = panel.Think
    function panel:Think()
        oldThink( self )
        if not self:IsVisible() then return end

        local speed = CFCNotifications._animationSpeed

        local speedDeltaTimeX = speed * self._thinkDeltaTime
        local speedDeltaTimeY = speedDeltaTimeX * 0.7 -- Make y movement a little slower

        local x, y = self:GetPos()
        local targetX, targetY = self._targetX, self._targetY
        if not targetX then return end

        local changed = false
        if targetX ~= x then
            changed = true
            local change = math.Clamp( targetX - x, -speedDeltaTimeX, speedDeltaTimeX )
            x = x + change
        end
        if targetY ~= y then
            changed = true
            local change = math.Clamp( targetY - y, -speedDeltaTimeY, speedDeltaTimeY )
            y = y + change
        end
        if changed then
            self:SetPos( x, y )
            if self._shouldRemove and x >= self:GetParent():GetWide() then
                local pHeight = self:GetTall()
                local pWidth = self:GetWide()

                local idx = table.KeyFromValue( CFCNotifications._popups, self.data )
                for k = idx + 1, #CFCNotifications._popups do -- move all above down
                    local cPanel = CFCNotifications._popups[k].panel
                    if cPanel:IsVisible() then
                        cPanel._targetY = cPanel._targetY + ( pHeight + notifSpacing )
                    end
                end

                -- Fade and slide the next hidden notif in
                local maxNotif = CFCNotifications.getSetting( "max_notifications" )
                local topPanelData = CFCNotifications._popups[maxNotif + 1]
                if topPanelData then
                    local topPanel = topPanelData.panel
                    local notifX = CFCNotifications.container:GetWide() - pWidth
                    local notifY = CFCNotifications.container:GetTall() - ( pHeight + ( maxNotif - 1 ) * ( pHeight + notifSpacing ) )
                    topPanel:SetPos( notifX, notifY - ( pHeight + notifSpacing ) )
                    topPanel._targetX = notifX
                    topPanel._targetY = notifY
                    topPanel:Show()
                    topPanel._hidden = false
                    topPanel:CustomAlphaTo( self._targetAlpha, 0.5 )
                end

                table.RemoveByValue( CFCNotifications._popups, self.data )
                self:Remove()
            end
        end
    end

    function panel:OnTimeout()
        -- Other hooks won't be called with buttons disabled, this still will though, so ignore it.
        if self:GetButtonsDisabled() then return end

        self.data.notification:_callHook( popupID, "OnClose", popupID, true )
        CFCNotifications._removePopup( panel )
    end

    function panel:OnClose()
        self.data.notification:_callHook( popupID, "OnClose", popupID, false )
        CFCNotifications._removePopup( self )
    end

    function panel:OnIgnore( permanent )
        for k, v in pairs( CFCNotifications._popups ) do
            if v.notification == self.data.notification then
                v.panel:OnClose()
            end
        end
        self.data.notification:Ignore( permanent )
    end
end

function CFCNotifications._removePopupByID( id )
    for k, v in pairs( CFCNotifications._popups ) do
        if v.popupID == id then
            CFCNotifications._removePopup( v.panel )
            return true
        end
    end
    return false
end

function CFCNotifications._removePopupByNotificationID( id )
    for k, v in pairs( CFCNotifications._popups ) do
        if v.notification:GetID() == id then
            CFCNotifications._removePopup( v.panel )
        end
    end
end

function CFCNotifications._removePopup( panel )
    local data = panel.data
    if not data then return end
    if panel._shouldRemove then return end
    local idx = table.KeyFromValue( CFCNotifications._popups, data )
    panel:SetButtonsDisabled( true )

    local pWidth = panel:GetWide()

    if panel:IsVisible() then
        panel._targetX = panel._targetX + pWidth -- move self right
        panel._shouldRemove = true

        local leftOpen = 0
        for k, v in pairs( CFCNotifications._popups ) do
            if not v.panel._shouldRemove then
                leftOpen = leftOpen + 1
            end
        end

        if leftOpen == 0 then
            CFCNotifications.freeCursorLabel:CustomAlphaTo( 0, 0.1 )
            clickerEnabled = false
            gui.EnableScreenClicker( clickerEnabled )
        end
    else
        table.remove( CFCNotifications._popups, idx )
        panel:Remove()
    end
end

function CFCNotifications._addNewPopup( notif )
    if not CFCNotifications.container then
        print( "Notification received too early! Discarding." )
        return false
    end
    local canClose = notif:GetCloseable()
    local canIgnore = notif:GetIgnoreable()
    local priority = notif:GetPriority()

    local pWidth = CFCNotifications.getSetting( "size_x" )
    local pHeight = CFCNotifications.getSetting( "size_y" )

    local panel = vgui.Create( "DNotification", CFCNotifications.container )
    panel:SetSize( pWidth, pHeight )
    panel:SetCloseable( canClose )
    panel:SetIgnoreable( canIgnore )
    if notif:GetTimed() then
        panel:SetDisplayTime( notif:GetDisplayTime() )
    end
    panel:SetTitle( notif:GetTitle() )
    panel:SetAlwaysTiming( notif:GetAlwaysTiming() )
    if priorityColors[priority] then
        panel:SetTitleBarColor( priorityColors[priority] )
    end
    panel:Populate()
    panel:InvalidateLayout( true )

    CFCNotifications._popupIDCounter = CFCNotifications._popupIDCounter + 1
    local id = CFCNotifications._popupIDCounter
    local data = {
        panel = panel,
        notification = notif,
        popupID = id,
    }

    addNotifHooks( panel, id )

    if #CFCNotifications._popups == 0 then
        CFCNotifications.freeCursorLabel:CustomAlphaTo( 255, 0.3 )
    end

    local idx = addData( data )

    panel.data = data

    notif:PopulatePanel( panel:GetCanvas(), id, panel )
    local maxNotif = CFCNotifications.getSetting( "max_notifications" )
    if idx > maxNotif then
        panel:Hide()
        panel:SetAlpha( 0 )
    else
        -- move all above panels up one
        for k = idx + 1, #CFCNotifications._popups do
            local cPanel = CFCNotifications._popups[k].panel
            if cPanel:IsVisible() then
                cPanel._targetY = cPanel._targetY - ( pHeight + notifSpacing )
            end
        end

        -- Hide the top panel if it exists
        local topPanelData = CFCNotifications._popups[maxNotif + 1]
        if topPanelData then
            local topPanel = topPanelData.panel
            topPanel._hidden = true
            topPanel:CustomAlphaTo( 0, 0.5, 0, function()
                topPanel:Hide()
            end )
        end

        -- slide self in left
        local notifX = CFCNotifications.container:GetWide()
        local notifY = CFCNotifications.container:GetTall() - ( pHeight + ( idx - 1 ) * ( pHeight + notifSpacing ) )

        panel:SetPos( notifX, notifY )
        panel._targetX = 0
        panel._targetY = notifY
    end

    notif:_callHook( id, "OnOpen", id )

    if CFCNotifications.getSetting( "allow_sound" ) then
        local min_priority = CFCNotifications.getSetting( "min_priority_sound" )
        if priority >= min_priority then
            surface.PlaySound( "garrysmod/balloon_pop_cute.wav" )
        end
    end

    return id
end

function CFCNotifications.Base:IsNotificationShowing()
    return #CFCNotifications.Base:GetPopupIDs() > 0
end

function CFCNotifications.Base:GetPopupIDs()
    local out = {}
    for k, v in pairs( CFCNotifications._popups ) do
        if v.notification == self then
            table.insert( out, v.popupID )
        end
    end
    return out
end

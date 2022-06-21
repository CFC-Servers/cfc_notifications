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

    local nonNotificationClick = clickerEnabled and key == MOUSE_LEFT and x < ( ScrW() - wide )

    local shouldToggle = key == KEY_F3 or nonNotificationClick
    shouldToggle = shouldToggle and not DarkRP

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
    if not input.IsButtonDown( KEY_LALT ) then return end

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
    function container:Think()
        self:MoveToBack()
    end

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
        local shouldShow = false
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
                        shouldShow = true
                    end
                    break
                end
            end
        end
        if self._prevShow ~= shouldShow then
            self._prevShow = shouldShow
            self:CustomAlphaTo( shouldShow and 255 or 0, 0.3 )
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
    local p = data.priority
    for k, v in ipairs( CFCNotifications._popups ) do
        if v.priority <= p then
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

                local idx = table.KeyFromValue( CFCNotifications._popups, self.data )
                for k = idx + 1, #CFCNotifications._popups do -- move all above down
                    local cPanel = CFCNotifications._popups[k].panel
                    cPanel._targetY = cPanel._targetY + ( pHeight + notifSpacing )
                end

                -- Fade and slide the next hidden notif in
                local maxNotif = CFCNotifications.getSetting( "max_notifications" )
                local topPanelData = CFCNotifications._popups[maxNotif + 1]
                if topPanelData then
                    local topPanel = topPanelData.panel
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

    function panel:OnIgnore( permanent, hidePrint )
        local popups = CFCNotifications._popups
        local popupCount = #popups
        local notifID = self.data.notifID

        -- TODO: Server can send multiple notifications with identical IDs. Probably should fix the root of that issue, when client receives new notifs from server.
        for i = popupCount, 1, -1 do
            local popup = popups[i]

            if popup.notifID == notifID then
                popup.panel:OnClose()
            end
        end

        self.data.notification:Ignore( permanent, hidePrint )
    end
end

-- Yoinked and modified from https://github.com/FPtje/DarkRP/blob/master/gamemode/modules/base/cl_util.lua1
local function charWrap( text, remainingWidth, maxWidth )
    local totalWidth = 0

    text = text:gsub( ".", function( char )
        local charW = surface.GetTextSize( char )
        totalWidth = totalWidth + charW

        -- Wrap around when the max width is reached
        if totalWidth >= remainingWidth then
            -- totalWidth needs to include the character width because it's inserted in a new line
            totalWidth = charW
            remainingWidth = maxWidth
            return "\n" .. char
        end

        return char
    end )

    return text, totalWidth
end

local function textWrap( text, font, maxWidth )
    local totalWidth = 0

    surface.SetFont( font )

    local spaceWidth, lineHeight = surface.GetTextSize( " " )
    text = text:gsub( "(%s?[%S]+)", function( word )
        local char = string.sub( word, 1, 1 )
        if char == "\n" or char == "\t" then
            totalWidth = 0
        end

        local wordlen = surface.GetTextSize( word )
        totalWidth = totalWidth + wordlen

        -- Wrap around when the max width is reached
        if wordlen >= maxWidth then -- Split the word if the word is too big
            local splitWord, splitPoint = charWrap( word, maxWidth - ( totalWidth - wordlen ), maxWidth )
            totalWidth = splitPoint
            return splitWord
        elseif totalWidth < maxWidth then
            return word
        end

        -- Split before the word
        if char == " " then
            totalWidth = wordlen - spaceWidth
            return "\n" .. string.sub( word, 2 )
        end

        totalWidth = wordlen
        return "\n" .. word
    end )

    local _, count = text:gsub( "\n", "" )

    return text, ( count + 1 ) * lineHeight
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

    local panel = vgui.Create( "DNotification", CFCNotifications.container )
    panel:SetSize( pWidth, 1 )

    local text, pHeight = textWrap( notif:GetText(), "CFC_Notifications_Big", CFCNotifications.getSetting( "size_x" ) - 10 )
    local heightOffset = 50 + notif:GetExtraHeight()

    pHeight = math.max( pHeight + heightOffset, 100 )
    panel:SetHeight( pHeight )
    notif:SetText( text )

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
        priority = priority,
        popupID = id,
        notifID = notif:GetID(),
    }

    addNotifHooks( panel, id )

    if #CFCNotifications._popups == 0 then
        CFCNotifications.freeCursorLabel:CustomAlphaTo( 255, 0.3 )
    end

    local idx = addData( data )

    panel.data = data
    notif:PopulatePanel( panel:GetCanvas(), id, panel )
    local maxNotif = CFCNotifications.getSetting( "max_notifications" )

    local dontShow = idx > maxNotif
    if dontShow then
        panel:Hide()
        panel:SetAlpha( 0 )
    end

    -- move all above panels up one
    for k = idx + 1, #CFCNotifications._popups do
        local cPanel = CFCNotifications._popups[k].panel
        cPanel._targetY = cPanel._targetY - ( pHeight + notifSpacing )
    end

    if not dontShow then
        -- Hide the top panel if it exists
        local topPanelData = CFCNotifications._popups[maxNotif + 1]
        if topPanelData then
            local topPanel = topPanelData.panel
            topPanel._hidden = true
            topPanel:CustomAlphaTo( 0, 0.5, function()
                topPanel:Hide()
            end )
        end
    end

    -- slide self in left
    local notifX = dontShow and 0 or CFCNotifications.container:GetWide()
    local notifY

    if idx > 1 then
        local panelBelow = CFCNotifications._popups[idx - 1].panel
        notifY = panelBelow._targetY - pHeight - notifSpacing
    else
        notifY = CFCNotifications.getSetting( "start_y_fraction" ) * ScrH() - pHeight - notifSpacing
    end

    panel:SetPos( notifX, notifY )
    panel._targetX = 0
    panel._targetY = notifY

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

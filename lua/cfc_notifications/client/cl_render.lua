CFCNotifications._popups = {}
CFCNotifications._popupIDCounter = 0

hook.Add( "CFC_Notifications_init", "render_init", function()
    local c = vgui.Create( "DPanel" )
    c.Paint = function( self, w, h ) draw.RoundedBox( 0, 0, 0, w, h, Color(100,100,100,100) ) end --nil
    local wide = CFCNotifications.getSetting( "size_x" ) * 1.2 -- Allow room for animation
    local h = CFCNotifications.getSetting( "start_y_fraction" ) * ScrH()
    c:SetSize( wide, h )
    c:SetPos( ScrW() - wide, 0 )
    CFCNotifications.container = c
end )

hook.Add( "CFC_Notifications_stop", "render_stop", function()
    if CFCNotifications.container then
        CFCNotifications.container:Remove()
        CFCNotifications.container = nil
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

function CFCNotifications._addNewPopup( notif )
    if not CFCNotifications.container then
        print( "Notification received too early! Discarding." )
        return false
    end
    local canClose = notif:GetCloseable()
    local canIgnore = notif:GetIgnoreable()

    local panel = vgui.Create( "DNotification", CFCNotifications.container )
    panel:SetSize( CFCNotifications.getSetting( "size_x" ), CFCNotifications.getSetting( "size_y" ) )
    panel:SetCloseable( canClose )
    panel:SetIgnoreable( canIgnore )
    if notif:GetTimed() then
        panel:SetDisplayTime( notif:GetDisplayTime() )
    end
    panel:SetTitle( notif:GetTitle() )
    panel:Populate()

    function panel:Think()
        local speed = 100

        local ct = SysTime()
        local pt = self._prevPaintTime
        local dt = ct - pt
        self._prevPaintTime = ct
        if dt > 0.5 then dt = 0 end

        local speedDT = speed * dt

        local x, y = self:GetPos()
        local tx, ty = self._targetX, self._targetY
        if not tx then return end
        
        local changed = false
        if tx ~= x then
            changed = true
            local change = math.Clamp( tx - x, -speedDT, speedDT )
            x = x + change
        end
        if ty ~= y then
            changed = true
            local change = math.Clamp( ty - y, -speedDT, speedDT )
            y = y + change
        end
        if changed then 
            self:SetPos( x, y )
        end
    end

    CFCNotifications._popupIDCounter = CFCNotifications._popupIDCounter + 1
    local id = CFCNotifications._popupIDCounter
    local data = {
        panel = panel,
        notification = notif,
        popupID = id,
    }

    local idx = addData( data )

    notif:PopulatePanel( panel:GetCanvas() )
    local maxNotif = CFCNotifications.getSetting( "max_notifications" )
    if idx > maxNotif then
        panel:Hide()
    else
        -- Animate the panel in
    end

    return id
end

function CFCNotifications.Base:IsNotificationShowing()
    return #CFCNotifications.Base:GetPopupIDS() > 0
end

function CFCNotifications.Base:GetPopupIDS()
    local out = {}
    for k, v in pairs( CFCNotifications._popups ) do
        if v.notification == self then
            table.insert( out, v.popupID )
        end
    end
    return out
end
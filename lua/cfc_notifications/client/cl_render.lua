CFCNotifications._popups = {}
CFCNotifications._popupIDCounter = 0

hook.Add( "CFC_Notifications_init", "render_init", function()
    local c = vgui.Create( "DFrame" ) -- DPanel might be better
    c:SetDraggable( false )
    c:ShowCloseButton( false )
    c:SetTitle( "" )
    c.Paint = function( self, w, h ) draw.RoundedBox( 0, 0, 0, w, h, Color(100,100,100,100) ) end --nil
    local wide = CFCNotifications.getSetting( "size_x" ) * 1.2 -- Allow room for animation
    local h = CFCNotifications.getSetting( "start_y_fraction" )
    c:SetSize( wide, h )
    c:SetPos( ScrW() - wide, 0 )

    CFCNotifications.container = c
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
    panel:SetClosable( canClose )
    panel:SetIgnoreable( canIgnore )
    if notif:GetTimed() then
        panel:SetDisplayTime( notif:GetDisplayTime() )
    end
    panel:Populate()

    CFCNotifications._popupIDCounter = CFCNotifications._popupIDCounter + 1
    local data = {
        panel = panel,
        notification = notif
        popupID = CFCNotifications._popupIDCounter
    }

    local idx = addData( data )

    notif:PopulatePopup( panel:GetCanvas() )
    local maxNotif = CFCNotifications.getSetting( "max_notifications" )
    if idx > maxNotif then
        panel:Hide()
    else
        -- Animate the panel in
    end

    return true
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
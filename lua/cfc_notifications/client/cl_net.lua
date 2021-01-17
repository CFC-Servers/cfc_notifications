net.Receive( "CFC_NotificationSend", function( len )
    local notif = net.ReadTable()
    notif._fromServer = true
    -- Fix up the metatable
    local CONTEXT = CFCNotifications.Types[notif._type]
    local mt = {}
    mt.__index = CONTEXT
    setmetatable( notif, mt )

    notif:Send()
    notif._sent = true
end )

CFCNotifications._serverNotificationIDs = {}

net.Receive( "CFC_NotificationExists", function( len )
    local id = net.ReadString()
    local exists = net.ReadBool()
    local hasValue = table.HasValue( CFCNotifications._serverNotificationIDs, id )

    if exists == hasValue then return end -- No change

    if exists then
        table.insert( CFCNotifications._serverNotificationIDs, id )
        CFCNotifications._reloadIgnoredPanels()
    else
        table.RemoveByValue( CFCNotifications._serverNotificationIDs, id )
        CFCNotifications._reloadIgnoredPanels()
    end
end )

net.Receive( "CFC_NotificationEvent", function( len )
    local id = net.ReadString()
    local funcName = net.ReadString()
    local data = net.ReadTable()

    if funcName == "RemovePopup" then
        local popupID = data[1]
        if popupID then
            CFCNotifications._removePopupByID( popupID )
        else
            CFCNotifications._removePopupByNotificationID( id )
        end
    else
        for _, popup in pairs( CFCNotifications._popups ) do
            local notif = popup.notification

            if notif._id == id then
                if not notif[funcName] then return end

                notif[funcName]( notif, unpack( data ) )

                break
            end
        end
    end
end )

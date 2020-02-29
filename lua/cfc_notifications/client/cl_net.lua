net.Receive( "CFC_NotificationSend", function( len )
    local notif = net.ReadTable()
    notif._fromServer = true
    -- Fix up the metatable
    local CONTEXT = CFCNotifications.Types[notif._type]
    local mt = {}
    mt.__index = CONTEXT
    setmetatable( notif, mt )

    notif:Send()
end )

CFCNotifications._serverNotificationIDs = {}

net.Receive( "CFC_NotificationExists", function( len )
	local id = net.ReadString()
	local exists = net.ReadBool()
	local hasValue = table.HasValue( CFCNotifications._serverNotificationIDs, id )
	if exists and not hasValue then
		table.insert( CFCNotifications._serverNotificationIDs, id )
		CFCNotifications._reloadIgnoredPanels()
	elseif not exists and hasValue then
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
    end
end )
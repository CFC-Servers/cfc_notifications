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
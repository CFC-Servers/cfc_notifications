function CFCNotifications.sendSimple( id, message, filter )
    local notif = CFCNotifications.new( id, "SimpleText" )
    notif:SetText( message )
    notif:Send( filter )
end

function CFCNotifications.sendImportantSimple( id, message, filter )
    local notif = CFCNotifications.new( id, "SimpleText" )
    notif:SetText( message )
    notif:SetCloseable( false )
    notif:SetPriority( CFCNotifications.PRIORITY_MAX )
    notif:Send( filter )
end
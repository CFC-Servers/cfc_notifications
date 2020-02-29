function CFCNotifications.sendSimple( id, message, filter )
    local notif = CFCNotifications.get( id ) or CFCNotifications.new( id, "Text" )
    notif:SetText( message )
    notif:Send( filter )
    return notif
end

function CFCNotifications.sendImportantSimple( id, message, filter )
    local notif = CFCNotifications.get( id ) or CFCNotifications.new( id, "Text" )
    notif:SetText( message )
    notif:SetCloseable( false )
    notif:SetPriority( CFCNotifications.PRIORITY_MAX )
    notif:Send( filter )
end
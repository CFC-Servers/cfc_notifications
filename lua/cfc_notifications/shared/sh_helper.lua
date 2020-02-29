function CFCNotifications.sendSimple( id, message, filter )
    local notif = CFCNotifications.getOrNew( id, "Text" )
    notif:SetText( message )
    notif:SetCloseable( true )
    notif:SetPriority( CFCNotifications.PRIORITY_NORMAL )
    notif:Send( filter )
    return notif
end

function CFCNotifications.sendImportantSimple( id, message, filter )
    local notif = CFCNotifications.getOrNew( id, "Text" )
    notif:SetText( message )
    notif:SetCloseable( false )
    notif:SetPriority( CFCNotifications.PRIORITY_MAX )
    notif:Send( filter )
    return notif
end
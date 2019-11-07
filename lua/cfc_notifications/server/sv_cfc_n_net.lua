function CFCNotifications.makePopup( message, filter )
    local getPlayers = filter or player.GetAll

    local players = getPlayers()

    net.Start( "CFC_PopupNotification" )
        net.WriteString( message )
    net.Send( players )
end


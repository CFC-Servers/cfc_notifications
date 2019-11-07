net.Receive( "CFC_PopupNotification", function( len, ply )
    local isFromServer = not ( IsValid( ply ) and ply:IsPlayer() )
    if not isFromServer then return end

    local message = net.ReadString()

    makePopupNotification( message )
end )
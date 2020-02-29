local function forceWriteTable( tab )
    for k, v in pairs( tab ) do

        local typeID = TypeID( v )
        if typeID == TYPE_TABLE then
            -- Ensure we recurse with this tablewrite, no the original
            net.WriteType( k )
            net.WriteUInt( typeID, 8 )
            forceWriteTable( v )
        elseif net.WriteVars[TypeID(v)] then
            -- Just gonna skip over things we can't encode
            net.WriteType( k )
            net.WriteType( v )
        end
    end
    -- End of table
    net.WriteType( nil )
end

function CFCNotifications._sendClients( players, notif )
    -- WriteTable can't write functions, so we're using forceWriteTable
    net.Start( "CFC_NotificationSend" )
    forceWriteTable( notif )
    net.Send( players )
end

net.Receive( "CFC_NotificationEvent", function( len, ply )
    local id = net.ReadString()
    local popupID = net.ReadUInt( 16 )
    local funcName = net.ReadString()
    local data = net.ReadTable()

    local notif = CFCNotifications.get( id )
    if not notif then return end

    notif._popupIDs = notif._popupIDs or {}
    notif._popupIDs[ply] = notif._popupIDs[ply] or {}

    -- Keep track of popup ids
    if funcName == "OnOpen" then
        notif._popupIDs[ply][popupID] = true
    elseif funcName == "OnClose" then
        notif._popupIDs[ply][popupID] = nil
    end

    if notif[funcName] then
        notif:SetCallingPopupID( popupID )
        notif[funcName]( notif, ply, unpack(data) )
    end
end )

function CFCNotifications.Base:_callClient( ply, funcName, ... )
    net.Start( "CFC_NotificationEvent" )
    net.WriteString( self:GetID() )
    net.WriteString( funcName )
    net.WriteTable( { ... } )
    net.Send( ply )
end

function CFCNotifications.Base:IsNotificationShowing( ply )
    return #CFCNotifications.Base:GetPopupIDs( ply ) > 0
end

function CFCNotifications.Base:GetPopupIDs( ply )
    if self._popupIDs and self._popupIDs[ply] then
        return table.GetKeys( self._popupIDs[ply] )
    end
    return {}
end

net.Receive( "CFC_NotificationExists", function( len, ply )
    for k, v in pairs( CFCNotifications.Notifications ) do
        net.Start( "CFC_NotificationExists" )
        net.WriteString( k )
        net.WriteBool( true )
        net.Send( ply )
    end
end )
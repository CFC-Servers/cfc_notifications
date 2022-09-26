local function forceWriteTable( tab )
    for k, v in pairs( tab ) do
        local typeID = TypeID( v )
        if typeID == TYPE_TABLE then
            -- Ensure we recurse with this tablewrite, no the original
            net.WriteType( k )
            net.WriteUInt( typeID, 8 )
            forceWriteTable( v )
        elseif net.WriteVars[TypeID( v )] then
            -- net.WriteVars is the table net uses when calling net.WriteType
            -- Key = TYPEID, Value = Function to write that type
            -- We're going to check it exists first, so WriteType can't error
            net.WriteType( k )
            net.WriteType( v )
        end
    end
    -- End of table
    net.WriteType( nil )
end

CFCNotifications.playerNetQueues = {}

local function splitReady( plys )
    local ready = {}
    local notReady = {}
    for _, ply in pairs( plys ) do
        if CFCNotifications.playersReady[ply] then
            table.insert( ready, ply )
        else
            table.insert( notReady, ply )
        end
    end

    return ready, notReady
end

local function sendQueuedMessages( ply )
    local queue = CFCNotifications.playerNetQueues[ply]
    if not queue then return end
    CFCNotifications.playerNetQueues[ply] = nil

    if #queue == 0 then return end
    timer.Create( "CFC_Notifications_ClearQueue_" .. ply:EntIndex(), 0.1, #queue, function()
        local func = table.remove( queue, 1 )
        pcall( func )
    end )
end

function CFCNotifications._sendMessage( name, func, plys )
    if type( plys ) == "Player" then plys = { plys } end
    local ready, notReady = splitReady( plys )

    if #ready > 0 then
        net.Start( name )
        func()
        net.Send( ready )
    end

    for _, ply in pairs( notReady ) do
        CFCNotifications.playerNetQueues[ply] = CFCNotifications.playerNetQueues[ply] or {}
        table.insert( CFCNotifications.playerNetQueues[ply], function()
            net.Start( name )
            func()
            net.Send( ply )
        end )
    end
end

function CFCNotifications._sendClients( players, notif )
    notif = table.Copy( notif )
    CFCNotifications._sendMessage( "CFC_NotificationSend", function()
        forceWriteTable( notif )
    end, players )
end

net.Receive( "CFC_NotificationEvent", function( _, ply )
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
        notif[funcName]( notif, ply, unpack( data ) )
    end
end )

function CFCNotifications.Base:_callClient( ply, funcName, ... )
    local data = { ... }
    CFCNotifications._sendMessage( "CFC_NotificationEvent", function()
        net.WriteString( self:GetID() )
        net.WriteString( funcName )
        net.WriteTable( data )
    end, ply )
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

net.Receive( "CFC_NotificationReady", function( _, ply )
    hook.Run( "CFC_NotificationsReady", ply )
    sendQueuedMessages( ply )
    for id, notif in pairs( CFCNotifications.Notifications ) do
        net.Start( "CFC_NotificationExists" )
        net.WriteString( id )
        net.WriteBool( notif:GetIgnoreable() and notif:GetCloseable() )
        net.Send( ply )
    end
end )

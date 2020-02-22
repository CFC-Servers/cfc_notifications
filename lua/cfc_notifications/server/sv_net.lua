local function forceWriteTable( tab )
	for k, v in pairs( tab ) do
		-- Just gonna skip over things we can't encode
		if net.WriteVars[TypeID(v)] then
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
	local funcName = net.ReadString()
	local id = net.ReadString()
	local data = net.ReadTable()

	local notif = CFCNotifications.Notifications[id]
	if not notif then return end
	if notif[funcName] then
		notif[funcName]( notif, unpack(data) )
	end
end )
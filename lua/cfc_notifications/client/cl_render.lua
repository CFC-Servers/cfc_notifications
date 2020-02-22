function CFCNotifications._getNewPanel( notif )
    local canClose = notif:GetCloseable()
    local priority = notif:GetPriority()

    local panel = vgui.Create( "DPanel" ) -- This should inherit from some frame on the right of the window

    -- Populate, position, etc. based on canClose and priority

    return panel
end

function CFCNotifications.isNotificationShowing( id )
	if type( id ) == "table" then
		-- Notif passed in, not id
		id = id:GetID()
	end
	-- Do something with the id

	return false
end
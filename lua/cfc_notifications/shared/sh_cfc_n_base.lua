CFCNotifications = CFCNotifications or {}

-- includes + network strs
if SERVER then
	util.AddNetworkString( "CFC_ReceivePopupNotification" )
	include("cfc_notifications/server/sv_cfc_n_net.lua")
else
	include("cfc_notifications/client/cl_cfc_n_net.lua")
	include("cfc_notifications/client/cl_cfc_n_render.lua")
	include("cfc_notifications/client/cl_cfc_n_save.lua")
end

include("sh_cfc_n_presets.lua")
include("sh_cfc_n_scheduled.lua")

CFCNotifications._registerNotification = function( notificationType, message, delay, recurring, filter )
    local repititions = recurring and 0 or 1

    local callback = nil
    if notificationType == "popup" then
        callback = makePopup
    end

    if not callback then return "Invalid notification type" end

    local timerName = CFCNotifications.getTimerName()
    timer.Create( timerName, delay, repititions, function()
        callback( message, filter )
    end )
end

-- Public API Below
CFCNotifications.registerPopup = function( message, interval, filter )
    CFCNotifications._registerNotification( "popup", message, interval, true, filter )
end


local function generateFilter( ply )
    return function()
        return { ply }
    end
end
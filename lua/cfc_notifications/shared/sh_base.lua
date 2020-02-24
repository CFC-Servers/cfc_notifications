CFCNotifications = CFCNotifications or {}
CFCNotifications.Types = {}
CFCNotifications.Notifications = {}

CFCNotifications.PRIORITY_MIN = 0
CFCNotifications.PRIORITY_LOW = 1
CFCNotifications.PRIORITY_NORMAL = 2
CFCNotifications.PRIORITY_HIGH = 3
CFCNotifications.PRIORITY_MAX = 4

-- includes + network strs
include( "sh_context.lua" )
include( "sh_helper.lua" )
if SERVER then
    util.AddNetworkString( "CFC_NotificationSend" )
    util.AddNetworkString( "CFC_NotificationEvent" )
    include( "cfc_notifications/server/sv_net.lua" )
else
    include( "cfc_notifications/client/cl_net.lua" )
    include( "cfc_notifications/client/cl_dnotification.lua" )
    include( "cfc_notifications/client/cl_render.lua" )
    include( "cfc_notifications/client/cl_save.lua" )
    include( "cfc_notifications/client/cl_settings.lua" )
end

-- naming convention:
-- camelCase for public methods on CFCNotifications
-- _camelCase for private methods/tables on CFCNotifications
-- UpperCamelCase for methods on a Notification object (CONTEXT)


function CFCNotifications.registerNotificationType( notificationType, callback )
    local CONTEXT = table.Copy( CFCNotifications.Base )
    callback( CONTEXT )
    CFCNotifications.Types[notificationType] = CONTEXT
end

include( "sh_presets.lua" )

function CFCNotifications.new( id, notificationType )
    if not id or not notificationType then
        error( "No id or type provided" )
    end
    local CONTEXT = CFCNotifications.Types[notificationType]
    if not CONTEXT then
        error( "No such notification type \"" .. notificationType .. "\"" )
    end
    if CFCNotifications.Notifications[id] then
        --error( "Notification id " .. notificationId .. " already in use")
    end
    local notif = {}
    notif._id = id
    notif._type = notificationType
    local mt = {}
    mt.__index = CONTEXT
    setmetatable( notif, mt )

    CFCNotifications.Notifications[id] = notif
    return notif
end

local function fWrap( ... )
    local data = { ... }
    return function()
        return unpack( data )
    end
end

-- Can take in an obj, list of objs, or function: which can return an obj or list of objs
-- Always returns a list of objs
-- This does not check the list returned only contains players
function CFCNotifications._resolveFilter( filter )
    if type( filter ) == "Player" then
        filter = { filter }
    end
    if type( filter ) == "table" then
        filter = fWrap( filter )
    end
    filter = filter or player.GetAll
    local players = filter()
    if type(players) == "Player" then
        players = { players }
    end
    return players
end

concommand.Add("cfc_notifications_reload", function()
    include( "cfc_notifications/shared/sh_base.lua" )
    timer.Simple( 0.1, function()
        hook.Run( "CFC_Notifications_init" )
    end )
end )

hook.Run( "CFC_Notification_Initialize" )
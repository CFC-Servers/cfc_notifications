CFCNotifications = CFCNotifications or {}
CFCNotifications.Types = {}
CFCNotifications.Notifications = {}

CFCNotifications.PRIORITY_MIN = 0
CFCNotifications.PRIORITY_LOW = 1
CFCNotifications.PRIORITY_NORMAL = 2
CFCNotifications.PRIORITY_HIGH = 3
CFCNotifications.PRIORITY_MAX = 4

-- includes + network strs
if SERVER then
    util.AddNetworkString( "CFC_NotificationSend" )
    util.AddNetworkString( "CFC_NotificationEvent" )
    include( "cfc_notifications/client/sv_net.lua" )
else
    include( "cfc_notifications/client/cl_net.lua" )
    include( "cfc_notifications/client/cl_render.lua" )
    include( "cfc_notifications/client/cl_save.lua" )
end

include( "sh_context.lua" )
include( "sh_helper.lua" )

function CFCNotifications.registerNotificationType( notificationType, callback )
    local CONTEXT = table.Copy( CFCNotifications.Base )
    callback( CONTEXT )
    CFCNotifications.Types[notificationType] = CONTEXT
end

include( "sh_presets.lua" )

function CFCNotifications.new( id, notificationType )
    local CONTEXT = CFCNotifications.Types[notificationType]
    if not CONTEXT then
        error( "No such notification type \"" .. notificationType .. "\"" )
    end
    if CFCNotifications.Notifications[id] then
        error( "Notification id " .. notificationId .. " already in use")
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

hook.Run( "CFC_Notification_Initialize" )
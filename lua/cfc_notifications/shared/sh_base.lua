CFCNotifications = CFCNotifications or {}
CFCNotifications.Types = {}
CFCNotifications.Notifications = {}

CFCNotifications.PRIORITY_MIN = 1
CFCNotifications.PRIORITY_LOW = 2
CFCNotifications.PRIORITY_NORMAL = 3
CFCNotifications.PRIORITY_HIGH = 4
CFCNotifications.PRIORITY_MAX = 5

-- naming convention:
-- camelCase for methods on CFCNotifications
-- UpperCamelCase for methods on a Notification object ( CONTEXT )
-- prefix with _ for private

-- includes + network strs
include( "sh_context.lua" )
include( "sh_helper.lua" )

if SERVER then
    util.AddNetworkString( "CFC_NotificationSend" ) -- send a notification from server
    util.AddNetworkString( "CFC_NotificationEvent" ) -- on notif events, like OnClose
    util.AddNetworkString( "CFC_NotificationExists" ) -- Keeping client up to date on server side notifications, for ignore
    util.AddNetworkString( "CFC_NotificationReady" )
    include( "cfc_notifications/server/sv_net.lua" )

    CFCNotifications.playersReady = {}
    hook.Add( "CFC_NotificationsReady", "trackReady", function( ply )
        CFCNotifications.playersReady[ply] = true
    end )

    hook.Add( "PlayerDisconnected", "CFC_NotificationUnready", function( ply )
        CFCNotifications.playersReady[ply] = true
    end )

    -- Give chance for other addons to load
    timer.Simple( 0, function()
        hook.Run( "CFC_Notifications_init" )
    end )
else
    include( "cfc_notifications/client/cl_net.lua" )
    include( "cfc_notifications/client/cl_dnotification.lua" )
    include( "cfc_notifications/client/cl_dnotificationbutton.lua" )
    include( "cfc_notifications/client/cl_render.lua" )
    include( "cfc_notifications/client/cl_save.lua" )
    include( "cfc_notifications/client/cl_settings.lua" )

    hook.Add( "Think", "CFCNotifications_request_data", function()
        hook.Remove( "Think", "CFCNotifications_request_data" )

        -- Acting as a way of saying "I'm ready"
        net.Start( "CFC_NotificationReady" )
        net.SendToServer()
    end )
end

function CFCNotifications.registerNotificationType( notificationType, callback, inherit )
    local CONTEXT

    if inherit then
        CONTEXT = CFCNotifications.Types[inherit]
        if not CONTEXT then
            error( "Unknown inherited notification type " .. inherit )
        end
    else
        CONTEXT = CFCNotifications.Base
    end

    local NEW_CONTEXT = table.Copy( CONTEXT )
    callback( NEW_CONTEXT )
    CFCNotifications.Types[notificationType] = NEW_CONTEXT
end

include( "sh_presets.lua" )

function CFCNotifications.new( id, notificationType, forceCreate )
    if not id or not notificationType then
        error( "No id or type provided" )
    end

    local CONTEXT = CFCNotifications.Types[notificationType]
    if not CONTEXT then
        error( "No such notification type \"" .. notificationType .. "\"" )
    end

    -- Check notification with given id already exists
    if CFCNotifications.Notifications[id] then
        if forceCreate then
            CFCNotifications.Notifications[id]:Remove()
        else
            error( "Notification id " .. id .. " already in use. Pass true as third argument to force replace." )
        end
    end

    local notif = {}
    -- Set id and type on notification
    notif._id = id
    notif._type = notificationType

    -- Build and set metatable for notif
    local mt = {}
    mt.__index = CONTEXT
    setmetatable( notif, mt )

    notif:SetIgnoreable( true )

    -- Initialize notification
    if notif.Init then
        notif:Init()
    end

    CFCNotifications.Notifications[id] = notif

    if CLIENT then
        CFCNotifications._reloadIgnoredPanels()
    end

    return notif
end

function CFCNotifications.get( id )
    return CFCNotifications.Notifications[id]
end

function CFCNotifications.getOrNew( id, notificationType )
    if CFCNotifications.get( id ) then
        return CFCNotifications.get( id )
    end
    return CFCNotifications.new( id, notificationType )
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

    if type( players ) == "Player" then
        players = { players }
    end

    if not players then players = player.GetAll() end

    return players
end

hook.Add( "CFC_Notifications_init", "init_message", function()
    print( "CFCNotifications loaded." )
end )

function CFCNotifications.reload()
    -- Escape this context
    timer.Simple( 0, function()
        hook.Run( "CFC_Notifications_stop" )
        include( "cfc_notifications/shared/sh_base.lua" )

        -- Wait for new notifs to load
        timer.Simple( 0.1, function()
            hook.GetTable().Initialize.cfc_notifications_init()
            net.Start( "CFC_NotificationExists" )
            net.SendToServer()
        end )
    end )
end

util.AddNetworkString( "CFC_ReceivePopupNotification" )

CFCNotifications = CFCNotifications or {}

CFCNotifications._timerNameCount = 1

local function getTimerName()
    local newName = "notification-timer-" .. tostring( CFCNotifications._timerNameCount )

    CFCNotifications._timerNameCount = CFCNotifications._timerNameCount + 1

    return newName
end

local function makePopup( message, filter )
    local getPlayers = filter or player.GetAll

    local players = getPlayers()

    net.Start( "CFC_PopupNotification" )
        net.WriteString( message )
    net.Send( players )
end

CFCNotifications._registerNotification = function( notificationType, message, delay, recurring, filter )
    local repititions = recurring and 0 or 1

    local callback = nil
    if notificationType == "popup" then
        callback = makePopup
    end

    if not callback then return "Invalid notification type" end

    local timerName = getTimerName()
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

local function addTestNotif( ply )
    CFCNotifications.registerPopup( "This is a test notification!", 1, generateFilter( ply ))
end

concommand.Add( "cfc_notif", addTestNotif )

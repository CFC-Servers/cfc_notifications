CFCNotifications._timerNameCount = 1

function CFCNotifications.getTimerName()
    local newName = "notification-timer-" .. tostring( CFCNotifications._timerNameCount )

    CFCNotifications._timerNameCount = CFCNotifications._timerNameCount + 1

    return newName
end

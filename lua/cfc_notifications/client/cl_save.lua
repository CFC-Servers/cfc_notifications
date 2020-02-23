-- Save/load notification perferences (such as "ignore this session" and "ignore forever")

function CFCNotifications.Base:ShouldShowNotification()
    local id = self:GetID()
    -- Temporary
    return true
end
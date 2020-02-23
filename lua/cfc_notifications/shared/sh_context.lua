CFCNotifications._timerNameCount = 1
CFCNotifications.contextHelpers = {}

function CFCNotifications._getTimerName()
    local newName = "notification-timer-" .. tostring( CFCNotifications._timerNameCount )

    CFCNotifications._timerNameCount = CFCNotifications._timerNameCount + 1 -- How I yearn for the ++ operator

    return newName
end

local function checkTypes( tab, t )
    for k, v in pairs(tab) do
        if type(v) ~= t then
            return false
        end
    end
    return true
end

local CONTEXT = {}
CFCNotifications.Base = CONTEXT

function CONTEXT:Send( filter )
    if SERVER then
        local players = CFCNotifications._resolveFilter( filter )
        local valid = checkTypes( players, "Player" )
        if not valid then
            return -- or maybe error?
        end
        CFCNotifications._sendClients( players, self )
    else
        -- Lets not pop up the same notification more than once
        if not self:GetAllowMultiple() and self:IsNotificationShowing( self ) then
            return
        end

        -- Check it's allowed to show
        if self:GetCloseable() and not self:ShouldShowNotification() then
            return
        end
        -- Call something in render.lua to make a panel for this notif
        return CFCNotifications._addNewPopup( self )
    end
end

function CONTEXT:SendDelayed( delay, filter )
    self:SendRepeated( delay, 1, filter )
end

function CONTEXT:SendRepeated( delay, reps, filter )
    if self._timerName then
        error( "Timer already running" )
    end
    self._timerName = CFCNotifications._getTimerName()
    timer.Create( self._timerName, delay, reps, function()
        self:Send( filter )
        if timer.RepsLeft( self._timerName ) == 1 then -- This might need to be 0, untested
            self._timerName = nil
        end
    end )
end

function CONTEXT:CancelDelay()
    if self._timerName then
        timer.Remove( self._timerName )
        self._timerName = nil
    end
end

CONTEXT.CancelTimer = CONTEXT.CancelDelay

function CONTEXT:HasTimer()
    return not not self._timerName
end

function CONTEXT:GetID()
    return self._id
end

function CONTEXT:GetType()
    return self._type
end

-- Add a field (Getter, Setter and default value) to context. "name" in camelCase
function CFCNotifications.contextHelpers.addField( context, name, default, argType )
    local internalName = "_" .. name
    local externalName = string.upper( name[1] ) .. string.sub( name, 2 )
    context[internalName] = default
    context["Set" .. externalName] = function(self, v)
        if type(v) ~= argType then
            error( "Unexpected type in Set" .. externalName .. ", expected " .. argType .. ", got " .. type(v))
        end
        self[internalName] = v
    end
    context["Get" .. externalName] = function(self)
        return self[internalName]
    end
end
local addField = function( ... ) CFCNotifications.contextHelpers.addField( CONTEXT, ... ) end

addField( "closeable", true, "boolean" )
addField( "displayTime", 5, "number" )
addField( "timed", true, "boolean" )
addField( "priority", CFCNotifications.PRIORITY_NORMAL, "number" )
addField( "allowMultiple", false, "boolean" )
addField( "ignoreable", true, "boolean" )

-- Empty implementations to be overwritten in registerType
function CONTEXT:PopulatePanel( panel ) end
-- End

function CFCNotifications.contextHelpers.addHook( context, funcName )
    context[funcName] = function( self, ... )
        if CLIENT and self._fromServer then
            net.Start( "CFC_NotificationEvent" )
            net.WriteString( funcName )
            net.WriteString( self:GetID() )
            net.WriteTable( { ... } )
            net.SendToServer()
        end
    end
end
local addHook = function( ... ) CFCNotifications.contextHelpers.addHook( CONTEXT, ... ) end

-- Empty implementations to be overwritten in register (by you!)
addHook( "OnClose" )
-- End
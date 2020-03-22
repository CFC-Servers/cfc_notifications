CFCNotifications._timerNameCount = 1
CFCNotifications.contextHelpers = {}

function CFCNotifications._getTimerName()
    local newName = "notification-timer-" .. tostring( CFCNotifications._timerNameCount )

    CFCNotifications._timerNameCount = CFCNotifications._timerNameCount + 1

    return newName
end

local function containsType( tab, t )
    for k, v in pairs( tab ) do
        if type( v ) ~= t then
            return false
        end
    end

    return true
end

local CONTEXT = {}
CFCNotifications.Base = CONTEXT

function CONTEXT:Remove()
    if SERVER then
        for k, v in pairs( player.GetAll() ) do
            self:RemovePopups( v )
        end
        net.Start( "CFC_NotificationExists" )
        net.WriteString( self:GetID() )
        net.WriteBool( false )
        net.Broadcast()
    else
        self:RemovePopups()
        CFCNotifications._reloadIgnoredPanels()
    end

    CFCNotifications.Notifications[self:GetID()] = nil
end

function CONTEXT:RemovePopup( id, ply )
    if SERVER then
        self:_callClient( ply, "RemovePopup", id )
    else
        if id then
            CFCNotifications._removePopupByID( id )
        else
            CFCNotifications._removePopupByNotificationID( self:GetID() )
        end
    end
end

function CONTEXT:RemovePopups( ply )
    self:RemovePopup( nil, ply )
end

function CONTEXT:Send( filter )
    if SERVER then
        local players = CFCNotifications._resolveFilter( filter )
        local valid = containsType( players, "Player" )
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

        if timer.RepsLeft( self._timerName ) == 0 then
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

-- Add a field ( Getter, Setter and default value ) to context. "name" in camelCase
function CFCNotifications.contextHelpers.addField( context, name, default, argType, onChange )
    -- _internalName (underscore .. camelCase
    local internalName = "_" .. name
    -- ExternalName (UpperCamelCase)
    local externalName = string.upper( name[1] ) .. string.sub( name, 2 )
    local setterName = "Set" .. externalName
    local getterName = "Get" .. externalName

    context[internalName] = default

    context[setterName] = function( self, v )
        -- Type checking
        if argType == "Color" then
            -- Color objects are actually just tables, so use IsColor() to check them
            if not IsColor( v ) then
                error( "Unexpected type in Set" .. externalName .. ", expected " .. argType .. ", got " .. type( v ) )
            end
        elseif type( v ) ~= argType then
            error( "Unexpected type in Set" .. externalName .. ", expected " .. argType .. ", got " .. type( v ) )
        end
        -- Set value
        self[internalName] = v
        -- Call onChange
        if onChange then onChange( self, v ) end
    end

    context[getterName] = function( self )
        return self[internalName]
    end
end
local addField = function( ... ) CFCNotifications.contextHelpers.addField( CONTEXT, ... ) end

addField( "displayTime", 5, "number" )
addField( "timed", true, "boolean" )
addField( "priority", CFCNotifications.PRIORITY_LOW, "number" )
addField( "allowMultiple", false, "boolean" )
addField( "title", "Notification", "string" )
addField( "alwaysTiming", false, "boolean" )
addField( "callingPopupID", -1, "number" )

local function ignoreableChanged( self, ignoreable )
    if SERVER then
        -- Delay as often called directly after new, which sends a message
        timer.Simple( 0.1, function()
            net.Start( "CFC_NotificationExists" )
            net.WriteString( self:GetID() )
            net.WriteBool( ignoreable and self:GetCloseable() )
            net.Broadcast()
        end )
    end
end

addField( "closeable", true, "boolean", ignoreableChanged )
addField( "ignoreable", true, "boolean", ignoreableChanged )



-- Empty implementations to be overwritten in registerType
function CONTEXT:PopulatePanel( panel ) end
function CONTEXT:OnAltNum( key ) end
-- End

function CONTEXT:_callHook( popupID, hookName, ... )
    if self._fromServer then
        net.Start( "CFC_NotificationEvent" )
        net.WriteString( self:GetID() )
        net.WriteUInt( popupID, 16 )
        net.WriteString( hookName )
        net.WriteTable( { ... } )
        net.SendToServer()
    else
        if self[hookName] then
            self:SetCallingPopupID( popupID )
            self[hookName]( self, ... )
        end
    end
    if self[hookName .. "_Client"] then
        self:SetCallingPopupID( popupID )
        self[hookName .. "_Client"]( self, ... )
    end
end

-- Empty implementations to be overwritten in register ( by you! )

function CONTEXT:OnClose( wasTimeout ) end
function CONTEXT:OnOpen( popupID ) end
-- End

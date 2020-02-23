CFCNotifications._settingsTemplate = {
    {
        name = "max_notifications",
        type = "int",
        min = 1,
        max = 10,
        default = 3,
    },
    {
        name = "size_x",
        type = "int",
        min = 50,
        max = 300,
        default = 150,
    },
    {
        name = "size_y",
        type = "int",
        min = 30,
        max = 200,
        default = 70,
    },
    {
        name = "start_y_fraction",
        type = "int",
        min = 0.2,
        max = 1,
        default = 0.7,
    },
    {
        name = "allow_sound",
        type = "bool",
        default = true,
    },
    {
        name = "min_priority_sound",
        type = "int",
        min = 1,
        max = 5,
        default = 4
    }
}

local typeGetters = {
    int = function( cVar ) return cVar:GetInt() end,
    bool = function( cVar ) return cVar:GetBool() end,
    float = function( cVar ) return cVar:GetFloat() end,
    string = function( cVar ) return cVar:GetString() end,
}

function CFCNotifications.getSetting( name )
    local cVar = GetConVar( "cfc_notifications_" .. name )
    if not cVar then return nil end
    for k, v in pairs( CFCNotifications._settingsTemplate ) do
        if v.name == name then
            return typeGetters[v.type]( cVar )
        end
    end
end

local typeValidators
typeValidators = {
    float = function( data, val )
        local n = tonumber( val )
        if n then
            local range = "(" .. (data.min or "-inf") .. ", " .. (data.max or "inf") .. ")"
            if data.min and n < data.min then
                return false, "Value too low, must be in range " .. range
            end
            if data.max and n > data.max then
                return false, "Value too high, must be in range " .. range
            end
            return true, val
        else
            return false, "Not a number"
        end
    end,
    int = function( data, val )
        local success, err = typeValidators.int( data, val )
        if not success then return false, err end
        local n = tonumber( val )
        if n % 1 == 0 then
            return true, val
        else
            return false, "Not an integer"
        end
    end,
    bool = function( data, val )
        val = string.lower( val )
        local tVals = {"1", "true", "t"}
        local fVals = {"0", "false", "f"}
        if table.HasValue( tVals, val ) then
            return true, "1"
        elseif table.HasValue( fVals, val ) then
            return false, "0"
        else
            return false, "Invalid boolean value"
        end
    end,
    string = function( data, val )
        return true, val
    end,
}

hook.Add( "Initialize", "cfc_notifications_init", function()
    for k, setting in pairs( CFCNotifications._settingsTemplate ) do
        local val = "cfc_notifications_" .. setting.name
        if not ConVarExists(val) then
            local def = setting.default
            local t = setting.type
            if type(def) == "bool" then def = def and 1 or 0 end
            CreateClientConVar(val, def)
            cvars.AddChangeCallback( val, function( cvar, old, new )
                local validator = typeValidators[t]
                local success, validVal = validator( new )
                if success then
                    if validVal ~= new then
                        cvar:SetString( validVal )
                    end
                else
                    print( "Error: " .. validVal )
                    cvar:SetString( old )
                end
            end )
        end
    end
    hook.Run( "CFC_Notifications_init" )
end )
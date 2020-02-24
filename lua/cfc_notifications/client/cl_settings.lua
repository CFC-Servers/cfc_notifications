-- Full console settings manager, good practice :)
-- Structure:
--[[
    {
        displayName - Name shown in Options menu (optional if noMenu)
        name - convar will be called "cfc_notifications_" .. name
        type - int, float, string, bool or action (button)
        min, max - for int and float only (optional)
        default - default value for convar
        onClick - for action only
        info - tooltip information for Options menu (optional)
        noMenu - true if setting should not be in the Options menu (optional)
    }
]]
CFCNotifications._settingsTemplate = {
    {
        displayName = "Maximum visible notifications",
        name = "max_notifications",
        type = "int",
        min = 1,
        max = 10,
        default = 3,
        info = "maximum number of notifications showing before hiding new ones"
    },
    {
        displayName = "Notification width",
        name = "size_x",
        type = "int",
        min = 300,
        max = 600,
        default = 400,
    },
    {
        displayName = "Notification height",
        name = "size_y",
        type = "int",
        min = 70,
        max = 300,
        default = 100,
    },
    {
        displayName = "First notification Y",
        name = "start_y_fraction",
        type = "float",
        min = 0.2,
        max = 1,
        default = 0.65,
        info = "Percent of screen height for first notification to show at"
    },
    {
        displayName = "Enable sounds",
        name = "allow_sound",
        type = "bool",
        default = true,
        info = "Should notifications with priority >= min_priority_sound (below) play a sound"
    },
    {
        displayName = "Minumum priority for sound",
        name = "min_priority_sound",
        type = "int",
        min = 1,
        max = 5,
        default = 4,
        info = "Minumum priority required for an alert sound to play if sounds enabled"
    },
    {
        name = "clear_settings_cache",
        type = "action",
        onClick = CFCNotifications.clearSettingsCache,
        noMenu = true
    },
    {
        displayName = "Reload CFCNotifications",
        name = "reload",
        type = "action",
        onClick = CFCNotifications.reload,
        extra = "This is required upon settings change"
    }
}

CFCNotifications._settingCache = {}

local typeGetters = {
    int = function( cVar ) return cVar:GetInt() end,
    bool = function( cVar ) return cVar:GetBool() end,
    float = function( cVar ) return cVar:GetFloat() end,
    string = function( cVar ) return cVar:GetString() end,
}

function CFCNotifications.getSetting( name )
    if CFCNotifications._settingCache[name] then
        return CFCNotifications._settingCache[name]
    end
    local cVar = GetConVar( "cfc_notifications_" .. name )
    if not cVar then return nil end
    for k, v in pairs( CFCNotifications._settingsTemplate ) do
        if v.name == name then
            local val = typeGetters[v.type]( cVar )
            CFCNotifications._settingCache[name] = val
            return val
        end
    end
end

function CFCNotifications.clearSettingsCache()
    CFCNotifications._settingCache = {}
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
        local success, err = typeValidators.float( data, val )
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

hook.Add( "CFC_Notifications_init", "settings_init", function()
    CFCNotifications.clearSettingsCache()
end )

hook.Add( "Initialize", "cfc_notifications_init", function()
    for k, setting in pairs( CFCNotifications._settingsTemplate ) do
        local val = "cfc_notifications_" .. setting.name
        if setting.type == "action" then
            concommand.Add( val, setting.onClick )
        elseif not ConVarExists( val ) then
            local def = setting.default
            local t = setting.type
            if type( def ) == "boolean" then def = def and 1 or 0 end
            CreateClientConVar(val, tostring(def))
            cvars.AddChangeCallback( val, function( cvarName, old, new )
                local cvar = GetConVar( cvarName )
                if old == new then return end
                local validator = typeValidators[t]
                local success, validVal = validator( setting, new )
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
    -- Let everything else run after settings are ready
    hook.Run( "CFC_Notifications_init" )
end )

hook.Add( "PopulateToolMenu", "CFCNotifications_settings", function()
    spawnmenu.AddToolMenuOption( "Options", "CFC", "cfc_notifications", "Notifications", "", "", function( panel )
        panel:ClearControls()
        for k, setting in pairs( CFCNotifications._settingsTemplate ) do
            if not setting.noMenu then
                local val = "cfc_notifications_" .. setting.name
                local c
                if setting.type == "bool" then
                    c = panel:CheckBox( setting.displayName, val )
                elseif setting.type == "action" then
                    c = panel:Button( setting.displayName, val )
                elseif setting.type == "int" then
                    c = panel:NumSlider( setting.displayName, val, setting.min or 0, setting.max or 100, 0 )
                elseif setting.type == "float" then
                    c = panel:NumSlider( setting.displayName, val, setting.min or 0, setting.max or 100, 2 )
                elseif setting.type == "string" then
                    c = panel:TextEntry( setting.displayName, val )
                end

                if setting.info then
                    c:SetTooltip( setting.info )
                end
            end
        end
    end )
end )
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

CFCNotifications._testMessages = {
    "Hey! A notification!",
    "This is a test.",
    "Hello world",
    "Goodbye universe",
    "Ping!",
    "Hey. Wake up.",
    "But How do it Know?",
    "Stop breaking the rules!",
    "The answer is 42, but what is the question?",
    "Tell legokidlogan to remove his minecraft e2",
    "Go ask Clashmecha how PhatTale is going!",
    "Tell Phatso to go to sleep"
}

CFCNotifications._cacheInvalid = false

CFCNotifications._settingsTemplate = {
    {
        displayName = "Max visible notifications",
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
        info = "Should notifications with priority >= min_priority_sound (below) play a sound",
        noCache = true
    },
    {
        displayName = "Min priority sound",
        name = "min_priority_sound",
        type = "int",
        min = 1,
        max = 5,
        default = 4,
        info = "Minumum priority required for an alert sound to play if sounds enabled",
        noCache = true
    },
    {
        displayName = "Adjusted cursor pos",
        name = "adjust_cursor",
        type = "bool",
        default = true,
        info = "Should your cursor position be next to notifications when pressing f3, rather than screen center",
        noCache = true
    },
    {
        name = "clear_settings_cache",
        type = "action",
        onClick = function()
            CFCNotifications.clearSettingsCache()
        end,
        noMenu = true
    },
    {
        displayName = "Show test notification",
        name = "test",
        type = "action",
        onClick = function()
            local notif = CFCNotifications._testNotification
            notif:SetText( CFCNotifications._testMessages[math.random( #CFCNotifications._testMessages )] )
            notif:SetDisplayTime( math.random( 2, 10 ) )
            notif:Send()
        end,
        extra = "Popup a test notification to see how it looks!"
    },
    {
        displayName = "Restore to default",
        name = "reset",
        onClick = function()
            CFCNotifications.resetSettings()
        end,
        type = "action",
        extra = "Revert all settings to their defaults"
    },
    {
        displayName = "Reload addon",
        name = "reload",
        onClick = function()
            CFCNotifications.reload()
        end,
        type = "action",
        extra = "This is required upon settings change",
        editMenuItem = function( c )
            function c:Think()
                self:SetTextColor( CFCNotifications._cacheInvalid and Color( 255, 0, 0 ) or Color( 0, 0, 0 ) )
            end
        end
    }
}

CFCNotifications._settingCache = {}

local typeGetters = {
    int = function( cVar ) return cVar:GetInt() end,
    bool = function( cVar ) return cVar:GetBool() end,
    float = function( cVar ) return cVar:GetFloat() end,
    string = function( cVar ) return cVar:GetString() end,
}

local typeSetters = {
    int = function( cVar, v ) return cVar:SetInt( v ) end,
    bool = function( cVar, v ) return cVar:SetBool( v ) end,
    float = function( cVar, v ) return cVar:SetFloat( v ) end,
    string = function( cVar, v ) return cVar:SetString( v ) end,
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
            if not v.noCache then
                CFCNotifications._settingCache[name] = val
            end
            return val
        end
    end
end

function CFCNotifications.clearSettingsCache()
    CFCNotifications._settingCache = {}
end

function CFCNotifications.resetSettings()
    for k, setting in pairs( CFCNotifications._settingsTemplate ) do
        if setting.type ~= "action" then
            local val = "cfc_notifications_" .. setting.name
            local cv = GetConVar( val )
            typeSetters[setting.type]( cv, setting.default )
        end
    end
    print( "Reverted CFCNotifications to default, reloading..." )
    CFCNotifications.reload()
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
            return true, "0"
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
    -- displays a normal test notification that shows for 5 seconds
    local notif = CFCNotifications.new( "test", "Text", true )

    -- Code for button test
    --notif:SetText( "Are you sure you want to burn all life on this planet?" )
    --notif:SetIgnoreable( false )
    --notif:SetTitle( "A real question" )
    --notif:AddButton( "Sure, why not", Color( 0, 255, 0 ), false )
    --notif:AddButton( "Maybe later?", Color( 255, 0, 0 ), false )
    --notif:AddButton( "A third option?", Color( 0, 0, 255 ), false )

    CFCNotifications._testNotification = notif
end )

hook.Add( "Initialize", "cfc_notifications_init", function()
    for k, setting in pairs( CFCNotifications._settingsTemplate ) do
        local val = "cfc_notifications_" .. setting.name
        if setting.type == "action" then
            concommand.Add( val, setting.onClick )
        elseif not ConVarExists( val ) then
            local def = setting.default
            local t = setting.type
            if type( def ) == "bool" then def = def and 1 or 0 end
            CreateClientConVar(val, tostring(def))
            cvars.AddChangeCallback( val, function( cvarName, old, new )
                local cvar = GetConVar( cvarName )
                if old == new then return end

                -- Form:NumSlider auto changes values by removing trailing 0's, aka 0.60000 -> 0.60, this triggers a nocache
                -- technically not a change, so lets ignore it
                if t == "float" and tonumber( old ) == tonumber( new ) then return end

                local validator = typeValidators[t]
                local success, validVal = validator( setting, new )
                if success then
                    if validVal ~= new then
                        cvar:SetString( validVal )
                    end
                    if not setting.noCache then
                        CFCNotifications._cacheInvalid = true
                    end
                else
                    print( "Error: " .. validVal )
                    cvar:SetString( old )
                end
            end )
        end
    end
    CFCNotifications.loadIgnores()
    -- Let everything else run after settings are ready
    if CFCNotifications.MenuOptions then
        CFCNotifications._updateMenuOptions( CFCNotifications.MenuOptions )
    end
    hook.Run( "CFC_Notifications_init" )
end )

local function addSettingsOptions()
    local panel = CFCNotifications.addOptionsCategory( "Settings" )
    panel:SetExpanded( true )
    panel:Help( "Some settings require you to reload the addon for them to take effect." )
    panel:Help( "The reload button will turn red if it is required" )
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

            if setting.editMenuItem then
                setting.editMenuItem( c )
            end

            if setting.info then
                c:SetTooltip( setting.info )
            end
        end
    end
    panel:Help( "" ) -- Bit of spacing at the end
end

function CFCNotifications._updateMenuOptions( panel )
    CFCNotifications.MenuOptions = panel
    panel:SetSize( 100, 400 )
    panel:Clear( true )

    panel.contents = panel.contents or vgui.Create( "DListLayout" )
    panel.contents:Clear()

    panel:SetContents( panel.contents )
    panel:Dock( FILL )

    addSettingsOptions()
    hook.Run( "CFC_Notifications_tool_menu" )
end

local function addListViewFunc( panel )
    function panel:ListView( strLabel )
        local listView = vgui.Create( "DListView", self )
        listView:AddColumn( strLabel )
        listView.AddItem = listView.AddLine
        listView.Stretch = true

        self:AddItem( listView )

        return listView
    end
end

function CFCNotifications.addOptionsCategory( name )
    local cat = CFCNotifications.MenuOptions.contents:Add( "DForm" )
    cat:SetLabel( name )
    cat:SetExpanded( false )

    cat.oldToggle = cat.Toggle
    function cat:Toggle()
        local isExpanded = self:GetExpanded()
        if isExpanded then return end -- Can't have none open
        self:oldToggle()
        for k, v in pairs( CFCNotifications.MenuOptions.contents:GetChildren() ) do
            if v ~= self and v:GetExpanded() then
                v:oldToggle()
            end
        end
    end

    addListViewFunc( cat )

    return cat
end

hook.Add( "PopulateToolMenu", "CFCNotifications_settings", function()
    spawnmenu.AddToolMenuOption( "Options", "CFC", "cfc_notifications", "Notifications", "", "", function( panel )
        CFCNotifications._updateMenuOptions( panel )
    end )
end )
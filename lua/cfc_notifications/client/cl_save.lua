-- Save/load notification perferences ( such as "ignore this session" and "ignore forever" )
CFCNotifications._tempIgnores = CFCNotifications._tempIgnores or {}
CFCNotifications._permIgnores = {}
CFCNotifications._SAVE_FILE_NAME = "cfc_notifications_data.json"

-- Add some way to browse ignores in settings and call Unignore on them

local COLOR_GREY = Color( 150, 150, 150, 255 )
local COLOR_DARK_GREY = Color( 41, 41, 41, 255 )
local COLOR_HIGHLIGHT = Color( 255, 230, 75, 255 )

function CFCNotifications.Base:ShouldShowNotification()
    local id = self:GetID()
    return not CFCNotifications._tempIgnores[id] and not CFCNotifications._permIgnores[id]
end

function CFCNotifications.Base:Ignore( permanent, hidePrint )
    local id = self:GetID()

    if permanent then
        if CFCNotifications._permIgnores[id] then return end

        CFCNotifications._permIgnores[id] = true
        CFCNotifications.saveIgnores()
    else
        if CFCNotifications._tempIgnores[id] then return end

        CFCNotifications._tempIgnores[id] = true
    end

    CFCNotifications._reloadIgnoredPanels()

    if hidePrint then return end

    if permanent then
        chat.AddText(
            COLOR_DARK_GREY, "[",
            COLOR_GREY, "Notifications",
            COLOR_DARK_GREY, "] ",
            color_white, "You will never see ",
            COLOR_HIGHLIGHT, tostring( id ),
            color_white, " notifications again."
        )
    else
        chat.AddText(
            COLOR_DARK_GREY, "[",
            COLOR_GREY, "Notifications",
            COLOR_DARK_GREY, "] ",
            color_white, "Temporarily ignoring ",
            COLOR_HIGHLIGHT, tostring( id ),
            color_white, " notifications for this session."
        )
    end
end

function CFCNotifications.Base:Unignore()
    local id = self:GetID()

    CFCNotifications._tempIgnores[id] = nil
    if CFCNotifications._permIgnores[id] then
        CFCNotifications._permIgnores[id] = nil
        CFCNotifications.saveIgnores()
    end

    CFCNotifications._reloadIgnoredPanels()
end

function CFCNotifications.saveIgnores()
    local strData = util.TableToJSON( table.GetKeys( CFCNotifications._permIgnores ) )
    file.Write( CFCNotifications._SAVE_FILE_NAME, strData )
end

function CFCNotifications.loadIgnores()
    local strData = file.Read( CFCNotifications._SAVE_FILE_NAME )
    if not strData then return end
    local data = util.JSONToTable( strData )
    for k = 1, #data do
        CFCNotifications._permIgnores[data[k]] = true
    end

    CFCNotifications._reloadIgnoredPanels()
end

function CFCNotifications.getTempIgnored()
    return table.GetKeys( CFCNotifications._tempIgnores )
end

function CFCNotifications.getPermIgnored()
    return table.GetKeys( CFCNotifications._permIgnores )
end

function CFCNotifications.getUnignored()
    local out = {}

    for k, v in pairs( CFCNotifications.Notifications ) do
        if not CFCNotifications._tempIgnores[k] and not CFCNotifications._permIgnores[k] and v:GetCloseable() and v:GetIgnoreable() then
            table.insert( out, k )
        end
    end

    for k, v in pairs( CFCNotifications._serverNotificationIDs ) do
        if not CFCNotifications._tempIgnores[v] and not CFCNotifications._permIgnores[v] and not table.HasValue( out, v ) then
            table.insert( out, v )
        end
    end

    return out
end

local panels = {}

function CFCNotifications._reloadIgnoredPanels()
    if #panels == 0 then return end

    panels[1]:Clear()

    for k, v in ipairs( CFCNotifications.getTempIgnored() ) do
        panels[1]:AddItem( v )
    end

    panels[2]:Clear()

    for k, v in ipairs( CFCNotifications.getPermIgnored() ) do
        panels[2]:AddItem( v )
    end

    panels[3]:Clear()

    for k, v in ipairs( CFCNotifications.getUnignored() ) do
        panels[3]:AddItem( v )
    end
end

hook.Add( "CFC_Notifications_init", "CFCNotifications_load_ignores", CFCNotifications.loadIgnores )

local function addList( panel, name, onLeft, onRight )
    local list = panel:ListView( name )
    list:SetSize( 100, 100 )
    list:SetMultiSelect( false )

    function list:OnRowSelected( idx, row )
        timer.Simple( 0, function()
            if not row:IsValid() then return end

            self:ClearSelection()

            local id = row:GetColumnText( 1 )

            self:RemoveLine( idx )
            onLeft( id )

            CFCNotifications._reloadIgnoredPanels()
        end )
    end

    function list:OnRowRightClick( idx, row )
        self:ClearSelection()

        local id = row:GetColumnText( 1 )

        self:RemoveLine( idx )
        onRight( id )

        CFCNotifications._reloadIgnoredPanels()
    end

    return list
end

hook.Add( "CFC_Notifications_tool_menu", "add_ignore_menu", function()
    local panel = CFCNotifications.addOptionsCategory( "Blacklist" )
    panel:Help( "Ignored notifications" )
    panel:ControlHelp( "Click an ID to remove it from your ignored notifications" )

    local tempIgnoredpanel = addList( panel, "Session blacklist ( cleared on disconnect )", function( id )
        CFCNotifications._tempIgnores[id] = nil
    end, function( id )
        CFCNotifications._tempIgnores[id] = nil
        CFCNotifications._permIgnores[id] = true
        CFCNotifications.saveIgnores()
    end )

    local permIgnoredpanel = addList( panel, "Permanent blacklist", function( id )
        CFCNotifications._permIgnores[id] = nil
        CFCNotifications.saveIgnores()
    end, function( id )
        CFCNotifications._permIgnores[id] = nil
        CFCNotifications._tempIgnores[id] = true
        CFCNotifications.saveIgnores()
    end )


    panel:Help( "Non-ignored notifications" )
    panel:ControlHelp( "Left click an ID to ignore temporarily, right click for permanent" )

    local Unignoredpanel = addList( panel, "Permanent whitelist", function( id )
        CFCNotifications._tempIgnores[id] = true
    end, function( id )
        CFCNotifications._permIgnores[id] = true
        CFCNotifications.saveIgnores()
    end )

    panels = { tempIgnoredpanel, permIgnoredpanel, Unignoredpanel }

    CFCNotifications._reloadIgnoredPanels()
end )

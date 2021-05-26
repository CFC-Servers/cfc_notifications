local BUTTON_ATTRIBUTES = {
    text = "SetText",
    color = "SetTextColor",
    alignment = "SetAlignment",
    autoClose = "SetAutoClose",
    canPress = "SetCanPress",
    location = true,
}

local function disableButtons( notif, btns )
    for _, v in pairs( btns ) do
        for _, v2 in pairs( v ) do
            if v2 ~= notif then
                v2:SetDisabled( true )
            end
        end
    end
end

local function isAlignmentValid( alignment )
    if alignment == CFCNotifications.ALIGN_LEFT then return true end
    if alignment == CFCNotifications.ALIGN_CENTER then return true end
    if alignment == CFCNotifications.ALIGN_RIGHT then return true end

    return false
end

local function isButtonLocationOccupied( context, row, col )
    if not context._buttons then
        error( "The notification has no buttons!" )

        return false
    end

    if not row or row < 1 or math.floor( row ) ~= row then
        error( "Invalid row! Rows must be a positive integer." )

        return false
    end

    if not col or col < 1 or math.floor( col ) ~= col then
        error( "Invalid column! Columns must be a positive integer." )

        return false
    end

    local rowTable = context._buttons[row] or {}

    if not context._buttons[row] or table.IsEmpty( rowTable ) then
        error( "Invalid row! The row is either empty or does not exist." )

        return false
    end

    local colTable = context._buttons[row][col] or {}

    if not context._buttons[row][col] or table.IsEmpty( colTable ) then
        error( "Invalid column! The column is either empty or does not exist." )

        return false
    end

    return true
end

local function canInsertButton( context, row, col )
    if not row or row < 1 or math.floor( row ) ~= row then
        error( "Invalid row! Rows must be a positive integer." )

        return false
    end

    if not col or col < 1 or math.floor( col ) ~= col then
        error( "Invalid column! Columns must be a positive integer." )

        return false
    end

    local numRows = #context._buttons
    local rowTable = context._buttons[numRows] or {}

    if row > numRows + 1 or ( row > numRows and table.IsEmpty( rowTable ) ) then
        error( "Invalid row! Cannot skip over unused row indeces." )

        return false
    end

    -- numCols is 0 if the current row is empty
    local numCols = math.max( #context._buttons[row], 1 )

    if col > numCols + 1 then
        error( "Invalid column! Cannot skip over unused column indeces." )

        return false
    end

    return true
end

local function isAllHumans( plys )
    for _, ply in pairs( player.GetHumans() ) do
        if not table.HasValue( plys, ply ) then return false end
    end

    return true
end

-- Simple label
CFCNotifications.registerNotificationType( "Text", function( CONTEXT )
    CFCNotifications.contextHelpers.addField( CONTEXT, "text", "", "string" )
    CFCNotifications.contextHelpers.addField( CONTEXT, "textColor", Color( 255, 255, 255 ), "Color" )

    function CONTEXT:PopulatePanel( canvas )
        local label = Label( self:GetText(), canvas )
        label:SetFont( "CFC_Notifications_Big" )
        label:SizeToContents()
        label:SetTextColor( self:GetTextColor() )
    end
end )

-- Simple label + any number of buttons
-- Close after button press
CFCNotifications.registerNotificationType( "Buttons", function( CONTEXT )
    CFCNotifications.contextHelpers.addField( CONTEXT, "text", "", "string" )
    CFCNotifications.contextHelpers.addField( CONTEXT, "textColor", Color( 255, 255, 255 ), "Color" )
    -- Args passed to AddButton after colour are passed into this button or the button text
    function CONTEXT:OnButtonPressed( data ) end

    CONTEXT._timed = false
    -- These require player input, so are more important than other notifications
    CONTEXT._priority = CFCNotifications.PRIORITY_NORMAL

    local btnH = 50
    local btnBottomMargin = 10
    local btnGap = 20

    CONTEXT:SetExtraHeight( btnH + btnBottomMargin - 20 )

    function CONTEXT:_addDefaultButtons()
        self:AddButton( "Yes", Color( 0, 255, 0 ), true )
        self:AddButton( "No", Color( 255, 0, 0 ), false )
    end

    function CONTEXT:AddButtonIndexed( text, color, alignment, row, col, ... )
        color = color or Color( 255, 255, 255 )

        if not isAlignmentValid( alignment ) then
            error( "Invalid alignment! Please use the ALIGN constants in CFCNotifications." )

            return
        end

        self._buttons = self._buttons or { {} }

        if not canInsertButton( self, row, col ) then return end

        if row > #self._buttons then
            self:NewButtonRow()
        end

        local button = {
            text = text,
            color = color,
            alignment = alignment,
            autoClose = true,
            canPress = true,
            data = { ... }
        }

        if self._buttons[row][col] and table.IsEmpty( self._buttons[row][col] ) then
            self._buttons[row][col] = button
        else
            table.insert( self._buttons[row], col, button )
        end
    end

    function CONTEXT:AddButtonAligned( text, color, alignment, ... )
        self._buttons = self._buttons or { {} }
        local row = #self._buttons
        local col = #self._buttons[row] + 1

        self:AddButtonIndexed( text, color, alignment, row, col, ... )
    end

    function CONTEXT:AddButton( text, color, ... )
        self._buttons = self._buttons or { {} }
        local row = #self._buttons
        local col = #self._buttons[row] + 1

        self:AddButtonIndexed( text, color, CFCNotifications.ALIGN_CENTER, row, col, ... )
    end

    function CONTEXT:NewButtonRow()
        if table.IsEmpty( self._buttons ) or table.IsEmpty( self._buttons[#self._buttons] ) then
            error( "Could not create a new row! The current row is empty!" )

            return
        end

        local numRows = #self._buttons + 1

        table.insert( self._buttons, numRows, {} )

        self:SetExtraHeight( btnH * numRows + btnBottomMargin - 20 )
    end

    function CONTEXT:_EditButtonAttribute( attribute, row, col, data, plys, fromNet )
        if not BUTTON_ATTRIBUTES[attribute] then return end

        if fromNet then -- Notification has already been sent, and is now being edited
            if not isButtonLocationOccupied( self, row, col ) then return end
            if SERVER and not isAllHumans( plys ) then return end -- SERVER only edits attribute if plys is equal to all humans
            if CLIENT and not table.HasValue( plys, LocalPlayer() ) then return end

            if attribute == "location" then
                if not canInsertButton( self, row, col ) then return end

                local numRows = #self._buttons

                -- Allowing notifications to change height after being sent requires a rework to how they are positioned
                -- Or it requires screwing with internal functions and data without a rewrite, either way it needs looking into
                if data.row > numRows then
                    error( "Cannot add new button rows once a notification has been sent!" )

                    return
                end

                local button = self._buttons[row][col]
                table.remove( self._buttons[row], col )
                local numCols = #self._buttons[data.row]

                if data.col > numCols + 1 then
                    data.col = numCols + 1
                end

                table.insert( self._buttons[data.row], data.col, button )

                if SERVER then return end

                local movedBtn = self._btns[row][col]
                table.remove( self._btns[row], col )
                table.insert( self._btns[data.row], data.col, movedBtn )

                -- Resize and reposition the buttons in the row that was moved to
                numCols = numCols + 1
                local canvas = self._panel:GetCanvas()
                local w, h = canvas:GetSize()

                local btnY = numRows - data.row + 1
                btnY = h - ( btnH * btnY + btnBottomMargin )

                local btnTotalW = w / ( numCols or 1 )
                local btnW = btnTotalW - btnGap

                for c, btn in ipairs( self._btns[data.row] ) do
                    btn:SetSize( btnW, btnH )
                    btn:SetPos( 10 + ( c - 1 ) * btnTotalW, btnY )
                end

                if row == data.row or table.IsEmpty( self._buttons[row] ) then return end

                -- Resize and reposition the buttons in the row that was moved from
                numCols = #self._buttons[row]
                btnY = numRows - row + 1
                btnY = h - ( btnH * btnY + btnBottomMargin )

                btnTotalW = w / ( numCols or 1 )
                btnW = btnTotalW - btnGap

                for c, btn in ipairs( self._btns[row] ) do
                    btn:SetSize( btnW, btnH )
                    btn:SetPos( 10 + ( c - 1 ) * btnTotalW, btnY )
                end
            else
                local funcName = BUTTON_ATTRIBUTES[attribute]

                self._buttons[row][col][attribute] = data

                if SERVER then return end

                self._btns[row][col][funcName]( self._btns[row][col], data )
            end

            return
        end

        if self._sent then -- Notification has already been sent
            if CLIENT then
                plys = { LocalPlayer() }
            elseif not plys then
                plys = player.GetHumans()
            elseif type( plys ) ~= "table" then
                if not IsValid( plys ) or not plys:IsPlayer() then
                    error( "That is not a valid player!" )

                    return
                end

                plys = { plys }
            end

            self:_callHook( -1, "_EditButtonAttribute", attribute, row, col, data, plys, true )
        elseif isButtonLocationOccupied( self, row, col ) then -- Notifications has not already been sent, and button location is valid
            if attribute == "location" then
                if not isButtonLocationOccupied( self, data.row, data.col ) then return end
                if not canInsertButton( self, row, col ) then return end

                local button = self._buttons[row][col]

                table.remove( self._buttons[row], col )

                if table.IsEmpty( self._buttons[row] ) then
                    table.remove( self._buttons, row )
                end

                local numRows = #self._buttons
                local numCols = #self._buttons[data.row]

                if data.row > numRows then
                    self:NewButtonRow()

                    if data.row > numRows + 1 then -- A gap is created when a button gets pulled out to move to the end
                        data.row = numRows + 1
                    end
                end

                if data.col > numCols + 1 then
                    data.col = numCols + 1
                end

                table.insert( self._buttons[data.row], data.col, button )
            else
                self._buttons[row][col][attribute] = data
            end
        end
    end

    function CONTEXT:EditButtonText( row, col, text, plys )
        self:_EditButtonAttribute( "text", row, col, text, plys, false )
    end

    function CONTEXT:EditButtonColor( row, col, color, plys )
        self:_EditButtonAttribute( "color", row, col, color, plys, false )
    end

    function CONTEXT:EditButtonAlignment( row, col, alignment, plys )
        self:_EditButtonAttribute( "alignment", row, col, alignment, plys, false )
    end

    function CONTEXT:EditButtonAutoClose( row, col, autoClose, plys )
        self:_EditButtonAttribute( "autoClose", row, col, autoClose, plys, false )
    end

    function CONTEXT:EditButtonCanPress( row, col, canPress, plys )
        self:_EditButtonAttribute( "canPress", row, col, canPress, plys, false )
    end

    function CONTEXT:EditButtonLocation( row, col, newRow, newCol, plys )
        local data = {
            row = newRow,
            col = newCol
        }

        self:_EditButtonAttribute( "location", row, col, data, plys, false )
    end

    function CONTEXT:OnAltNum( key )
        if key < 1 or key > 9 then return end

        local ind = 0
        local row, col

        for r, btnRow in pairs( self._btns ) do
            for c, btn in pairs( btnRow ) do
                ind = ind + 1

                if ind == key then
                    row = r
                    col = c

                    break
                end
            end
        end

        local btn = self._btns[row][col]

        if btn and btn.canPress then
            btn:DoClickInternal()
            btn:DoClick()

            return true
        end
    end

    function CONTEXT:PopulatePanel( canvas, popupID, panel )
        if not self._buttons then
            self:_addDefaultButtons()
        end

        local numRows = #self._buttons

        if table.IsEmpty( self._buttons[numRows] ) then
            self._buttons[numRows] = nil
            numRows = numRows - 1
            self:SetExtraHeight( btnH * numRows + btnBottomMargin - 20 )
        end

        local label = Label( self:GetText(), canvas )
        label:SetFont( "CFC_Notifications_Big" )
        label:SizeToContents()
        label:SetTextColor( self:GetTextColor() )

        local this = self
        local btns = {}
        local w, h = canvas:GetSize()

        local btnY = h - ( btnH * numRows + btnBottomMargin )

        for r, row in ipairs( self._buttons ) do
            local btnTotalW = w / ( #self._buttons[r] or 1 )
            local btnW = btnTotalW - btnGap
            table.insert( btns, {} )

            for c, btnData in ipairs( row ) do
                local btn = vgui.Create( "DNotificationButton", canvas )
                btn:SetText( btnData.text )
                btn:SetFont( "CFC_Notifications_Big" )
                btn:SetTextColor( btnData.color )
                btn:SetUnderlineWeight( 2 )
                btn:SetAlignment( btnData.alignment )
                btn:SetAutoClose( btnData.autoClose )
                btn:SetCanPress( btnData.canPress )

                function btn:DoClick()
                    if panel:GetButtonsDisabled() or not btn.canPress then return end

                    local autoClose = btn.autoClose

                    if autoClose then
                        panel:SetButtonsDisabled( true )

                        disableButtons( self, btns )
                    end

                    -- Delay the close to see the button animation, make it clear that the button is what was selected
                    timer.Simple( 0.5, function()
                        this:_callHook( popupID, "OnButtonPressed", unpack( btnData.data or { btnData.text } ) )

                        if not autoClose then return end

                        CFCNotifications._removePopup( panel )
                    end )
                end

                btn:SetSize( btnW, btnH )
                btn:SetPos( 10 + ( c - 1 ) * btnTotalW, btnY )
                table.insert( btns[r], btn )
            end

            btnY = btnY + btnH
        end

        self._btns = btns
        self._panel = panel
    end
end )

CFCNotifications.registerNotificationType( "TextAcknowledge", function( CONTEXT )
    local oldPopulate = CONTEXT.PopulatePanel
    function CONTEXT:OnButtonPressed_Client( ignore )
        if ignore then
            self:Ignore( true )
        end
    end
    CONTEXT._priority = CFCNotifications.PRIORITY_LOW

    CONTEXT:AddButton( "Okay!", Color( 0, 255, 0 ), false )
    CONTEXT:AddButton( "Never show again", Color( 255, 255, 255 ), true )
    function CONTEXT:PopulatePanel( canvas, popupID, panel )
        panel._unhoverTime = SysTime() + 1
        local oldThink = panel.Think

        function panel:Think()
            local x, y = self:LocalCursorPos()
            local w, h = self:GetSize()

            self._hovered = not ( x < 0 or x > w or y < 0 or y > h )
            if self._hovered ~= self._lastHovered then
                if self._hovered then
                    self._targetAlpha = 255

                    if not self._hidden then
                        self:CustomAlphaTo( self._targetAlpha, 0.1 )
                    end
                else
                    self._unhoverTime = SysTime()
                end
            end

            if not self._hovered and self._unhoverTime and SysTime() - self._unhoverTime > 1 then
                self._unhoverTime = nil
                self._targetAlpha = 100

                if not self._hidden then
                    self:CustomAlphaTo( self._targetAlpha, 0.5 )
                end
            end

            panel._lastHovered = panel._hovered

            oldThink( self )
        end

        oldPopulate( self, canvas, popupID, panel )
    end
end, "Buttons" )

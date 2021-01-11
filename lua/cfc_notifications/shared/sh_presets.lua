local function isAlignmentValid( alignment )
    if alignment == CFCNotifications.ALIGN_LEFT then return true end
    if alignment == CFCNotifications.ALIGN_CENTER then return true end
    if alignment == CFCNotifications.ALIGN_RIGHT then return true end

    return false
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
        -- Need to error if color is not valid

        if not isAlignmentValid( alignment ) then
            error( "Invalid alignment! Please use the ALIGN constants in CFCNotifications." )

            return
        end

        -- Need to see if there is a built-in for determining if a number is an integer or not
        if not row or row < 1 or math.floor( row ) ~= row then
            error( "Invalid row! Rows must be a positive integer." )

            return
        end

        -- Need to see if there is a built-in for determining if a number is an integer or not
        if not col or col < 1 or math.floor( col ) ~= col then
            error( "Invalid column! Columns must be a positive integer." )

            return
        end

        self._buttons = self._buttons or { {} }
        local numRows = #self._buttons

        if row > numRows + 1 or ( row > numRows and table.IsEmpty( self._buttons[numRows] ) ) then
            error( "Invalid row! Cannot skip over unused row indeces." )

            return
        end

        -- numCols is 0 if the current row is empty
        local numCols = math.max( #self._buttons[row], 1 )

        if col > numCols + 1 or ( col > numCols and table.IsEmpty( self._buttons[numCols] ) ) then
            error( "Invalid column! Cannot skip over unused column indeces." )

            return
        end

        if row > numRows then
            self:NewButtonRow()
        end

        local button = {
            text = text,
            color = color,
            alignment = alignment,
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

    function CONTEXT:OnAltNum( key )
        if key < 1 or key > 9 then return end
        if self._btns[key] then
            self._btns[key]:DoClickInternal()
            self._btns[key]:DoClick()
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

            for c, btnData in ipairs( row ) do
                local btn = vgui.Create( "DNotificationButton", canvas )
                btn:SetText( btnData.text )
                btn:SetFont( "CFC_Notifications_Big" )
                btn:SetTextColor( btnData.color )
                btn:SetUnderlineWeight( 2 )
                btn:SetAlignment( btnData.alignment )

                function btn:DoClick()
                    if panel:GetButtonsDisabled() then return end

                    panel:SetButtonsDisabled( true )

                    for _, v in pairs( btns ) do
                        if v ~= self then
                            v:SetDisabled( true )
                        end
                    end

                    -- Delay the close to see the button animation, make it clear that the button is what was selected
                    timer.Simple( 0.5, function()
                        CFCNotifications._removePopup( panel )
                        this:_callHook( popupID, "OnButtonPressed", unpack( btnData.data or { btnData.text } ) )
                    end )
                end

                btn:SetSize( btnW, btnH )
                btn:SetPos( 10 + ( c - 1 ) * btnTotalW, btnY )
                table.insert( btns, btn )
            end

            btnY = btnY + btnH
        end

        self._btns = btns
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

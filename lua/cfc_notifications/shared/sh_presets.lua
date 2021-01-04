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

    local btnH = 45
    local btnBottomMargin = 10

    CONTEXT:SetExtraHeight( btnH + btnBottomMargin - 20 )

    function CONTEXT:_addDefaultButtons()
        self:AddButton( "Yes", Color( 0, 255, 0 ), true )
        self:AddButton( "No", Color( 255, 0, 0 ), false )
    end

    function CONTEXT:AddButtonAligned( text, col, alignment, ... )
        col = col or Color( 255, 255, 255 )
        alignment = alignment or CFCNotifications.ALIGN_CENTER
        self._curRowSize = ( self._curRowSize or 0 ) + 1
        self._buttons = self._buttons or {}

        table.insert( self._buttons, {
            text = text,
            color = col,
            alignment = alignment,
            data = { ... }
        } )
    end

    function CONTEXT:AddButton( text, col, ... )
        self:AddButtonAligned( text, col, CFCNotifications.ALIGN_CENTER, ... )
    end

    function CONTEXT:NewButtonRow()
        if table.IsEmpty( self._buttons ) then return end
        if self._curRowSize < 1 then return end

        self._buttons[#self._buttons].startNewRow = true
        self._rowSizes = self._rowSizes or {}
        table.insert( self._rowSizes, self._curRowSize )
        self._curRowSize = 0

        self:SetExtraHeight( btnH * ( #self._rowSizes + 1 ) + btnBottomMargin - 20 )
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
        local label = Label( self:GetText(), canvas )
        label:SetFont( "CFC_Notifications_Big" )
        label:SizeToContents()
        label:SetTextColor( self:GetTextColor() )

        local this = self

        if not self._buttons then
            self:_addDefaultButtons()
        end

        if self._curRowSize > 0 then
            self._rowSizes = self._rowSizes or {}
            table.insert( self._rowSizes, self._curRowSize )
        end

        local w, h = canvas:GetSize()
        local btnRow = 1
        local btnCol = 1
        local btnGap = 20
        local btnTotalW = ( w / self._rowSizes[btnRow] )

        local btnW = btnTotalW - btnGap
        local btnY = h - ( btnH * #self._rowSizes + btnBottomMargin )

        local btns = {}
        for _, btnData in ipairs( self._buttons ) do
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
            btn:SetPos( 10 + ( btnCol - 1 ) * btnTotalW, btnY )
            table.insert( btns, btn )

            if btnData.startNewRow then
                btnRow = btnRow + 1
                btnCol = 1
                btnTotalW = ( w / ( self._rowSizes[btnRow] or 1 ) )
                btnW = btnTotalW - btnGap
                btnY = btnY + btnH
            else
                btnCol = btnCol + 1
            end
        end

        self._btns = btns
    end
end )

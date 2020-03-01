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

    function CONTEXT:_addDefaultButtons()
        self:AddButton( "Yes", Color( 0, 255, 0 ), true )
        self:AddButton( "No", Color( 255, 0, 0 ), false )
    end

    function CONTEXT:AddButton( text, col, ... )
        col = col or Color( 255, 255, 255 )
        self._buttons = self._buttons or {}
        table.insert( self._buttons, {
            text = text,
            color = col,
            data = { ... }
        } )
    end

    function CONTEXT:PopulatePanel( canvas, popupID, panel )
        local label = Label( self:GetText(), canvas )
        label:SetFont( "CFC_Notifications_Big" )
        label:SizeToContents()
        label:SetPos( 10, 0 )
        label:SetTextColor( self:GetTextColor() )

        local this = self

        if not self._buttons then
            self:_addDefaultButtons()
        end

        local w, h = canvas:GetSize()
        local btnW = w / #self._buttons

        local btns = {}

        for k, btnData in ipairs( self._buttons ) do
            local btn = vgui.Create( "DNotificationButton", canvas )
            btn:SetText( btnData.text )
            btn:SetFont( "CFC_Notifications_Big" )
            btn:SetTextColor( btnData.color )
            btn:SetUnderlineWeight( 2 )
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
                end )

                this:_callHook( popupID, "OnButtonPressed", unpack( btnData.data or { btnData.text } ) )
                -- this:_callHook( popupID, "OnClose", popupID, false )
            end
            btn:SetSize( btnW - 20, 30 )
            btn:SetPos( 10 + ( k - 1 ) * btnW, h - 40 )
            table.insert( btns, btn )
        end
    end
end )
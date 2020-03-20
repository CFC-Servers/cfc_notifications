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
                    this:_callHook( popupID, "OnButtonPressed", unpack( btnData.data or { btnData.text } ) )
                end )
            end
            btn:SetSize( btnW - 20, 30 )
            btn:SetPos( 10 + ( k - 1 ) * btnW, h - 40 )
            table.insert( btns, btn )
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
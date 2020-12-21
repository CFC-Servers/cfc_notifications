-- Create main text
function CFCNotifications.drawMessageText( canvas, text, color )
    local maxWidth = CFCNotifications.getSetting( "size_x" ) - 10 --Get client's width setting and account for textbox position

    local label = Label( text, canvas )
    local length = text:len()
    label:SetFont( "CFC_Notifications_Big" )

    if length > 0 then
        local labelWidth, _ = label:GetTextSize()
        local newText = ""

        if labelWidth > maxWidth then
            if text:find( "\n" ) then
                local lines = text:Split( "\n" )
                local biggestLength = 0
                local lengths = {}

                for _, line in pairs( lines ) do
                    local len = line:len()
                    table.insert( lengths, len )

                    if len > biggestLength then
                        biggestLength = len
                    end
                end

                local charWidth = labelWidth / biggestLength
                local chunkLength = math.floor( maxWidth / charWidth )

                for i, line in pairs( lines ) do
                    local len = lengths[i]

                    if len > chunkLength then
                        local index = 1

                        while index <= length do
                            newText = newText .. line:sub( index, math.min( index + chunkLength - 1, len ) ) .. "\n"
                            index = index + chunkLength
                        end
                    else
                        newText = newText .. line .. "\n"
                    end
                end

                newText = newText:sub( 1, newText:len() - 1 ) --Remove extra newline at the end
            else
                local charWidth = labelWidth / length
                local chunkLength = math.floor( maxWidth / charWidth )
                local index = 1

                while index <= length do
                    newText = newText .. text:sub( index, math.min( index + chunkLength - 1, length ) ) .. "\n"
                    index = index + chunkLength
                end

                newText = newText:sub( 1, newText:len() - 1 ) --Remove extra newline at the end
            end

            label:SetText( newText )
        end
    end

    label:SizeToContents()
    label:SetTextColor( color or color_white )

    return label
end

-- Simple label
CFCNotifications.registerNotificationType( "Text", function( CONTEXT )
    CFCNotifications.contextHelpers.addField( CONTEXT, "text", "", "string" )
    CFCNotifications.contextHelpers.addField( CONTEXT, "textColor", Color( 255, 255, 255 ), "Color" )

    function CONTEXT:PopulatePanel( canvas )
        CFCNotifications.drawMessageText( canvas, self:GetText(), self:GetTextColor() )
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
        CFCNotifications.drawMessageText( canvas, self:GetText(), self:GetTextColor() )

        local this = self

        if not self._buttons then
            self:_addDefaultButtons()
        end

        local w, h = canvas:GetSize()
        local btnGap = 20
        local btnTotalW = ( w / #self._buttons )

        local btnW = btnTotalW - btnGap
        local btnH = 30
        local btnBottomMargin = 10

        local btnY = h - ( btnH + btnBottomMargin )

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

            btn:SetSize( btnW, btnH )
            btn:SetPos( 10 + ( k - 1 ) * btnTotalW, btnY )
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

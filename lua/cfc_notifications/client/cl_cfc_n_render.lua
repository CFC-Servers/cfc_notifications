local function makePopupNotification( message )
    local bubbleWidth = 300
    local bubbleHeight = 170

    local bubbleX = ScrW() - bubbleWidth
    local bubbleY = ScrH() - ( bubbleHeight + 100 )

    local Container = vgui.Create( "DPanel" )
    Container:SetSize( bubbleWidth, bubbleHeight )
    --Container:SetPos( containerX, containerY )
    Container:SetDrawBackground( false )

    local Bubble = vgui.Create( "DBubbleContainer", Container )
    Bubble:SetBackgroundColor( Color( 36, 41, 67, 255 ) )

    Bubble:OpenForPos( bubbleX, bubbleY, bubbleWidth, bubbleHeight )

    local MessageLabel = vgui.Create( "DLabel", Bubble )
    MessageLabel:SetPos( 5, 5 )
    MessageLabel:SetSize( bubbleX * 0.9, bubbleY * 0.9 )
    MessageLabel:SetWrap( true )
    MessageLabel:SetFont( "Trebuchet24" )
    MessageLabel:SetText( message )

    function MessageLabel:PerformLayout()
        Title:SetFGColor( Color( 255, 255, 255, 255 ) )
        Title:SetToFullHeight()
    end
end
local PANEL = {}

local animSpeed = 0.2

-- Adjust by applying sin function to prog, still 0 - 1, but not increases with sin rather than linear
-- Mathsy thing to change the number to not increase in a boring way
-- Makes things look prettier
local function adjustProg( prog )
    return math.sin( prog * ( math.pi / 2 ) )
end

function PANEL:Init()
    self.animState = 0
    self.bgCol = Color( 0, 0, 255 )
    self.underlineWeight = 1
    self.clickAnimationLength = 1
    self.clickAnimState = 0
    self.text = ""
    self.alignment = CFCNotifications.ALIGN_CENTER
    self:SetTextColor( Color( 255, 255, 255 ) )
    self:SetBackgroundColor( Color( 100, 100, 100 ) )
    self.BaseClass.SetText( self, "" ) -- Hide the default panel text since we track and draw the text ourselves
end

function PANEL:Think()
    local disabled = self:GetDisabled()
    local textColor = self.textColor
    if disabled then
        self:SetCursor( "no" )
        self.BaseClass.SetTextColor( self, Color( 100, 100, 100 ) )
    else
        self:SetCursor( "hand" )
        self.BaseClass.SetTextColor( self, textColor )
    end

    local hovered = self:IsHovered()
    local time = SysTime()
    self.lastT = self.lastT or time
    local change = time - self.lastT
    self.lastT = time
    if change > 1 then change = 0 end -- If there has been > 1 second since last think, dont do the animation
    if hovered or self.clicked then
        self.animState = math.Clamp( self.animState + change / animSpeed, 0, 1 )
    else
        self.animState = math.Clamp( self.animState - change / animSpeed, 0, 1 )
    end

    if self.clicked then
        self.clickAnimState = self.clickAnimState + change
        if self.clickAnimState >= self.clickAnimationLength + 0.4 then
            self.clicked = false
            self.clickAnimState = 0
        end
    end
end

-- The base DButton class doesn't support text alignment, so we don't let it draw anything, and store the text ourself
function PANEL:SetText( text )
    self.text = string.Trim( text, "\n" )
end

function PANEL:GetText()
    return self.text
end

function PANEL:SetTextColor( textColor )
    self.BaseClass.SetTextColor( self, textColor )
    self.textColor = textColor
end

local function isAlignmentValid( alignment )
    if alignment == CFCNotifications.ALIGN_LEFT then return true end
    if alignment == CFCNotifications.ALIGN_CENTER then return true end
    if alignment == CFCNotifications.ALIGN_RIGHT then return true end

    return false
end

function PANEL:SetAlignment( alignment )
    if not isAlignmentValid( alignment ) then
        error( "Invalid alignment type! Please use the ALIGN constants in CFCNotifications." )

        return
    end

    self.alignment = alignment
end

function PANEL:Paint( w, h )
    if self:GetDisabled() then return end

    local uWeight = self:GetUnderlineWeight()
    local barHeight = h - uWeight - 4
    local halfWidth = w / 2

    if self.clicked then
        -- Click animation
        local col = table.Copy( self.textColor )
        col.a = col.a * 0.1
        surface.SetDrawColor( col )

        if self.clickAnimState >= self.clickAnimationLength + 0.2 then
            -- Progress val from 0 - 1 for start of animation ( bar expanding )
            local prog = ( self.clickAnimState - self.clickAnimationLength - 0.2 ) / 0.2
            -- See above for what this means
            local adjustedProg = adjustProg( prog )
            local inverseProg = 1 - adjustedProg
            surface.DrawRect( 0, 0, halfWidth * inverseProg, h - uWeight - 4 )
            surface.DrawRect( halfWidth + halfWidth * adjustedProg, 0, halfWidth * inverseProg, barHeight )
        else
            -- Progress val from 0 - 1 for end of animation ( bar collapsing )
            local prog = math.Clamp( self.clickAnimState / 0.2, 0, 1 )
            -- Same as previous "adjustedProg"
            local adjustedProg = adjustProg( prog )
            local inverseProg = 1 - adjustedProg
            surface.DrawRect( halfWidth * inverseProg, 0, w * adjustedProg, barHeight )
        end
    end

    -- Underline background
    surface.SetDrawColor( self:GetBackgroundColor() )
    surface.DrawRect( 0, barHeight, w, uWeight )

    -- Hover animation
    -- Adjusted animState (similar to prog) to be sinusoidal
    local prog = adjustProg( self.animState )
    local inverseProg = 1 - prog

    -- Underline foreground
    surface.SetDrawColor( self.textColor )
    surface.DrawRect( halfWidth * inverseProg, barHeight, w * prog, uWeight )

    -- Draw aligned multiline text
    surface.SetFont( self:GetFont() )
    surface.SetTextColor( self:GetTextColor() )

    local lines = string.Explode( "\n", self:GetText() )
    local numLines = #lines
    local _, textH = surface.GetTextSize( "|" )
    local textYStart = h / 2 - numLines * textH / 2
    local textXStart
    local textXMult

    if self.alignment == CFCNotifications.ALIGN_LEFT then
        textXStart = 0
        textXMult = 0
    elseif self.alignment == CFCNotifications.ALIGN_RIGHT then
        textXStart = w
        textXMult = -1
    else
        textXStart = halfWidth
        textXMult = -0.5
    end

    for k, line in pairs( lines ) do
        local textW = surface.GetTextSize( line )
        local textX = textXStart + textW * textXMult
        local textY = textYStart + ( k - 1 ) * textH

        surface.SetTextPos( textX, textY )
        surface.DrawText( line )
    end
end

function PANEL:SetUnderlineWeight( w )
    self.underlineWeight = w
end

function PANEL:GetUnderlineWeight()
    return self.underlineWeight
end

function PANEL:SetBackgroundColor( c )
    self.bgCol = c
end

function PANEL:GetBackgroundColor()
    return self.bgCol
end

function PANEL:SetClickAnimationLength( v )
    self.clickAnimationLength = v
end

function PANEL:GetClickAnimationLength()
    return self.clickAnimationLength
end

function PANEL:DoClickInternal()
    self.clicked = true
end

function PANEL:IsHovered()
    local w, h = self:GetSize()
    local x, y = self:LocalCursorPos()
    return x >= 0 and x <= w and y >= 0 and y <= h
end

vgui.Register( "DNotificationButton", PANEL, "DButton" )

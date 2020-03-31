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
    self:SetTextColor( Color( 255, 255, 255 ) )
    self:SetBackgroundColor( Color( 100, 100, 100 ) )
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

function PANEL:SetTextColor( textColor )
    self.BaseClass.SetTextColor( self, textColor )
    self.textColor = textColor
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

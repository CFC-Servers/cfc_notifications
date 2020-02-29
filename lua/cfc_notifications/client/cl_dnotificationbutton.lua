local PANEL = {}

local animSpeed = 0.2

function PANEL:Init()
    self.animState = 0
    self.bgCol = Color(0, 0, 255)
    self.underlineWeight = 1
    self.clickAnimationLength = 1
    self.clickAnimState = 0
    self:SetTextColor( Color( 255, 255, 255 ) )
    self:SetBackgroundColor( Color(100, 100, 100) )
end

function PANEL:Think()
    local disabled = self:GetDisabled()
    local tc = self.textCol
    if disabled then
        self:SetCursor("no")
        self.BaseClass.SetTextColor(self, Color(100, 100, 100))
    else
        self:SetCursor("hand")
        self.BaseClass.SetTextColor(self, tc)
    end

    local h = self:IsHovered()
    local time = SysTime()
    self.lastT = self.lastT or time
    local change = time - self.lastT
    self.lastT = time
    if change > 1 then change = 0 end -- If there has been > 1 second since last think, dont do the animation
    if h or self.clicked then
        self.animState = math.Clamp(self.animState + change / animSpeed, 0, 1)
    else
        self.animState = math.Clamp(self.animState - change / animSpeed, 0, 1)
    end

    if self.clicked then
        self.clickAnimState = self.clickAnimState + change
        if self.clickAnimState >= self.clickAnimationLength + 0.4 then
            self.clicked = false
            self.clickAnimState = 0
        end
    end
end

function PANEL:SetTextColor( tc )
    self.BaseClass.SetTextColor( self, tc )
    self.textCol = tc
end

function PANEL:Paint( w, h )
    if self:GetDisabled() then return end

    local uWeight = self:GetUnderlineWeight()

    if self.clicked then
        local col = table.Copy( self.textCol )
        col.a = col.a * 0.1
        surface.SetDrawColor( col )

        if self.clickAnimState >= self.clickAnimationLength + 0.2 then
            local prog = ( self.clickAnimState - self.clickAnimationLength - 0.2 ) / 0.2
            local adjustedProg = math.sin( prog * ( math.pi / 2 ) )
            surface.DrawRect( 0, 0, w * ( 1 - adjustedProg ) * 0.5, h - uWeight - 4 )
            surface.DrawRect( w * ( 0.5 + 0.5 * adjustedProg ), 0, w * ( 1 - adjustedProg ) * 0.5, h - uWeight - 4 )
        else
            local prog = math.Clamp( self.clickAnimState / 0.2, 0, 1 )
            local adjustedProg = math.sin( prog * ( math.pi / 2 ) )
            surface.DrawRect( w * ( 1 - adjustedProg ) * 0.5, 0, w * adjustedProg, h - uWeight - 4 )
        end
    end

    local s = math.sin( self.animState * ( math.pi / 2 ) )

    surface.SetDrawColor( self:GetBackgroundColor() )
    surface.DrawRect( 0, h - uWeight - 4, w, uWeight )

    surface.SetDrawColor( self.textCol )
    surface.DrawRect( w * (1 - s) * 0.5, h - uWeight - 4, w * s, uWeight )


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

vgui.Register("DNotificationButton", PANEL, "DButton")
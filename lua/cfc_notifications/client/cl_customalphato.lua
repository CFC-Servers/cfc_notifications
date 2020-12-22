local fadePanels = {}

hook.Add( "Think", "CustomAlphaTo_SetAlpha", function()
    local sTime = SysTime()
    -- Exposed as while loop so I can modify k
    -- So I can modify fadePanels while iterating it
    local k = 1
    while k <= #fadePanels do
        local v = fadePanels[k]
        if v:IsVisible() then
            local lerpVal = math.Clamp( ( sTime - v._ca_timeStart ) / ( v._ca_timeEnd - v._ca_timeStart ), 0, 1 )
            local newAlpha = Lerp( lerpVal, v._ca_startAlpha, v._ca_endAlpha )

            v:SetAlpha( newAlpha )

            if lerpVal == 1 then
                table.remove( fadePanels, k )
                if v._ca_callback then
                    v:_ca_callback()
                end
                v._ca_timeStart = nil
                v._ca_timeEnd = nil
                v._ca_startAlpha = nil
                v._ca_endAlpha = nil
                v._ca_callback = nil
                k = k - 1
            end
        end
        k = k + 1
    end
end )

local function AddCustomAlphaTo( CONTEXT )
    function CONTEXT:CustomAlphaTo( targetAlpha, time, cb )
        local sTime = SysTime()
        self._ca_timeStart = sTime
        self._ca_timeEnd = sTime + time
        self._ca_startAlpha = self:GetAlpha()
        self._ca_endAlpha = targetAlpha
        self._ca_callback = cb
        table.insert( fadePanels, self )
    end
end

-- Wait until vgui has loaded
function CFCNotifications._addCustomAlphaTo()
    if not vgui.GetControlTable( "DFrame" ) then return end
    timer.Remove( "ca_wait" )

    AddCustomAlphaTo( vgui.GetControlTable( "DLabel" ) )
    AddCustomAlphaTo( vgui.GetControlTable( "DPanel" ) )
    AddCustomAlphaTo( vgui.GetControlTable( "DFrame" ) )
end

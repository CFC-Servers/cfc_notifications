local PANEL = {}

function PANEL:Init()
	self:SetCloseable( true )
	self:SetIgnoreable( true )
	self:SetDisplayTime( nil )
end

function PANEL:SetCloseable( v )
	self._showClose = v
end

function PANEL:SetIgnoreable( v )
	self._showIgnore = v
end

function PANEL:SetDisplayTime( t )
	if t then
		self._showTimer = true
		self._maxTime = t
		self._curTime = 0
	else
		self._showTimer = false
	end
end

function PANEL:GetCanvas()
	return self._canvas
end

function PANEL:Populate()
	
	self._canvas = vgui.Create( "DPanel", self )
end

vgui.Register( "DNotification", PANEL, "DPanel" )
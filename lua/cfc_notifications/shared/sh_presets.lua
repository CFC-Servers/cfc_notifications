CFCNotifications.registerNotificationType( "SimpleText", function( CONTEXT )
	function CONTEXT:PopulatePanel( panel )
		local message = self:GetText()

		-- Use cl_render.lua to draw a simple text notification
	end
	CFCNotifications.ContextHelpers.addField( CONTEXT, "text", "" )
end )
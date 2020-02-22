function addFiles(dir)
	local files, dirs = file.Find(dir .. "/*", "LUA")
	if not files then return end
	for k, v in pairs(files) do
		if string.match(v, "^.+%.lua$") then
			AddCSLuaFile(dir .. "/" .. v)
		end
	end
	for k, v in pairs(dirs) do
		addFiles(dir .. "/" .. v)
	end
end
addFiles("cfc_notifications/client")
addFiles("cfc_notifications/shared")

include("cfc_notifications/shared/sh_base.lua")

if SERVER then
	AddCSLuaFile("client/cl_minimap.lua")
    AddCSLuaFile("client/minimap_settings.lua")  
    AddCSLuaFile("client/ezmask.lua")
    resource.AddSingleFile("materials/minimap/icon.png")
    resource.AddSingleFile("materials/minimap/arrow.png")
    resource.AddSingleFile("materials/minimap/cross.png")

      
end

if CLIENT then
	include("client/cl_minimap.lua")
end
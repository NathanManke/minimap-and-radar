local SCALE_DEFAULT     = 1
local ZOOM_DEFAULT      = 1
local XROOT_DEFAULT     = 0.1
local YROOT_DEFAULT     = 0.17
local RADIUS_DEFAULT    = 0.25
local ALPHA_DEFAULT     = 150

local LOCALA_DEFAULT = 200
local LOCALR_DEFAULT = 0
local LOCALG_DEFAULT = 200
local LOCALB_DEFAULT = 255

local OTHERA_DEFAULT = 200
local OTHERR_DEFAULT = 50
local OTHERG_DEFAULT = 255
local OTHERB_DEFAULT = 50



--[[CVAR INITIALIZATION]]


-- Map settings

sConvar = CreateClientConVar("minimap_icon_scale", SCALE_DEFAULT, true)
zConvar = CreateClientConVar("minimap_zoom", ZOOM_DEFAULT, true)
xConvar = CreateClientConVar("minimap_xroot", XROOT_DEFAULT, true)
yConvar = CreateClientConVar("minimap_yroot", YROOT_DEFAULT, true)
rConvar = CreateClientConVar("minimap_radius", RADIUS_DEFAULT, true)
aConvar = CreateClientConVar("minimap_back_alpha", ALPHA_DEFAULT, true)

-- Colors
localA = CreateClientConVar("minimap_local_a", LOCALA_DEFAULT, true)
localR = CreateClientConVar("minimap_local_r", LOCALR_DEFAULT, true)
localG = CreateClientConVar("minimap_local_g", LOCALG_DEFAULT, true)
localB = CreateClientConVar("minimap_local_b", LOCALB_DEFAULT, true)

otherA = CreateClientConVar("minimap_other_a", OTHERA_DEFAULT, true)
otherR = CreateClientConVar("minimap_other_r", OTHERR_DEFAULT, true)
otherG = CreateClientConVar("minimap_other_g", OTHERG_DEFAULT, true)
otherB = CreateClientConVar("minimap_other_b", OTHERB_DEFAULT, true)


local function resetMinimap() 
    sConvar:SetFloat(SCALE_DEFAULT)
    zConvar:SetFloat(ZOOM_DEFAULT)
    xConvar:SetFloat(XROOT_DEFAULT)
    yConvar:SetFloat(YROOT_DEFAULT)
    rConvar:SetFloat(RADIUS_DEFAULT)
    aConvar:SetFloat(ALPHA_DEFAULT)

    localA:SetInt(LOCALA_DEFAULT)
    localR:SetInt(LOCALR_DEFAULT)
    localG:SetInt(LOCALG_DEFAULT)
    localB:SetInt(LOCALB_DEFAULT)

    otherA:SetInt(OTHERA_DEFAULT)
    otherR:SetInt(OTHERR_DEFAULT)
    otherG:SetInt(OTHERG_DEFAULT)
    otherB:SetInt(OTHERB_DEFAULT)
end

concommand.Add("minimap_reset", resetMinimap, nil, "resets the minimap to its default settings", 0)



--[[UTILITIES PANEL]]--


hook.Add("AddToolMenuCategories", "MinimapCategory", function()
    spawnmenu.AddToolCategory("Utilities", "Minimap", "#Minimap")
end)

hook.Add("PopulateToolMenu", "MinimapSettings", function()
	spawnmenu.AddToolMenuOption("Utilities", "Minimap", "Minimap_Menu", "Settings", "", "", function(panel)
		panel:Clear()
        panel:NumSlider("Map X Position", "minimap_xroot", 0, 1, 2  )
		panel:NumSlider("Map Y Position", "minimap_yroot", 0, 1, 2)
        panel:NumSlider("Map Radius", "minimap_radius", 0, 1, 2)

        panel:NumSlider("Icon Scale", "minimap_icon_scale", 0, 5, 2)
        panel:NumSlider("Zoom", "minimap_zoom", 0, 4, 2)


        panel:NumSlider("Background Alpha", "minimap_back_alpha", 0, 255, 0)

        -- Color mixer for the local player's icon color & cvars below
        local localColorMixer = vgui.Create("DColorMixer", panel)
        localColorMixer:Dock(TOP)
        localColorMixer:DockMargin(10, 25, 10, 0)
        localColorMixer:SetLabel("Local Player Color")

        localColorMixer:SetConVarA("minimap_local_a")
        localColorMixer:SetConVarR("minimap_local_r")
        localColorMixer:SetConVarG("minimap_local_g")
        localColorMixer:SetConVarB("minimap_local_b")

        -- Color mixer for the other players' icon color & cvars below
        local otherColorMixer = vgui.Create("DColorMixer", panel)
        otherColorMixer:Dock(TOP)
        otherColorMixer:DockMargin(10, 25, 10, 10)
        otherColorMixer:SetLabel("Other Player Color")

        otherColorMixer:SetConVarA("minimap_other_a")
        otherColorMixer:SetConVarR("minimap_other_r")
        otherColorMixer:SetConVarG("minimap_other_g")
        otherColorMixer:SetConVarB("minimap_other_b")

        -- Reset button
        panel:Button("Reset to Defaults", "minimap_reset")

	end )
end )
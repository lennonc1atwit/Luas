local version = "1.1.1"
local version_addr = "https://raw.githubusercontent.com/lennonc1atwit/Luas/master/Epacs%20Tweaks/version.txt"
local script_addr = "https://raw.githubusercontent.com/lennonc1atwit/Luas/master/Epacs%20Tweaks/Core.lua"
local script_name = GetScriptName()

local version_http = http.Get(version_addr)
version_http = string.gsub(version_http, "\n", "")

if version_http ~= version then
    local new_script_raw = http.Get(script_addr)
    local old_script = file.Open(script_name, "w");
    old_script:Write(new_script_raw);
    old_script:Close();
    print("Epacs Updated")
end

-- The God function... this thing is very handy, i would like to be able to modify properties like parent of objects though
local function ModifyChildren(obj, func)
    for child in obj:Children() do
        func(child)
        ModifyChildren(child, func)
	end
end

-- Globals
local local_player = entities.GetLocalPlayer() 
local choked = 0
local tick_base = 0
-- Cache to store variables we want between callback calls
local cache = {} 
-- Tables for gui management
local blend_table = {"esp.chams.local.visible.clr", "esp.chams.local.occluded.clr", "esp.chams.ghost.occluded.clr", "esp.chams.ghost.visible.clr"}
local doublefire_table = {"rbot.accuracy.weapon.shared.doublefire","rbot.accuracy.weapon.pistol.doublefire", "rbot.accuracy.weapon.hpistol.doublefire", "rbot.accuracy.weapon.smg.doublefire", "rbot.accuracy.weapon.rifle.doublefire", "rbot.accuracy.weapon.shotgun.doublefire", "rbot.accuracy.weapon.asniper.doublefire", "rbot.accuracy.weapon.lmg.doublefire"}

-- Clearing all of enemy esp and adding it back just to add 1 option
local enemyOverlayRef = gui.Reference("Visuals", "Overlay", "Enemy")

cache.overlay_settings = {} -- add a cache index for our saved values
ModifyChildren(enemyOverlayRef, function(obj)
    if obj:GetName() ~= "" then
        cache.overlay_settings[obj:GetName()] = obj:GetValue()
        obj:SetDisabled(true)
        obj:SetInvisible(true)
        obj:SetValue(false or "Off")
    end
end)

-- Visible only esp settings
local visibleOverlayBox = gui.Groupbox(gui.Reference("Visuals", "Overlay"), "", 224,336,192,0)
local enemyBox = gui.Combobox(visibleOverlayBox, "epacS.overlay.enemy.box", "Box", "Off", "Outlined", "Normal")
local enemyBoxColor = gui.ColorPicker(enemyBox, "epacS.overlay.enemy.box.clr", "", gui.GetValue("esp.overlay.enemy.box.clr"))
local enemyName = gui.Checkbox(visibleOverlayBox, "epacS.overlay.enemy.name", "Name", false)
local enemySkeleton = gui.Checkbox(visibleOverlayBox, "epacS.overlay.enemy.skeleton", "Skeleton", false)
local enemySkeletonColor = gui.ColorPicker(enemySkeleton, "epacS.overlay.enemy.skeleton.clr", "Visible", gui.GetValue("esp.overlay.enemy.skeleton.clr"))
local enemyHealth = gui.Multibox(visibleOverlayBox, "Health")
local enemyHealthBar = gui.Checkbox(enemyHealth, "epacS.overlay.enemy.health.bar", "Bar", false)
local enemyHealthNum = gui.Checkbox(enemyHealth, "epacS.overlay.enemy.health.num", "Number", false)
local enemyArmor = gui.Checkbox(visibleOverlayBox, "epacS.overlay.enemy.armor", "Armor", false)
local enemyWeapon = gui.Combobox(visibleOverlayBox,"epacS.overlay.enemy.weapon", "Weapon", "Off", "Name")
local enemyAmmo = gui.Checkbox(visibleOverlayBox, "epacS.overlay.enemy.ammo", "Ammo", false)
local enemyAmmoClr = gui.ColorPicker(enemyAmmo, "epacS.overlay.enemy.ammo.clr", "", 0, 83, 166, 255)
--[[local enemyFlags = gui.Multibox(visibleOverlayBox, "Flags")
    local flagDefusing = gui.Checkbox(enemyFlags, "epacS.overlay.enemy.flags.defusing", "Defusing", false)
    local flagDefusing = gui.Checkbox(enemyFlags, "epacS.overlay.enemy.flags.plant", "Planting", false)
    local flagDefusing = gui.Checkbox(enemyFlags, "epacS.overlay.enemy.flags.scope", "Scoped", false)
    local flagDefusing = gui.Checkbox(enemyFlags, "epacS.overlay.enemy.flags.reload", "Reloading", false)
    local flagDefusing = gui.Checkbox(enemyFlags, "epacS.overlay.enemy.flags.flash", "Flashed", false)
    local flagDefusing = gui.Checkbox(enemyFlags, "epacS.overlay.enemy.flags.defusekit", "Has Defuser", false)
    local flagDefusing = gui.Checkbox(enemyFlags, "epacS.overlay.enemy.flags.c4", "Has C4", false)]]
local enemyMoney = gui.Checkbox(visibleOverlayBox, "epacS.overlay.enemy.money", "Money", false)
local enemyEspVisibility = gui.Combobox(gui.Reference("Visuals", "Overlay"), "epacS.overlay.enemy.visibility", "", "Always", "Visible", "Spotted + Visible")
-- Various Visuial Tweaks
local visTwesksGroupbox = gui.Groupbox( gui.Reference("Visuals", "Local"), "Visuals Tweaks", 328, 220, 296, 0)
local blendScoped = gui.Checkbox(visTwesksGroupbox, "epacS.scopeblend", "Blend On Scope", false)
local blendPercent = gui.Slider(visTwesksGroupbox, "epacS.blendpercent", "Blend Percentage", 25, 0, 100);
local dynamicSmoothing = gui.Checkbox(visTwesksGroupbox, "epacS.dynamicmodel", "Better Ghost Smoothing", false)
local firstPersonGrenade = gui.Checkbox(visTwesksGroupbox, "epacS.firstpersongrenade", "Frist Person On Grenade (sv_cheats bypass)", false);
local thirdpersonKey = gui.Keybox(visTwesksGroupbox, "epacS.thirdpersonkey", "Third Person Key", 97)
local dtIndicator = gui.Checkbox(visTwesksGroupbox, "epacS.doublefire", "Double Fire Indicator", false)
gui.SetValue("misc.bypasscheats", false)
-- Fakelag trigger fixes
local fakelagRef = gui.Reference("Misc", "Enhancement", "Fakelag")
local triggerMultibox = gui.Multibox(fakelagRef, "Conditions")
local triggerPeek = gui.Checkbox(triggerMultibox, "epacS.conditions.peek", "Peek", false)
local triggerStanding = gui.Checkbox(triggerMultibox, "epacS.conditions.standing", "While Standing", false)
local triggerMoving = gui.Checkbox(triggerMultibox, "epacS.conditions.moving", "While Moving", false)
local triggerAir = gui.Checkbox(triggerMultibox, "epacS.conditions.air", "While In Air", false)
local movingThreshold = gui.Slider(fakelagRef, "epacS.movingvelocity", "Moving Velocity", 2, 2, 250)
-- Ragebot fixes
local movementRef = gui.Reference("Ragebot", "Accuracy", "Movement")
local weaponRef = gui.Reference("Ragebot", "Accuracy", "Weapon")
local jumpScoutFix = gui.Checkbox(movementRef, "espacS.scout.jumpfix", "Jump-Scout Fix", false)
local jumpScoutHitchance = gui.Slider(movementRef, "espacS.scout.jumphitchance", "Jump-Scout Hitchance", 33, 0, 100)
local dtGlobalToggle = gui.Keybox(weaponRef, "epacs.doubletap.key", "Double Tap Toggle", 0)
local dtGlobalToggleMode = gui.Combobox(weaponRef, "epacs.doubletap.mode", "Double Tap Mode", "Shift", "Rapid")
local dtRechargeDelay = gui.Slider(weaponRef, "epacs.doubletap.delay", "Recharge Delay", 0, 0, 2, 0.05)
-- Gui finishing touches
gui.Reference("Misc", "Enhancement", "Fakelag", "Conditions"):SetInvisible(true)

dtRechargeDelay:SetDescription("Delay in seconds before double fire attempts to recharge.")
jumpScoutHitchance:SetDescription("Modify hitchance when jump scouting with fix.")
movingThreshold:SetDescription("Minimum threshold for moving fakelag to trigger.")
movingThreshold:SetDescription("Minimum threshold for moving fakelag to trigger.")
firstPersonGrenade:SetDescription("Toggles first person when holding grenades.")
dynamicSmoothing:SetDescription("Toggles smoothing based on choked ticks.")
thirdpersonKey:SetDescription("Key to toggle perspective for nade fix.")
triggerPeek:SetDescription("Lag your model behind wall when peeking.")
triggerPeek:SetDescription("Lag your model behind wall when peeking.")
jumpScoutFix:SetDescription("Disable autostrafer when jump scouting.")
dtGlobalToggle:SetDescription("Toggle double fire on all weapons.")
dtGlobalToggleMode:SetDescription("Select mode for double fire.")
enemyMoney:SetDescription("Draw amount of money player has.")
triggerMultibox:SetDescription("Configure fakelag options.")
triggerMultibox:SetDescription("Configure fakelag options.")
blendScoped:SetDescription("Lower model alpha when scoped.")
enemyAmmo:SetDescription("Amount of ammo left in weapon.")
enemyArmor:SetDescription("Indicate helmet and kevlar.")
enemyHealth:SetDescription("Configure health options.")
enemyBox:SetDescription("Draw 2D box around entity.")
enemySkeleton:SetDescription("Draw player skeleton.")
enemyWeapon:SetDescription("Draw weapon of player.")
enemyName:SetDescription("Draw entity name.")
enemyEspVisibility:SetWidth(160)
enemyEspVisibility:SetPosX(240)
enemyEspVisibility:SetPosY(30)
enemyBoxColor:SetPosY(-48)
enemyBox:SetPosY(-48)

ModifyChildren(weaponRef, function(obj)
    if string.match(obj:GetName(), "Double Fire") then 
        obj:SetInvisible(true)
    end
end)

local function getBoundingBox(entity)
	local origin = entity:GetAbsOrigin();
	
	local mins = entity:GetMins() + origin;
	local maxs = entity:GetMaxs() + origin;

    local points = {}
    table.insert(points, Vector3(mins.x, mins.y, mins.z))
	table.insert(points, Vector3(mins.x, mins.y, mins.z))
	table.insert(points, Vector3(mins.x, maxs.y, mins.z))
	table.insert(points, Vector3(maxs.x, maxs.y, mins.z))
	table.insert(points, Vector3(maxs.x, mins.y, mins.z))
	table.insert(points, Vector3(maxs.x, maxs.y, maxs.z))
	table.insert(points, Vector3(mins.x, maxs.y, maxs.z))
	table.insert(points, Vector3(mins.x, mins.y, maxs.z))
	table.insert(points, Vector3(maxs.x, mins.y, maxs.z))
	
    return points;
end

local function isVisible(entity)
    local points = getBoundingBox(entity)
    local src = local_player:GetAbsOrigin() + local_player:GetPropVector( "localdata", "m_vecViewOffset[0]" )
    
    for i, dst in ipairs(points) do
        if engine.TraceLine(src, dst, 0xFFFFFFFF).fraction >= .9 then
            return true
        end
    end

    return false
end

local function HandleDoubleTap()
    -- Rehcarge reset
    if cache.next_recharge and (cache.next_recharge < globals.CurTime() or not cache.double_fire)then
        cache.next_recharge = nil
    end

    -- Double fire toggle
    if dtGlobalToggle:GetValue() ~= 0 and input.IsButtonPressed(dtGlobalToggle:GetValue()) then
        cache.double_fire = not cache.double_fire
    end
    
    -- Get doubletap mode
    set_mode = dtGlobalToggleMode:GetValue() + 1
    -- check for toggle and recharge delay
    if not cache.double_fire or (cache.next_recharge and globals.CurTime() < cache.next_recharge) then
        set_mode = 0
    end
    -- Set vars
    for i, varname in ipairs(doublefire_table) do
        gui.SetValue(varname, set_mode)
    end

    -- Store fakelag setting
    if not cache.fakelag then 
        cache.fakelag = gui.GetValue("misc.fakelag.enable")
    end
    -- Disable fakelag while recharging
    if cache.next_recharge then
            gui.SetValue("misc.fakelag.enable", false)
    elseif cache.fakelag then
        gui.SetValue("misc.fakelag.enable", cache.fakelag)
        cache.fakelag = nil
    end

    -- Double fire Indicator 
    if dtIndicator:GetValue() and local_player:IsAlive() then
        local sw, sh = draw.GetScreenSize()
        local width, height = 130, 18
        local offset = 0.05 * sh + 9
        local x1, y1 = sw/2 - width/2 , sh - offset
        local x2, y2 = sw/2 + width/2 , sh - offset + height
        -- backround rect
        draw.Color(51,55,60,255)
        draw.RoundedRectFill(x1,y1,x2,y2,5)
        -- Bar percentage
        local string = "SHIFT"
        if cache.next_recharge then
            local percent = 1 - (cache.next_recharge - globals.CurTime()) / dtRechargeDelay:GetValue()
            local barWidth = 130 * percent
            local bx1, by1 = sw/2 - barWidth/2 , sh - offset
            local bx2, by2 = sw/2 + barWidth/2 , sh - offset + height

            local val = percent * 255;
            draw.Color(255 - val,val,0)
            draw.RoundedRectFill(bx1,by1,bx2,by2,5)
            draw.Color(0,0,0,255)
            draw.RoundedRect(bx1,by1,bx2,by2,5)

            string = "DELAY"
        elseif not cache.double_fire then
            string = "OFF"
        end
        -- Outline
        draw.Color(0,0,0,255)
        draw.RoundedRect(x1,y1,x2,y2,5)
        draw.SetFont(draw.CreateFont("tomah", 14, 551))
        local tw, th = draw.GetTextSize(string)
        -- Text
        draw.Color(255,255,255,255)
        draw.TextShadow(x1 + width/2 - tw/2,y1 + height/2 - th/2, string)
    end     
end

callbacks.Register("Draw", function()
    local_player = entities.GetLocalPlayer()

    local drawFont = draw.CreateFont("Tahoma", 24, 551)
    draw.SetFont(drawFont)


    -- Reset states if we are dead or dont exist
    if not local_player or not local_player:IsAlive() then
        -- Reset thirdperson
        client.Command("firstperson", true);
        -- Reset jump scout states
        if cache.autostrafe_state then 
            gui.SetValue("misc.strafe.enable", cache.autostrafe_state) 
            cache.autostrafe_state = nil
        end
        if cache.scout_hitchance then 
            gui.SetValue("rbot.accuracy.weapon.scout.hitchance", cache.scout_hitchance)
            cache.scout_hitchance = nil
        end
    end

    if local_player then
        cache.active_weapon = local_player:GetPropEntity("m_hActiveWeapon")

        -- Blend on scope
        if blendScoped:GetValue() and (cache.active_weapon:GetWeaponType() == 3 or cache.active_weapon:GetWeaponType() == 5) and cache.active_weapon:GetPropInt("m_zoomLevel") ~= 0 then
            -- Save alphas to resore
            if not cache.local_alphas then
                cache.local_alphas = {}
                for i, var in ipairs(blend_table) do
                    local r, g, b, a = gui.GetValue(var)
                    table.insert(cache.local_alphas, a)
                end
            end

            -- Set all the alphas
            for i, var in ipairs(blend_table) do
                local r, g, b, a = gui.GetValue(var)
                gui.SetValue(var, r, g, b, cache.local_alphas[i] * ((100-blendPercent:GetValue()) / 100))
            end

        elseif cache.local_alphas then
            -- restore on unscope and clear table
            for i, var in ipairs(blend_table) do
                local r, g, b, a = gui.GetValue(var)
                gui.SetValue(var, r, g, b, cache.local_alphas[i])
            end
            cache.local_alphas = nil
        end

        -- smoothes model when extra fakelag is added
        if dynamicSmoothing:GetValue() then
            if choked > 1 then
                gui.SetValue("esp.local.smoothghost", false);
            else
                gui.SetValue("esp.local.smoothghost", true);
            end
        end

        -- First person grenade stuff
        if input.IsButtonPressed(thirdpersonKey:GetValue()) then
            thirdperson_active = not thirdperson_active;
        end

        if firstPersonGrenade:GetValue() and local_player then
            gui.Reference("Visuals", "Local", "Camera", "Third Person Enable"):SetDisabled(true)
            gui.Reference("Visuals", "Local", "Camera", "Third Person Enable"):SetValue(false)
            if cache.active_weapon:GetWeaponType() == 9 or not local_player:IsAlive() then
                client.Command("firstperson", true);
            else
                if thirdperson_active then
                    client.Command("thirdperson", true);
                end
            end
        end

        -- Used by fakelag and jumpscout fixes
        local vx = local_player:GetPropFloat("localdata", "m_vecVelocity[0]");
        local vy = local_player:GetPropFloat("localdata", "m_vecVelocity[1]");
        local velocity = math.sqrt(vx^2 + vy^2);

        -- Fakelag triggers fixes
        if velocity >= movingThreshold:GetValue() and triggerMoving:GetValue() then
            gui.SetValue("misc.fakelag.condition.moving", true);
        else
            gui.SetValue("misc.fakelag.condition.moving", false);
        end
        gui.SetValue("misc.fakelag.condition.standing", triggerStanding:GetValue())
        gui.SetValue("misc.fakelag.condition.peek", triggerPeek:GetValue())
        gui.SetValue("misc.fakelag.condition.inair", triggerAir:GetValue())

        -- Jump scout fix and hit chance
        if jumpScoutFix:GetValue() then
            local flags = local_player:GetPropInt("m_fFlags")

            if cache.active_weapon:GetName() == "weapon_ssg08" then
                -- Saves state of auto strafer to restore
                if not cache.autostrafe_state then
                    cache.autostrafe_state = gui.GetValue("misc.strafe.enable")
                end
                -- Saves scout hitchance
                if not cache.scout_hitchance then
                    cache.scout_hitchance = gui.GetValue("rbot.accuracy.weapon.scout.hitchance")
                end

                -- Disables and re-enables autostrafer
                -- You can change this threshold if you'd like
                if velocity > 5 then
                    gui.SetValue("misc.strafe.enable", cache.autostrafe_state)
                else
                    gui.SetValue("misc.strafe.enable", false)
                end

                -- Sets in air hitchance and restores it after
                if bit.band(flags, 1) == 0 then
                    gui.SetValue("rbot.accuracy.weapon.scout.hitchance", jumpScoutHitchance:GetValue())
                else
                    gui.SetValue("rbot.accuracy.weapon.scout.hitchance", cache.scout_hitchance)
                    cache.scout_hitchance = nil
                end

            else
                -- Resets strafe state
                if cache.autostrafe_state then
                    gui.SetValue("misc.strafe.enable", cache.autostrafe_state)
                end
                cache.autostrafe_state = nil
            end
        end

        HandleDoubleTap()
    end

    -- Esp Logic
    if cache.last_mode ~= enemyEspVisibility:GetValue() then
        if enemyEspVisibility:GetValue() == 0 then
            if cache.overlay_settings then
                ModifyChildren(enemyOverlayRef, function(obj)
                    if obj:GetName() ~= "" then
                        obj:SetDisabled(false)
                        obj:SetInvisible(false)
                        obj:SetValue(cache.overlay_settings[obj:GetName()])
                    end
                end)
                cache.overlay_settings = nil
            end
            visibleOverlayBox:SetInvisible(true)
        elseif not cache.overlay_settings then
            cache.overlay_settings = {}
            ModifyChildren(enemyOverlayRef, function(obj)
                if obj:GetName() ~= "" then
                    cache.overlay_settings[obj:GetName()] = obj:GetValue()
                    obj:SetDisabled(true)
                    obj:SetInvisible(true)
                    obj:SetValue(false or "Off")
                end
            end)
            visibleOverlayBox:SetInvisible(false)
        end
        cache.last_mode = enemyEspVisibility:GetValue()
    end
end)

callbacks.Register("DrawESP", function(espBuilder)
    local_player = entities.GetLocalPlayer()
    local entity = espBuilder:GetEntity()

    if enemyEspVisibility:GetValue() == 0 then return end

    --Team check and visibility mode checks
    local visible = isVisible(entity) or (entity:GetProp("m_bSpotted") == 1 and enemyEspVisibility:GetValue() == 2) or enemyEspVisibility:GetValue() == 0
    local team = entity:IsAlive() and entity:GetTeamNumber() ~= local_player:GetTeamNumber()
    if visible and team then
        -- Box
        local r, g, b, a = 255, 255, 255, 255

        if enemyBox:GetValue() ~= 0 then
            local rect = {espBuilder:GetRect()}
            r, g, b, a = enemyBoxColor:GetValue()
            draw.Color(r, g, b, a)
            draw.OutlinedRect(rect[1], rect[2], rect[3], rect[4])
            if enemyBox:GetValue() == 1 then
                draw.Color(0, 0, 0, a)
                draw.OutlinedRect(rect[1]+1, rect[2]+1, rect[3]-1, rect[4]-1)
                draw.OutlinedRect(rect[1]-1, rect[2]-1, rect[3]+1, rect[4]+1)
            end
        end

        -- Name
        if enemyName:GetValue() then
            espBuilder:AddTextTop(entity:GetName())
        end

        -- Skeleton (not really though)
        if enemySkeleton:GetValue() then
            r, g, b, a = enemySkeletonColor:GetValue()
            draw.Color(r, g, b, a)

            local hitboxes = {}
            for index = 0, 19 do
                local vec = entity:GetHitboxPosition(index)
                table.insert(hitboxes, vec)            
            end
            local t = {{1, 2}, {2,7}, {7, 6}, {6, 5}, {5, 4}, {4, 3}, {3, 9}, {3, 8}, {9, 11}, {8, 10}, {11, 13}, {10, 12}, {7, 18}, {18, 19}, {19, 15}, {7, 16}, {16, 17}, {17, 14}}
            for i = 1, #t do
                local connection = t[i]

                local x1, y1 = client.WorldToScreen(hitboxes[connection[1]])
                local x2, y2 = client.WorldToScreen(hitboxes[connection[2]])
            
                if x1 and y1 and x2 and y2 then
                    draw.Line(x1, y1, x2, y2)
                end
            end

        end

        -- Health bar/number
        if enemyHealthBar:GetValue() then
            local health = entity:GetHealth()
            espBuilder:Color(math.floor(255 - health * 2.55), math.floor(health * 2.55), 0, 255)
            espBuilder:AddBarLeft(health/100)
        end
        if enemyHealthNum:GetValue() then
            espBuilder:Color(255, 255, 255, 255)
            espBuilder:AddTextLeft(entity:GetHealth())
        end

        -- Armor
        if enemyArmor:GetValue() then
            espBuilder:Color(255, 255, 255, 255)

            local s = ""
            if entity:GetPropInt("m_bHasHelmet") == 1 then
                s = "H"
            end
            if entity:GetPropInt("m_ArmorValue") > 0 then
                s = s .. "K"
            end

            espBuilder:AddTextRight(s)
        end

        -- Weapon name
        local esp_active_weapon = entity:GetPropEntity("m_hActiveWeapon")
        if enemyWeapon:GetValue() ~= 0 then
            espBuilder:Color(255,255,255,255)
            local weapon_name = esp_active_weapon:GetClass()

            if weapon_name == "CDeagle" and esp_active_weapon:GetWeaponID() == 64 then
                weapon_name = "R8"
            end

            weapon_name = weapon_name:gsub("CWeapon", "")
            weapon_name = weapon_name:gsub("CKnife", "Knife")

            espBuilder:AddTextBottom(weapon_name)
        end

        -- Ammo
        if enemyAmmo:GetValue() then
            local max_ammos = {7, 30, 20, 20, 0, 0, 30, 30, 10, 25, 20, 0, 35, 100, 0, 30, 30, 18, 50, 0, 0, 0, 30, 25, 7, 64, 5, 150, 7, 18, 0, 13, 30, 30, 8, 13, 0, 20, 30, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 25, 12, 0, 12, 8};
            local ammo = esp_active_weapon:GetPropInt("m_iClip1")
            local max_ammo = max_ammos[esp_active_weapon:GetWeaponID()]

            if max_ammo then
                r,g,b,a = enemyAmmoClr:GetValue()
                espBuilder:Color(r,g,b,a)
                espBuilder:AddBarBottom(ammo/max_ammo)
            end
        end

        -- Flags, if someone wants to contribute code plesase do i really dont feel like doing this
            -- Defusing
            -- Planting
            -- Scoped
            -- Reloading
            -- Flashed
            -- Has Defuser
            -- Has C4

        -- Money
        if enemyMoney:GetValue() then
            local money = entity:GetProp("m_iAccount");
            espBuilder:Color(0,255,0,255)
            espBuilder:AddTextRight("$"..money)
        end

    end
end)

callbacks.Register("CreateMove", function(cmd) 
    if cmd.sendpacket then
        choked = 0
    else
        choked = choked + 1
    end

    if local_player then
        local temp = local_player:GetPropInt("localdata", "m_nTickBase")
        
        if cache.current_shot and math.abs(temp - cache.tick_base) > 6 and dtRechargeDelay:GetValue() > 0 then
            cache.next_recharge = globals.CurTime() + dtRechargeDelay:GetValue()
            cache.current_shot = nil
        end

        cache.tick_base = temp
    end
end)

callbacks.Register("FireGameEvent", function(event) 
    local curtime = globals.CurTime()
    if event:GetName() == "weapon_fire" then
        if (client.GetPlayerIndexByUserID(event:GetInt('userid')) == client.GetLocalPlayerIndex()) then
            cache.current_shot = cache.active_weapon:GetPropFloat("m_fLastShotTime")
        end
    elseif event:GetName() == "player_connect_full" then
        gui.SetValue("misc.bypasscheats", true)
    end
end)

-- Unload so i dont fuck up people cfg's
callbacks.Register("Unload", function()
    -- Thirdperson reset
    gui.Reference("Visuals", "Local", "Camera", "Third Person Enable"):SetDisabled(false)
    -- Fakelag Reset
    gui.Reference("Misc", "Enhancement", "Fakelag", "Conditions"):SetInvisible(false);
    if cache.fakelag then gui.SetValue("misc.fakelag.enable", cache.fakelag) end
    -- Reset scout and autostrafer
    if cache.autostrafe_state then gui.SetValue("misc.strafe.enable", cache.autostrafe_state) end
    if cache.scout_hitchance then gui.SetValue("rbot.accuracy.weapon.scout.hitchance", cache.scout_hitchance) end
    -- Setting dt stuff to visible
    ModifyChildren(weaponRef, function(obj)
        obj:SetInvisible(false)
    end)
    -- Reset chams
    if cache.local_alphas then
        for i, var in ipairs(blend_table) do
            local r, g, b, a = gui.GetValue(var)
            gui.SetValue(var, r, g, b, cache.local_alphas[i])
        end
    end
    -- Restoring enemy overlay
    if cache.overlay_settings then
        ModifyChildren(enemyOverlayRef, function(obj)
            if obj:GetName() ~= "" then
                obj:SetDisabled(false)
                obj:SetInvisible(false)
                obj:SetValue(cache.overlay_settings[obj:GetName()])
            end
        end)
    end
    visibleOverlayBox:SetInvisible(true)
end)

client.AllowListener("weapon_fire")
client.AllowListener("player_connect_full")

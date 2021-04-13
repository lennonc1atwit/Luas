local installed = false
file.Enumerate(function(filename)
    if filename == "Libraries/Notify" then
        installed = true;
    end;
end)

if not installed then
    local script = http.Get("https://raw.githubusercontent.com/lennonc1atwit/Luas/master/Notify/Core.lua");
    file.Write("Libraries/Notify.lua", script);
end

local function require(filename)
    local res = file.Open(filename..".lua", "r")
    if res then
        local buf = res:Read()
        res:Close()
        return load(buf, filename)()
    end
    return nil
end

require "Libraries/Notify"

local local_player = entities.GetLocalPlayer()

local Color = {
    red = {r = 255, g = 0, b  = 0, a = 255},
    green = {r = 0, g = 255, b  = 0, a = 255},
    yellow = {r = 255, g = 255, b  = 0, a = 255},
    white = {r = 255, g = 255, b  = 255, a = 255},
}

local Cache = {
    weapon_name = "",
    bullet_impact = {},
    player_hurt = {},
    target = nil,
    view_angles = {
        [1] = nil,
        [2] = nil
    }
}

local Hit_Groups = {"GENERIC", "HEAD", "CHEST", "STOMACH", "LEFT ARM", "RIGHT ARM", "LEFT LEG", "RIGHT LEG", "NECK"}

local Event_Table = {}
--[[ 
    Helpers
]]
local function IsGrenade(weapon_name)
    for i, str in ipairs({"grenade", "flash", "decoy", "molotov", "mine", "charge"}) do
        if string.find(weapon_name, str) then return true end
    end

    return false
end

local function CalculateSpread(view_angles, src, dst)
    local dst_wish = src + view_angles:Forward() * 1000
    
    local AB = src - dst
    local AC = src - dst_wish
    
    local deg = math.deg(math.acos(AB:Dot(AC) / (AB:Length() * AC:Length())))
    
    return deg
end

local function DisplayShot(shot)
    local msg = "nil"
    local clr = Color.white 

    local hit_target = false

    local flags = string.format( "[spread: %.3f deg | weapon: %s ]", shot.spread, shot.weapon)


    -- log each hit in path and mark unintended ones as yellow
    for i, hurt in ipairs(shot.hurts) do 
        local hurt_name = entities.GetByIndex( hurt.index ):GetName()
        local hurt_where = Hit_Groups[hurt.hitgroup]
        msg = string.format("[HURT] %s damage to %s %s (%s hp left) ", hurt.damage, hurt_name, hurt_where, hurt.health)

        clr = Color.yellow

        -- if we killed them look for last target
        local look_for = 0
        if Cache.target and Cache.last_target then
            look_for = hurt.health > 0 and Cache.target:GetIndex() or Cache.last_target:GetIndex()
        end

        if not Cache.target or look_for == hurt.index then
            clr = Color.green
            hit_target = true
        end

        AddToNotify(clr, msg..flags, true)
    end

    -- is we didnt hit anyone and we have a valid target
    if shot.target and (#shot.hurts == 0 or not hit_target) then 
        clr = Color.red
        msg = string.format("[MISS] on %s (%s hp left) ", shot.target:GetName(), shot.target:GetHealth())
        AddToNotify(clr, msg..flags, true)
    end
end
--[[
    Events
]]
Event_Table['weapon_fire'] = function(weapon_fire)
    local player_index = entities.GetByUserID(weapon_fire:GetInt("userid")):GetIndex()

    if player_index ~= local_player:GetIndex() then return end

    local weapon = string.gsub(weapon_fire:GetString("weapon"), "weapon_", "")
    local eye_pos = local_player:GetAbsOrigin() + local_player:GetPropVector("localdata", "m_vecViewOffset[0]")

    table.insert(Cache.bullet_impact, eye_pos)

    Cache.weapon_name = weapon
end

Event_Table["bullet_impact"] = function(bullet_impact)
    local player_index = entities.GetByUserID(bullet_impact:GetInt("userid")):GetIndex()

    if player_index ~= local_player:GetIndex() then return end

    local x = bullet_impact:GetFloat("x")
    local y = bullet_impact:GetFloat("y")
    local z = bullet_impact:GetFloat("z")

    local position = Vector3(x,y,z)

    table.insert(Cache.bullet_impact, position)
end

Event_Table["player_hurt"] = function(player_hurt)
    local attacker_index = entities.GetByUserID(player_hurt:GetInt("attacker")):GetIndex()
	local victim_index = entities.GetByUserID(player_hurt:GetInt("userid")):GetIndex()
    -- we are not attacker
    if attacker_index ~= local_player:GetIndex() then return end

    local _damage = player_hurt:GetInt("dmg_health")
    local _health = player_hurt:GetInt("health")
    local _hitgroup = player_hurt:GetInt("hitgroup")

    table.insert(Cache.player_hurt, {damage = _damage, health = _health, hitgroup = _hitgroup + 1, index = victim_index})
end

local function handleEvents(event)
    local_player = entities.GetLocalPlayer()
    if event then
        local event_name = event:GetName()
        if Event_Table[event_name] then
            Event_Table[event_name](event);
        end
    end
end

--[[
    CreateMove
]]
local function CompileShot(predicted_shot)
    local shot_type = "gunshot"

    if Cache.weapon_name == "weapon_taser" then shot_type = "zeus" end
    if string.find(Cache.weapon_name, "knife") then return end
    if IsGrenade(Cache.weapon_name) then return end
    
    local shot = {
        type = shot_type,
        target = Cache.target,
        weapon = Cache.weapon_name,
        ang = predicted_shot[1],
        pos = predicted_shot[2],
        impacts = Cache.bullet_impact,
        hurts = Cache.player_hurt,
        tick = globals.TickCount(),
        spread = CalculateSpread(predicted_shot[1], predicted_shot[2], Cache.bullet_impact[#Cache.bullet_impact])
    }
    
    DisplayShot(shot)
end

local function HandleViewAngles(cmd)
    -- remove old angles
    local i = 1 
    while i <= 2 do
        if Cache.view_angles[i] and globals.TickCount() - Cache.view_angles[i][3] > 16 then
            Cache.view_angles[i] = nil
        end

        i = i + 1
    end

    -- In attack check for getting shot angles
    if bit.band(cmd.buttons, bit.lshift(1,0)) == bit.lshift(1,0) then
        local shot_pos = local_player:GetAbsOrigin() + local_player:GetPropVector("localdata", "m_vecViewOffset[0]")
        local recoil = local_player:GetPropVector("localdata", "m_Local", "m_aimPunchAngle") * 2
        local shot_angle =  cmd.viewangles

        -- account for recoil
        shot_angle.x = shot_angle.x + recoil.x
        shot_angle.y = shot_angle.y + recoil.y

        -- my best attempt at filtering the correct shot angles and positions
        if Cache.view_angles[1] == nil then
            Cache.view_angles[1] = {shot_angle, shot_pos, globals.TickCount()}
        else
            Cache.view_angles[2] = {shot_angle, shot_pos, globals.TickCount()}
        end
    end

    -- match angles to shots
    if Cache.weapon_name ~= "" then
        -- basic logic for deciding which angle to choose
        local shot = Cache.view_angles[1]
        Cache.view_angles[1] = nil

        if shot == nil then
            shot = Cache.view_angles[2]
            Cache.view_angles[2] = nil
        end

        -- the actual function of the script
        if shot then
            CompileShot(shot)

            -- clear cache shit
            Cache.weapon_name = ""
            Cache.bullet_impact = {}
            Cache.player_hurt = {}
        end
    end
end
--[[
    Target Stuff (BUGGY AS FUCK)
]]
local function UpdateTarget(entity)
    if entity:GetName() then
        Cache.last_target = Cache.target
        Cache.target = entity
    else 
        Cache.last_target = Cache.target
        Cache.target = nil
    end
end
--[[
    Boring Shit
]]
callbacks.Register( "CreateMove", HandleViewAngles)

callbacks.Register( "AimbotTarget", UpdateTarget)

callbacks.Register( "Draw", UpdateNotify)
callbacks.Register( "Draw", DrawNotify)

callbacks.Register( "FireGameEvent", handleEvents)

for k, v in pairs(Event_Table) do
    client.AllowListener(k)
end

gui.Command("clear")

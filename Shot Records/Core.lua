-- some lib stuff thanks to Yukine#4752 from scripting server for this func
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

-- Gui setup
local gui_shot_flags = {}
local flags = {"Spread", "Weapon", "Double Tap", "Hide Shot", "Backtrack"}
local multibox = gui.Multibox(gui.Reference("Misc", "General", "logs"), "Record Flags")

for i, flag in ipairs(flags) do 
    gui_shot_flags[i] = gui.Checkbox(multibox, "shotrecords."..string.gsub(flag, " ", ""), flag, false)
end

local Hit_Groups = {"GENERIC", "HEAD", "CHEST", "STOMACH", "LEFT ARM", "RIGHT ARM", "LEFT LEG", "RIGHT LEG", "NECK"}
local Target = nil

-- Some structures to keep this information mess neater
local ShotEvent = {
    -- 1 being source and #Impacts being dest: Table
    impact_events,
    -- list of players shot hit and info about it: Table
    hurt_events,
    -- if cheat or us shot: Bool
    manual,
    -- weapon that was fired: String
    weapon,
    -- spread of shot: Float
    spread,
    -- if shot was not manual what was cheats target: Entity
    target,
}

local HurtEvent = {
    -- player hurt: Entity
    player,
    -- how much damage was delt: Int
    damage,
    -- how much health remains after: Int
    health,
    -- where was damage delt: Int
    hitgroup
}

function HurtEvent:New(ent, dmg, hp, hg)
    local event = {}

    setmetatable(event, self)
    self.__index = self

    self.player = ent
    self.damage = dmg
    self.health = hp
    self.hitgroup = hg

    return event
end

function ShotEvent:New(impacts, hurts, manual, weapon, spread, target, WIP)
    local event = {}

    setmetatable(event, self)
    self.__index = self

    return event
end

local latest_shot = {}
function DrawSpread(src, dst1, dst2, deg)
    local x, y =   client.WorldToScreen( src  )
    local x1, y1 = client.WorldToScreen( dst1 )
    local x2, y2 = client.WorldToScreen( dst2 )

    draw.Color(255, 0, 0, 255)
    draw.Line(x, y, x1, y1)
    draw.Color(0, 255, 0, 255)
    draw.Line(x, y, x2, y2)
    draw.Color(255, 255, 255, 255)
    draw.Text(x, y, deg)
end

callbacks.Register( "Draw", function() 
    if false and latest_shot[1] then
        DrawSpread(latest_shot[1], latest_shot[2], latest_shot[3], latest_shot[4])
    end
end)

local function CalculateSpread(angle, B, C)
    local A = src + angle:Forward()

    local AB = B - A
    local BC = B - C

    local deg = math.deg(math.acos(AB:Dot(BC) / (AB:Length() * BC:Length())))

    latest_shot = {src, dst, dst_pred, deg}

    return deg
end

local tick_impacts = {}
local tick_hurts = {}
local tick_manual = false
local tick_weapon = ""

local shot_angle = nil
callbacks.Register( "CreateMove", function(cmd)
    local local_player = entities.GetLocalPlayer()

    if bit.band(cmd.buttons, bit.lshift(1,0)) == bit.lshift(1,0) and not input.IsButtonDown(1)then
        local recoil = local_player:GetPropVector("localdata", "m_Local", "m_aimPunchAngle")*2
        shot_angle =  cmd.viewangles
        shot_angle.x = shot_angle.x + recoil.x
        shot_angle.y = shot_angle.y + recoil.y
    end

    if #tick_impacts <= 0 then
        return
    end
    
    local shot_hit = #tick_hurts > 0
    local clr = {r = not shot_hit and 255 or 0, g = shot_hit and 255 or 0, b = 0, a = 255}
    local spread = CalculateSpread(shot_angle, tick_impacts[1], tick_impacts[#tick_impacts])
    
    if shot_hit then
        for i, hurt_event in ipairs(tick_hurts) do
            local msg = string.format( "[HURT] %s for %s in %s (%s hp left) [ spread: %.3f deg | weapon: %s ]", 
                hurt_event.player:GetName(), -- Name
                hurt_event.damage, -- Damage
                Hit_Groups[hurt_event.hitgroup+1], -- Hitgroup
                hurt_event.health, -- Remaining health
                spread, -- Spread
                tick_weapon -- Weapon
            )

            AddToNotify(clr, msg, true)
        end
    elseif not shot_hit and Target and not tick_manual then
        local msg = string.format( "[MISS] on %s [ spread: %.3f | weapon: %s ]", Target:GetName(), spread, tick_weapon)

        AddToNotify(clr, msg, true)
    end

    -- clear tick based vars for next tick
    tick_impacts, tick_hurts, tick_manual, tick_weapon = {}, {}, false, ""
end)

-- Log events to be parsed
callbacks.Register( "FireGameEvent", function(event)
    local local_player = entities.GetLocalPlayer()

    if event then
        if event:GetName() == "weapon_fire" then
            local player = entities.GetByUserID(event:GetInt("userid"))

            -- Check that we are the one that shot
            if player:GetIndex() == local_player:GetIndex() then
                -- Update weapon we fired
                tick_weapon = string.gsub(event:GetString("weapon"), "weapon_", "")

                -- add our position to impacts to use as source vector
                local eye_pos = local_player:GetAbsOrigin() + local_player:GetPropVector("localdata", "m_vecViewOffset[0]")
                
                table.insert(tick_impacts, eye_pos)
            end

            -- check if we are the one the fired
            tick_manual = input.IsButtonDown(1)
        elseif event:GetName() == "bullet_impact" then
            local player = entities.GetByUserID(event:GetInt("userid"))

            -- check that we are the ones who made that whole in the wall
            if player:GetIndex() == local_player:GetIndex() then
                -- add each bullet impact we come across
                local pos = Vector3(event:GetFloat("x"), event:GetFloat("y"), event:GetFloat("z"))
                table.insert(tick_impacts, pos)
            end

        elseif event:GetName() == "player_hurt" then
            local attacker = entities.GetByUserID(event:GetInt("attacker"))
		    local victim = entities.GetByUserID(event:GetInt("userid"))

            -- check that we are attacker and not also victim
            if victim:GetIndex() ~= local_player:GetIndex() and attacker:GetIndex() == local_player:GetIndex() then
                local damage = event:GetInt("dmg_health")
                local health = event:GetInt("health")
                local hitgroup = event:GetInt("hitgroup")

                local hurt_event = HurtEvent:New(victim, damage, health, hitgroup)

                table.insert(tick_hurts, hurt_event)
            end
        end
    end
end)

callbacks.Register( "AimbotTarget", function(entity) 
    Target = entity
end)

callbacks.Register("Draw", UpdateNotify)
callbacks.Register("Draw", DrawNotify)

client.AllowListener("weapon_fire")
client.AllowListener("bullet_impact")
client.AllowListener("player_hurt")



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

local shots = {}

local shot_queue = {}
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
    if #shots > 0 then
        local i = 1
        while i <= #shots do
            local shot = shots[i]
            DrawSpread(shots[i][1], shots[i][2], shots[i][3], shots[i][4])
            if shot[5] + shot[6] <= globals.CurTime() then
                table.remove(shots, i)
            else 
                i = i + 1
            end
        end
    end


    draw.Text(600, 100, "First Shot: "..(shot_queue[1] and "Reg" or "UnReg"))
    draw.Text(600, 115, "Second Shot: "..(shot_queue[2] and "Reg" or "UnReg"))

end)

local function CalculateSpread(angle, B, C)
    local A = B + angle:Forward() * 1000

    local AB = B - A
    local BC = B - C

    local deg = math.deg(math.acos(AB:Dot(BC) / (AB:Length() * BC:Length())))

    table.insert(shots, {B, C, A, deg, globals.CurTime(), 8})

    return deg
end

local tick_impacts = {}
local tick_hurts = {}
local tick_manual = false
local tick_weapon = ""
local tick_last

callbacks.Register( "CreateMove", function(cmd)
    local tick_count = cmd.tick_count
    local local_player = entities.GetLocalPlayer()

    -- log angles of potential shots
    if bit.band(cmd.buttons, bit.lshift(1,0)) == bit.lshift(1,0) and tick_last ~= tick_count then
        -- account for recoil control
        local recoil = local_player:GetPropVector("localdata", "m_Local", "m_aimPunchAngle") * 2
        local shot_angle =  cmd.viewangles
        shot_angle.x = shot_angle.x + recoil.x
        shot_angle.y = shot_angle.y + recoil.y

        local shot_pos = local_player:GetAbsOrigin() + local_player:GetPropVector("localdata", "m_vecViewOffset[0]")

        print("Shot Detected",   cmd.sendpacket, cmd.hasbeenpredicted)

        if shot_queue[1] == nil and shot_queue[2] == nil then
            shot_queue[1] = {shot_angle, shot_pos}
            print("Queue 1 Filled",   tick_count)
        else    
            shot_queue[2] = {shot_angle, shot_pos}
            print("Queue 2 Filled",   tick_count)
        end

        tick_last = tick_count
    end

    -- if we have impacts of a shot this tick match it to an angle
    if #tick_impacts > 0 then 
        print("Shot Impacts Detected", tick_count)

        -- match shot impacts to pos and view angles
        local shot = nil
        if shot_queue[1] ~= nil then
            shot = shot_queue[1]
            shot_queue[1] = nil
        elseif shot_queue[2] ~= nil then
            shot = shot_queue[2]
            shot_queue[2] = nil
        end

        -- if we matched a shot log it
        if shot then 
            print("Matched Ang/Pos to Shot", tick_count)

            local spread = CalculateSpread(shot[1], shot[2], tick_impacts[#tick_impacts])
            
            local shot_hit = #tick_hurts > 0
            local clr = {r = not shot_hit and 255 or 0, g = shot_hit and 255 or 0, b = 0, a = 255}

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
        end
        print("")
        tick_impacts, tick_hurts, tick_manual, tick_weapon = {}, {}, false, ""
    end
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
    if entity:GetName() then
        Target = entity
    end
end)

callbacks.Register("Draw", UpdateNotify)
callbacks.Register("Draw", DrawNotify)

client.AllowListener("weapon_fire")
client.AllowListener("bullet_impact")
client.AllowListener("player_hurt")

gui.Command("clear")



local WEAPON_GROUPBOX_NAMES    = {"Shared", "Zeus", "Pistol", "Heavy Pistol", "Submachine Gun", "Rifle", "Shotgun", "Scout", "Auto Sniper", "Sniper", "Light Machine Gun"}
local WEAPON_SNIPER_CONVERSION = {["weapon_awp"] = "Sniper", ["weapon_g3sg1"] = "Auto Sniper", ["weapon_scar20"] = "Auto Sniper", ["weapon_ssg08"] = "Scout"}
local WEAPON_GROUPBOX_VARNAMES = {"shared", "zeus", "pistol", "hpistol",      "smg",            "rifle", "shotgun", "scout", "asniper",     "sniper", "lmg"}
local WEAPON_TYPE_TO_NAME = {[0] = "Zeus", [1] = "Pistol", [2]= "Submachine Gun", [3] = "Rifle", [4] = "Shotgun", [6] = "Light Machine Gun"}
local PERWEAPON_ELEMENTS = {}

local function CreatePerWeaponCheckbox(parent, varname, name, value, description)
    local ID = #PERWEAPON_ELEMENTS + 1
    PERWEAPON_ELEMENTS[ID] = {}

    if type(parent) == "userdata" then
        for i = 1, 11 do
            local weapon = WEAPON_GROUPBOX_VARNAMES[i]

            local e = gui.Checkbox(parent, weapon.."."..varname, name, value)
            e:SetDescription(description)

            PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] =  {e, parent}
        end
    elseif type(parent) == "table" then -- Multi box parent
        for i = 1, 11 do
            local weapon = WEAPON_GROUPBOX_VARNAMES[i]

            local e = gui.Checkbox(parent[WEAPON_GROUPBOX_NAMES[i]][1], weapon.."."..varname, name, value)
            PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] =  {e, parent[WEAPON_GROUPBOX_NAMES[i]][2]}
        end
    end

    return PERWEAPON_ELEMENTS[ID]
end

local function CreatePerWeaponSlider(parent, varname, name, value, min, max, step, description)
    local ID = #PERWEAPON_ELEMENTS + 1
    PERWEAPON_ELEMENTS[ID] = {}

    for i = 1, 11 do
        local weapon = WEAPON_GROUPBOX_VARNAMES[i]

        local e = gui.Slider(parent, weapon.."."..varname, name, value, min, max, step)
        e:SetDescription(description)

        PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] =  {e, parent}
    end

    return PERWEAPON_ELEMENTS[ID]
end

local function CreatePerWeaponCombobox(parent, varname, name, description, ...) 
    local ID = #PERWEAPON_ELEMENTS + 1
    PERWEAPON_ELEMENTS[ID] = {}
    
    for i = 1, 11 do
        local weapon = WEAPON_GROUPBOX_VARNAMES[i]

        local e = gui.Combobox(parent, weapon.."."..varname, name, ...)
        e:SetDescription(description)

        PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] =  {e, parent}
    end
    
    return PERWEAPON_ELEMENTS[ID]
end

local function CreatePerWeaponMultibox(parent, name, description)
    local ID = #PERWEAPON_ELEMENTS + 1
    PERWEAPON_ELEMENTS[ID] = {}

    for i = 1, 11 do
        local e = gui.Multibox(parent, name)
        PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] =  {e, parent}
        e:SetDescription(description)
    end

    return PERWEAPON_ELEMENTS[ID]
end

local function getActiveWeaponIndex(ref)
    local active_weapon = entities.GetLocalPlayer():GetPropEntity("m_hActiveWeapon")
    local weapon_name = active_weapon:GetName()

    if ref:GetValue() == "\"Shared\"" then
        return "Shared"
    elseif weapon_name == "weapon_revolver" or weapon_name == "weapon_deagle" then -- heavy pistol filter
        return "Heavy Pistol"
    elseif active_weapon:GetWeaponType() == 5 then -- snipers
         return WEAPON_SNIPER_CONVERSION[weapon_name]
    else
        return WEAPON_TYPE_TO_NAME[active_weapon:GetWeaponType()]
    end
end

local function getActiveWeaponVar(ref)
    local index = getActiveWeaponIndex(ref)

    for i = 1, 11 do 
        if WEAPON_GROUPBOX_NAMES[i] == index then
            return WEAPON_GROUPBOX_VARNAMES[i]
        end
    end
end

local function RefreshGUI()
    if gui.Reference("Menu"):IsActive() then
        for ID, group in pairs(PERWEAPON_ELEMENTS) do 
            for key, element in pairs(group) do
                if key == string.gsub(element[2]:GetValue(), "\"", "") then
                    element[1]:SetInvisible(false)
                else 
                    element[1]:SetInvisible(true)
                end
            end
        end
    end
end

local function ShutDown()
    for ID, group in pairs(PERWEAPON_ELEMENTS) do 
        for key, element in pairs(group) do
           element[1]:Remove()
        end
    end
end

callbacks.Register("Draw", RefreshGUI)

--// END OF FRAMEWORK //--
-- This is where the fun begins!
local HSREF = gui.Reference("Ragebot", "Hitscan", "Hitbox Points")

-- Processing Time -> Ragebot, Hitscan, Hitbox Points
local maxproc = CreatePerWeaponSlider(HSREF, "maxprocessingtime", "Max Processing Time", 65, 5, 75, 5, "Lower this value to maintain better FPS.")

-- Percise Hitscan -> Ragebot, Hitscan, Hitbox Points
local percise = CreatePerWeaponCheckbox(HSREF, "precisehitscan", "Precise Hitscan", false, "Enable additional checks when selecting hit points.")

-- Predictive -> Ragebot, Hitscan, Hitbox Points
local predictive = CreatePerWeaponCheckbox(HSREF, "predictive", "Predictive", false, "Wait for higher damage spot when peeking.")

callbacks.Register("Draw", function()

    local localPlayer = entities.GetLocalPlayer()
    if localPlayer and localPlayer:IsAlive() then -- dont do shit when we dead cause we dont need to
        local index = getActiveWeaponIndex(HSREF)
        
        -- Set hitscan vars based on the weapon we are holding if we are holding a valid weapon
        if index then
            gui.SetValue("rbot.hitscan.maxprocessingtime", maxproc[index][1]:GetValue())
            gui.SetValue("rbot.hitscan.precisehitscan", percise[index][1]:GetValue())
            gui.SetValue("rbot.hitscan.predictive", predictive[index][1]:GetValue())
        end
    end
end)


callbacks.Register("Unload", ShutDown)

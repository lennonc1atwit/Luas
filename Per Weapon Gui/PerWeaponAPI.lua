WEAPON_GROUPBOX_NAMES    = {"Shared", "Zeus", "Pistol", "Heavy Pistol", "Submachine Gun", "Rifle", "Shotgun", "Scout", "Auto Sniper", "Sniper", "Light Machine Gun"}
WEAPON_SNIPER_CONVERSION = {["weapon_awp"] = "Sniper", ["weapon_g3sg1"] = "Auto Sniper", ["weapon_scar20"] = "Auto Sniper", ["weapon_ssg08"] = "Scout"}
WEAPON_GROUPBOX_VARNAMES = {"shared", "zeus", "pistol", "hpistol",      "smg",            "rifle", "shotgun", "scout", "asniper",     "sniper", "lmg"}
WEAPON_TYPE_TO_NAME = {[0] = "Zeus", [1] = "Pistol", [2]= "Submachine Gun", [3] = "Rifle", [4] = "Shotgun", [6] = "Light Machine Gun"}
PERWEAPON_ELEMENTS = {}

function CreatePerWeaponCheckbox(ID, parent, varname, name, value, description)
    if not PERWEAPON_ELEMENTS[ID] then
        PERWEAPON_ELEMENTS[ID] = {}
    end

    for i = 1, 11 do
        local weapon = WEAPON_GROUPBOX_VARNAMES[i]

        local e = gui.Checkbox(parent, weapon.."."..varname, name, value)
        e:SetDescription(description)

        if not PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] then
            PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] = {}
        end

        PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] =  {e, parent}
    end
end

function CreatePerWeaponSlider(ID, parent, varname, name, value, min, max, step, description)
    if not PERWEAPON_ELEMENTS[ID] then
        PERWEAPON_ELEMENTS[ID] = {}
    end

    for i = 1, 11 do
        local weapon = WEAPON_GROUPBOX_VARNAMES[i]

        local e = gui.Slider(parent, weapon.."."..varname, name, value, min, max, step)
        e:SetDescription(description)

        if not PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] then
            PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] = {}
        end

        PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] =  {e, parent}
    end
end

function CreatePerWeaponCombobox(ID, parent, varname, name, description, ...) 
    if not PERWEAPON_ELEMENTS[ID] then
        PERWEAPON_ELEMENTS[ID] = {}
    end

    for i = 1, 11 do
        local weapon = WEAPON_GROUPBOX_VARNAMES[i]

        local e = gui.Combobox(parent, varname, name, ...)
        e:SetDescription(description)

        if not PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] then
            PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] = {}
        end

        PERWEAPON_ELEMENTS[ID][WEAPON_GROUPBOX_NAMES[i]] =  {e, parent}
    end
end

function getActiveWeaponIndex(ref)
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

function getActiveWeaponVar(ref)
    local index = getActiveWeaponIndex(ref)

    for i = 1, 11 do 
        if WEAPON_GROUPBOX_NAMES[i] == index then
            return WEAPON_GROUPBOX_VARNAMES[i]
        end
    end
end

function RefreshGUI()
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

function ShutDown()
    for ID, group in pairs(PERWEAPON_ELEMENTS) do 
        for key, element in pairs(group) do
           element[1]:Remove()
        end
    end
end

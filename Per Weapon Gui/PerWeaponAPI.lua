local SUBGROUPBOX_NAMES     = {"Shared", "Zeus", "Pistol", "Heavy Pistol", "Submachine Gun", "Rifle", "Shotgun", "Scout", "Auto Sniper", "Sniper", "Light Machine Gun"}
local SUBGROUPBOX_VAR_NAMES = {"shared", "zeus", "pistol", "hpistol",      "smg",            "rifle", "shotgun", "scout", "asniper",     "sniper", "lmg"}
local ELEMENTS_STORE = {}

PerWeapon = {
    gui = {},

    refresh = function()
        -- Get an element table
        for i, element_table in ipairs(ELEMENTS_STORE) do
        -- Look at each element
            local parent_state = string.gsub(element_table[2]:GetValue(), "\"", "")
            for key, value in pairs(element_table[1]) do
                -- Set disbaled depending on slected weapon
                if key == parent_state then
                    value:SetInvisible(false)
                else 
                    value:SetInvisible(true)
                end
            end
        end
    end,

    shutdown = function()
        for i, element_table in ipairs(ELEMENTS_STORE) do
            for key, value in pairs(element_table[1]) do
                value:Remove()
            end
        end
    end
}

PerWeapon.gui.Checkbox = function(parent, varname, name, value)
    local elements = {}

    for i = 1, 11 do
        local subvarname = SUBGROUPBOX_VAR_NAMES[i]:lower():gsub(" ", "").."."..varname
        elements[SUBGROUPBOX_NAMES[i]] = gui.Checkbox(parent, subvarname, name, value)
    end

    table.insert(ELEMENTS_STORE, {elements, parent})

    return elements
end

PerWeapon.gui.Slider = function(parent, varname, name, value, min, max, step)
    local elements = {}

    for i = 1, 11 do
        local subvarname = SUBGROUPBOX_VAR_NAMES[i]:lower():gsub(" ", "").."."..varname

        -- Check if user gave a step value
        if step then
            elements[SUBGROUPBOX_NAMES[i]] = gui.Slider(parent, subvarname, name, value, min, max, step)
        else
            elements[SUBGROUPBOX_NAMES[i]] = gui.Slider(parent, subvarname, name, value, min, max)
        end
    end

    table.insert(ELEMENTS_STORE, {elements, parent})

    return elements
end

PerWeapon.gui.Keybox = function(parent, varname, name, key)
    local elements = {}

    for i = 1, 11 do
        local subvarname = SUBGROUPBOX_VAR_NAMES[i]:lower():gsub(" ", "").."."..varname
        elements[SUBGROUPBOX_NAMES[i]] = gui.Keybox(parent, subvarname, name, key)
    end

    table.insert(ELEMENTS_STORE, {elements, parent})

    return elements
end

-- I like variable argument counts
PerWeapon.gui.Combobox = function(parent, varname, name, ...)
    local elements = {}

    for i = 1, 11 do
        local subvarname = SUBGROUPBOX_VAR_NAMES[i]:lower():gsub(" ", "").."."..varname
        elements[SUBGROUPBOX_NAMES[i]] = gui.Combobox(parent, varname, name, ...)
    end

    table.insert(ELEMENTS_STORE, {elements, parent})

    return elements
end

PerWeapon.gui.Editbox = function(parent, varname, value)
    local elements = {}

    for i = 1, 11 do
        local subvarname = SUBGROUPBOX_VAR_NAMES[i]:lower():gsub(" ", "").."."..varname
        elements[SUBGROUPBOX_NAMES[i]] = gui.Editbox( parent, varname, value )
    end

    table.insert(ELEMENTS_STORE, {elements, parent})

    return elements
end

PerWeapon.gui.Text = function(parent, text) 
    local elements = {}

    for i = 1, 11 do
        local subvarname = SUBGROUPBOX_VAR_NAMES[i]:lower():gsub(" ", "").."."..varname
        elements[SUBGROUPBOX_NAMES[i]] = gui.Text(parent, text)
    end

    table.insert(ELEMENTS_STORE, {elements, parent})

    return elements
end

PerWeapon.gui.ColorPicker = function(parent, varname, name, r, g, b, a)
    local elements = {}

    for i = 1, 11 do
        local subvarname = SUBGROUPBOX_VAR_NAMES[i]:lower():gsub(" ", "").."."..varname
        elements[SUBGROUPBOX_NAMES[i]] = gui.Text(parent, text)
    end

    table.insert(ELEMENTS_STORE, {elements, parent})

    return elements
end

-- this may need more functionallity 
PerWeapon.gui.Multibox = function (parent, name)
    local elements = {}

    for i = 1, 11 do
        local subvarname = SUBGROUPBOX_VAR_NAMES[i]:lower():gsub(" ", "").."."..varname
        elements[SUBGROUPBOX_NAMES[i]] = gui.Multibox(parent, name)
    end

    table.insert(ELEMENTS_STORE, {elements, parent})

    return elements
end

-- Load API
if not PerWeapon then 
    local script_raw = http.Get("https://raw.githubusercontent.com/lennonc1atwit/Luas/master/Per%20Weapon%20Gui/PerWeaponAPI.lua")
    local temp = file.Open("temp.lua", "w");
    temp:Write(script_raw)
    temp:Close()
    LoadScript("temp.lua")
    file.Delete("temp.lua")
end

-- Gui Elements are returned in a table indexed as:
-- "Shared", "Zeus", "Pistol", "Heavy Pistol", "Submachine Gun", "Rifle", "Shotgun", "Scout", "Auto Sniper", "Sniper", "Light Machine Gun"
-- let me know if a different system would work better
local parent = gui.Reference("legitbot", "Weapon", "Accuracy")
local TestCheckBox = PerWeapon.gui.Checkbox(parent, "testcheckbox", "Test Check Box", false)
local TestComboBox = PerWeapon.gui.Combobox(parent, "testcombobox", "Test Combo Box", "Option 1", "Option 2", "Option 3")

--  Call this each frame or when weapon selection changes
callbacks.Register("Draw", function()
    PerWeapon.refresh()
end)

--  Call this in unload to clean everything up
callbacks.Register("Unload", function() 
    PerWeapon.shutdown()
end)

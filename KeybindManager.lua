local guiBindGroupbox = gui.Groupbox(gui.Reference("Settings", "Advanced"), "Keybind Manager", 328, 16, 296, 0)
local guiEditBox = gui.Editbox(guiBindGroupbox, "", "keybind Enter Box")
local guiBindListBox = gui.Listbox(guiBindGroupbox, "", 100, "")
local guiBindWindow = gui.Window("", "Keybinds", 15, 15, 400, 60)

local binds, bindStrings, bindRaw
local windowTextElements = {}
local Bind = {}

local temp = file.Open("Binds.dat", "a")
temp:Close()

local function BindToString(self)
    return string.format("%s %s %s", self.type, self.key, self.parent)
end

local function CreateBind(bindType, bindKey, guiParent, offState, onState)
    local bindData = setmetatable({
        type = bindType,
        key = bindKey,
        parent = guiParent,
        offstate = offState,
        onstate = onState
        }, Bind
    );

    local newBind = setmetatable({}, {
        __index = function(self, index)
            return bindData[index]
        end,
        __tostring = BindToString
    })

    return newBind
end

-- Validates new binds to make sure they are correct and returns bind data
local function ParseBind(bind)
    local subStrings = {}

    for str in string.gmatch(bind, "%S+") do
        if str == nil then return nil end
        str = string.gsub(str, "\"", "")
        table.insert(subStrings, str)
    end

    -- Check length of arguments to make sure we have enough
    -- Check type of bind for a valid type
    -- Check gui var, This will cause an error with invalid gui objects so we can catch it with pcall
    if #subStrings > 6 or #subStrings < 5 then return nil end
    if subStrings[1] ~= "bindtoggle" and subStrings[1] ~= "bindhold" then return nil end
    gui.GetValue(subStrings[3])

    return CreateBind(subStrings[1], subStrings[2], subStrings[3], subStrings[4], subStrings[5])
end

-- Initalizes script and loads saved binds
local function Init()
    print("KeyBind Manager - Loading Saves Binds")

    local f = file.Open("binds.dat", "r")
    local file = f:Read()
    f:Close()

    local t1, t2, t3 = {}, {}, {}
    for str in string.gmatch(file, "([^,]+)") do
        local bind = ParseBind(str)
        table.insert(t1, bind)
        table.insert(t2, tostring(bind))
        table.insert(t3, str)
    end

    binds, bindStrings, bindRaw = t1, t2, t3
    guiBindListBox:SetOptions(unpack(bindStrings))
    guiEditBox:SetValue("Enter a keybind")

    print(string.format("KeyBind Manager - Loaded %s saved binds!", #t1))
end

if not pcall(Init) then
    print("KeyBind Manager - Error Loading Binds, Corrupt .dat file!")
end

-- Adds a new bind to file and window
local function Addbind()
    local valid, newBind = pcall(ParseBind, guiEditBox:GetValue());
    
    -- Check if string was valid and draw error text if it isnt
    if valid == false or not newBind then
        guiEditBox:SetValue("Invalid Bind, check cheat console for more info.")

        if valid == false then
            print("KeyBind Manager - Error Creating Bind, invalid gui object")
        else
            print("KeyBind Manager - Error Creating Bind, incorrect bind format")
        end

        return
    end

    table.insert(binds, newBind)
    table.insert(bindRaw, guiEditBox:GetValue())
    table.insert(bindStrings, tostring(newBind))

    -- Updates List and file
    local newRaw = ""
    for i, raw in ipairs(bindRaw) do 
        newRaw = newRaw..raw

        if i ~= #bindRaw then
            newRaw = newRaw..","
        end
    end

    local f = file.Open("binds.dat", "w")
    newRaw:gsub("\n", "")
    f:Write(newRaw)
    f:Close()

    guiBindListBox:SetOptions(unpack(bindStrings))
    guiEditBox:SetValue("Enter Another Bind")
end

-- Removes bind from index in list box
local function DeleteBind()
    if #binds == 0 then return end
    local index = guiBindListBox:GetValue() + 1

    print(string.format("KeyBind Manager - %s removed", bindRaw[index]))

    table.remove(binds, index)
    table.remove(bindStrings, index)
    table.remove(bindRaw, index)

    -- Updates list and file
    local newRaw = ""
    for i, raw in ipairs(bindRaw) do 
        newRaw = newRaw..raw

        if i ~= #bindRaw then
            newRaw = newRaw..","
        end
    end

    local f = file.Open("binds.dat", "w")
    f:Write(newRaw)
    f:Close()

    guiBindListBox:SetOptions(unpack(bindStrings))
    guiEditBox:SetValue("Bind Removed")
end

local guiButtonAdd = gui.Button(guiBindGroupbox, "Add", Addbind)
local guiButtonDel = gui.Button(guiBindGroupbox, "Remove", DeleteBind)
local guiBindWindowMode = gui.Combobox(guiBindGroupbox, "keybind.mode", "Keybind Window Mode", "Off", "Active", "All")
guiButtonDel:SetPosY(172)
guiButtonDel:SetPosX(136)

local textSpacing = 20
callbacks.Register("Draw", function()
    -- Clear previous frames text emelents
    for i, textRow in ipairs(windowTextElements) do
        for j, textElement in ipairs(textRow) do
            textElement:Remove()
        end
    end
    windowTextElements = {}
    
    -- Check if window is enabled
    if guiBindWindowMode:GetValue() == 0 then 
        guiBindWindow:SetActive(false) 
        return 
    else
        guiBindWindow:SetActive(true); 
    end

    -- Add new text elements according to mode
    for i, bind in ipairs(binds) do
        local parentValue = gui.GetValue(bind.parent)
        
        if type(parentValue) == "boolean" then
            if parentValue == true then
                parentValue = "On"
            else
                parentValue = "Off"
            end
        end

        local text = {}
        windowTextElements[i] = {}
        -- Check boxes are the only gui element that can be truly off so we only need to check for them if we are in active mode
        if (guiBindWindowMode:GetValue() == 1 and parentValue ~= "Off") or guiBindWindowMode:GetValue() == 2 then
            text[1] = string.format("[%s]", string.gsub(bind.type, "bind", ""))
            text[2] = bind.key
            text[3] = bind.parent
            text[4] = parentValue
        end

        for j, str in ipairs(text) do
            table.insert(windowTextElements[i], gui.Text(guiBindWindow, str));
        end
    end

    -- Scale window to fit binds
    local y, x = 10
    local textPositions = {10, 60, 110, 340}
    for i, textRow in ipairs(windowTextElements) do
        if #textRow ~= 0 then
            for j, textElement in ipairs(textRow) do
                x = textPositions[j]
                textElement:SetPosY(y)
                textElement:SetPosX(x)
            end
            guiBindWindow:SetHeight(50 + y)

            y = y + textSpacing
        end
    end

end)

-- I tend to comment my code alot and idk if anyone actually read these, if you do dm Scape#4313 'im a nerd and like to read'
callbacks.Register("unload", function()
    for i, textRow in ipairs(windowTextElements) do
        for j, textElement in ipairs(textRow) do
            textElement:Remove()
        end
    end

    windowTextElements = {}
    bindStrings = {}
    bindRaw = {}
    binds = {}
end)

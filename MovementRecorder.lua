-- Movement Recorder V5 by Scape#4313
-- Mostly writted from scratch i stole the base 64 functions from stackoverflow tho https://stackoverflow.com/questions/34618946/lua-base64-encode
-- Dm me with questions but please try to figure them out yourself first

-- Important globals that run the script smoothly
local stringBase64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" -- Dont touch this youll corrupt your reorded files and not be able to load other ones
local stringFolder = "MovementRecs" -- You can change this folder name to your liking
local stringPattern = stringFolder.."/.+%.dat" -- NEVER CHANGE THIS you could accidentally delete configs or scripts

local isRecording = false
local isPlayback = false
local isPaused = false
local inReturn = false
local cache = nil

-- gui vars
local guiTab = gui.Tab(gui.Reference("Misc"), "moverec", "Movement Recorder")
local guiRef = gui.Reference("Misc", "Movement Recorder")

local groupboxSettings = gui.Groupbox(guiRef, "Recording and Playback Settings", 16, 16, 296, 0)
-- Big multi setup right here
local drawingSettingsMulti = gui.Multibox(groupboxSettings, "Path Drawing")
    local multiDrawEnds = gui.Checkbox(drawingSettingsMulti, "settings.drawends", "loaded Start and Stop Points", true)
        local colorEnd = gui.ColorPicker(multiDrawEnds, "color.end", "", 255, 0, 0, 255)
        local colorStart= gui.ColorPicker(multiDrawEnds, "color.Start", "", 0, 255, 0, 255)
    local multiDrawOnPlay = gui.Checkbox(drawingSettingsMulti, "settings.drawpathPlay", "As Recording Plays", true)
        local colorPlay = gui.ColorPicker(multiDrawOnPlay, "color.play", "", 255, 255, 0, 255)
    local multiDrawOnRec = gui.Checkbox(drawingSettingsMulti, "settings.drawpathlive", "As Recording Saves", true)
        local colorRec = gui.ColorPicker(multiDrawOnRec, "color.rec", "", 255, 0, 0, 255)
    local multiDrawLoaded = gui.Checkbox(drawingSettingsMulti, "settings.drawpathloaded", "Loaded Path", true)
        local colorLoaded = gui.ColorPicker(multiDrawLoaded, "color.loaded", "", 255, 255, 0, 255)
drawingSettingsMulti:SetDescription("Control draw conditions and color of the path.")

-- Pathfinding options, not really but it does 'find' the path so it counts as 'pathfinding'
local pathReturnMulti = gui.Multibox(groupboxSettings, "Return To Path")
    local multiReturnUnpause = gui.Checkbox(pathReturnMulti, "settings.return.unpause", "On Unpause", true);
    local multiReturnPlay = gui.Checkbox(pathReturnMulti, "settings.return.play", "On start", true);
    local multiReturnKeypress = gui.Checkbox(pathReturnMulti, "settings.return.play", "On Keypress", false)
pathReturnMulti:SetDescription("Moves player to start position of path before it plays.")

-- Rest of options and shit
local recordingText = gui.Checkbox(groupboxSettings, "settings.indicator", "Recording and Playback Indicator", true)
recordingText:SetDescription("Enable to see recording and playback status.")
local recordingStartKey = gui.Keybox(groupboxSettings, "recoder.key.start", "Start Recording", 0)
local playControlKey = gui.Keybox(groupboxSettings, "playback.key.start", "Play/Pause Playback", 0)
local recordingEndKey = gui.Keybox(groupboxSettings, "recoder.key.end", "End Recording", 0)
local returnKey = gui.Keybox(groupboxSettings, "playback.key.pause", "Return Key", 0)
local recordingSaveName = gui.Editbox(groupboxSettings, "", "Recording File Name")
recordingSaveName:SetDescription("The name of next recording saved. (alphanumeric only)")


-- List box soo cool
local groupboxRecordings = gui.Groupbox(guiRef, "Saved Recordings", 328, 16, 296, 0)
local selectedRecording = gui.Listbox(groupboxRecordings, "", 244)
local splashText = gui.Text(groupboxRecordings, "Movement Recorder - by scape#4313")

local function recordingEncode(tableData)
    local stringData = ""

    for i, data in ipairs(tableData) do
        stringData = stringData..string.format( "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s", unpack(data))
        if i ~= #tableData then stringData = stringData..":" end
    end

    return ((stringData:gsub('.', function(x) 
        local r,stringBase64='',x:byte()
        for i=8,1,-1 do r=r..(stringBase64%2^i-stringBase64%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return stringBase64:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#stringData%3+1])
end

local function recordingDecode(stringData)

    stringDecoded = string.gsub(stringData, '[^'..stringBase64..'=]', '')
    local stringDecoded = (stringData:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(stringBase64:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))

    local ticks = {}

    for tick in string.gmatch(stringDecoded, "([^:]+)") do
        if tick ~= nil then
            local tickData = {}

            for data in string.gmatch(tick, "([^,]+)") do
                table.insert(tickData, tonumber(data))
            end
            
            if #tickData ~= 10 then
                error("Corrupt .dat File!")
            end

            table.insert(ticks, {tickData[1], tickData[2], tickData[3], tickData[4], tickData[5], tickData[6], tickData[7], tickData[8], tickData[9], tickData[10]})

        end
    end

    return ticks
end

local function refreshListBox(text)
    local saves = {}

    file.Enumerate(function(filename)
        if string.match(filename, stringPattern) then

            local f = file.Open(filename, "r")
            if not pcall(recordingDecode, f:Read()) then
                filename = filename.." - WARNING CORRUPT FILE!"
            end
            filename = filename:gsub(stringFolder.."/", "")
            table.insert(saves, filename)
            f:Close()
        end
    end)
    
    splashText:SetText(text or "Movement Recorder - by scape#4313")
    recordingSaveName:SetValue("Enter a Recording Name")
    selectedRecording:SetOptions(unpack(saves))
end

local buttonLoadRecording = gui.Button(groupboxRecordings, "Load Recording", function()
    local index = 0
    local error
    
    file.Enumerate(function(filename)
        if string.match(filename, stringPattern) then
            if index == selectedRecording:GetValue() then
                local f = file.Open(filename, "r")
                error, cache = pcall(recordingDecode, f:Read())
                f:Close()

                if error then
                    splashText:SetText(string.format("Loaded Playback, %s!", filename))
                else
                    splashText:SetText(string.format("Failed to load Playback, %s!", cache))
                end
            end

            index = index + 1
        end
    end)
end)

local buttonUnloadRecording = gui.Button(groupboxRecordings, "Unload Recording", function()
    if isRecording then return end

    isPlayback = false
    isPaused = false
    inReturn = false
    cache = nil

    splashText:SetText("Unloaded Playback.")
end)

local buttonDeleteRecording = gui.Button(groupboxRecordings, "Delete Recording", function() 
    local index = 0
    file.Enumerate(function(filename)
        if string.match(filename, stringPattern) then
            if index == selectedRecording:GetValue() then
                file.Delete(filename)
                refreshListBox("Deleted "..filename)
                
            end
        
        index = index + 1
        end
    end)
end)

local buttonRenameRecording = gui.Button(groupboxRecordings, "Rename Recording", function() 
    local index = 0
    file.Enumerate(function(filename)
        if string.match(filename, stringPattern) then
            if index == selectedRecording:GetValue() then
                -- Sanitize filenames for renaming procedure
                if not (recordingSaveName:GetValue():match("%W")) then
                    -- Save and delete old file
                    local f = file.Open(filename, "r")
                    local backup = f:Read()
                    f:Close()
                    file.Delete(filename)
                    print("deleted "..filename)
                    -- Create new file with new name same data
                    local r = file.Open(string.format( "%s/%s",stringFolder, recordingSaveName:GetValue())..".dat", "w")
                    r:Write(backup)
                    r:Close()

                    refreshListBox(string.format("Renamed %s to %s.", filename, recordingSaveName:GetValue()))
                else
                    recordingSaveName:SetValue("Invalid filename, Alphanum chars only!")
                end
                
                return
            end
        
        index = index + 1
        end
    end)
end)

local buttonRefreshRecording = gui.Button(groupboxRecordings, "Refresh List", refreshListBox)
-- Finishing touches cause front end is as important as back end and my ocd makes me do this
-- I always scale dpi wayyyy up to align everything pixel perfect
buttonDeleteRecording:SetPosX(136)
buttonRenameRecording:SetPosX(136)
buttonDeleteRecording:SetPosY(260)
buttonRenameRecording:SetPosY(308)
buttonLoadRecording:SetPosY(260)
buttonLoadRecording:SetPosX(0)
recordingStartKey:SetPosY(264)
recordingEndKey:SetPosX(136)
recordingEndKey:SetPosY(264)
playControlKey:SetPosY(320)
returnKey:SetPosX(136)
returnKey:SetPosY(320)
splashText:SetPosY(404)

local function Init()
    print("Movement Recorder - Initializing...")

    -- Loops through folders to find all recordings
    file.Enumerate(function(filename)
        if string.match(filename, stringPattern) then
            print(string.format("   Validating %s", filename))
            
            -- Load each file to cache to make sure they are valid
            local f = file.Open(filename, "r")
            local error, data = pcall(recordingDecode, f:Read())
            f:Close()

            if error then
                print(string.format("   Validated %s!\n", filename))
            else
                print(string.format("   Failed to Validate %s!\n", data))
            end
        end
    end)

    recordingSaveName:SetValue("Enter a name and start recording!")
    print("Movement Recorder - Initializing done!")
    refreshListBox("Movement Recorder - by scape#4313")
end

if not pcall(Init) then
    print("Movement Recorder - Error Loading Recordings, Corrupt .dat file!")
    print("Movement Recorder - UnLoading Script")
    UnloadScript(GetScriptName())
end

-- Callbacks
callbacks.Register("CreateMove", function(cmd) 
    local Mf = cmd:GetForwardMove()
    local Ms = cmd:GetSideMove()
    local Mu = cmd:GetUpMove()
    local B = cmd:GetButtons()
    local V = cmd:GetViewAngles()
    local P = entities.GetLocalPlayer():GetAbsOrigin()

    if cache and isRecording then
        table.insert(cache, {Mf, Ms, Mu, B, V.x, V.y, V.z, P.x, P.y, P.z})
    end

    if cache and inReturn and isPaused then
        if cache[1] then 
            local target = Vector3(cache[1][8], cache[1][9], cache[1][10])
            local forward = target - entities.GetLocalPlayer():GetAbsOrigin()
            local angles = engine.GetViewAngles()

            if forward:Length() < 10 then
                inReturn = false
                isPaused = false
            end
           
            cmd.forwardmove = (((math.sin(math.rad(angles.y)) * forward.y) + (math.cos(math.rad(angles.y)) * forward.x) ) * 200)
            cmd.sidemove = (((math.cos(math.rad(angles.y)) * -forward.y) + (math.sin(math.rad(angles.y)) * forward.x) ) * 200)
        end
    elseif cache and isPlayback and not isPaused then
        if cache[1] then
            local actions = cache[1]
    
            cmd.forwardmove = actions[1]
            cmd.sidemove = actions[2]
            cmd.upmove = actions[3]
            cmd.buttons = actions[4]
            engine.SetViewAngles(EulerAngles(actions[5], actions[6], actions[7])) 
    
            table.remove(cache, 1)
            if #cache == 0 then
                isPlayback = false
                isPaused = false
                cache = nil
            end
        end
    end
end)

callbacks.Register("Draw", function() 
    -- Key Press control
    -- Start recording
    if recordingStartKey:GetValue() ~= 0 and input.IsButtonPressed(recordingStartKey:GetValue()) then
        if not isPlayback and not isRecording then
            local filename = recordingSaveName:GetValue()

            -- Sanitize filenames
            if not (filename:match("%W")) then
                isRecording = true
                cache = {}

                cache.filename = string.format( "%s/%s",stringFolder, recordingSaveName:GetValue())..".dat"
                splashText:SetText(string.format("Recording to %s.dat ", filename))
            else
                recordingSaveName:SetValue("Invalid filename, Alphanum chars only!")
            end
        end
    end

    -- Save recording
    if recordingEndKey:GetValue() ~= 0 and input.IsButtonPressed(recordingEndKey:GetValue()) then
        if isRecording and not isPlayback then
            isRecording = false
        
            local f = file.Open(cache.filename, "w")
            local data = recordingEncode(cache)
            f:Write(data)
            f:Close()
            
            refreshListBox("Recording Ended "..cache.filename)
        end
    end

    -- Start playback
    if cache and playControlKey:GetValue() ~= 0 and input.IsButtonPressed(playControlKey:GetValue()) then
        if not isRecording then
            -- Start
            if not isPlayback then
                if multiReturnPlay:GetValue() then
                    isPaused = true inReturn = true
                else
                    isPaused = false inReturn = false
                end

                isPlayback = true
            -- Unpause
            elseif isPaused then
                if multiReturnUnpause:GetValue() and not inReturn then
                    isPaused = true inReturn = true
                else 
                    isPaused = false inReturn = false
                end
            -- Pause
            else
                isPaused = true
                inReturn = false
            end
        end
    end

    -- Recording indicator
    if recordingText:GetValue() then
        -- Draw Control
        draw.Color(255, 0, 0, 255)
        if isRecording then
            draw.Color(0, 255, 0, 255)
        end
        draw.Text(100, 100, "Recording")

        draw.Color(255, 0, 0, 255)
        if isPlayback then
            draw.Color(0, 255, 0, 255)
            if isPaused then
                draw.Color(255, 255, 0, 255)
            end
        end
        draw.Text(100, 115, "Playback")

        draw.Color(255, 0, 0, 255)
        if inReturn then
            draw.Color(0, 255, 0, 255)
        end
        draw.Text(100, 130, "Return")
    end

    -- Path drawing stuff
    if cache and ((isRecording and multiDrawOnRec:GetValue()) or (isPlayback and multiDrawOnPlay:GetValue()) or (multiDrawLoaded:GetValue()and not isPlayback and not isRecording)) then
        for i = 1, #cache - 1 do
            
            local x1, y1 = client.WorldToScreen(Vector3(cache[i][8], cache[i][9], cache[i][10]))
            local x2, y2 = client.WorldToScreen(Vector3(cache[i+1][8], cache[i+1][9], cache[i+1][10]))
            if x1 and x2 then
                -- Draw Line
                local r, g, b, a = colorLoaded:GetValue()
                if isRecording then
                    r, g, b, a = colorRec:GetValue()
                elseif isPlayback then
                    r, g, b, a = colorPlay:GetValue()
                end

                draw.Color(r, g, b, a)
                draw.Line(x1, y1, x2, y2)
            end
        end
    end

    -- Start and end points, how path drawing and play back is handled makes this real ez
    if cache and multiDrawEnds:GetValue() then
        if cache[1] and cache[#cache] then
            local Bx, By = client.WorldToScreen(Vector3(cache[1][8], cache[1][9], cache[1][10]))
            local Ex, Ey = client.WorldToScreen(Vector3(cache[#cache][8], cache[#cache][9], cache[#cache][10]))

            local r, g, b, a = colorStart:GetValue()
            draw.Color(r, g, b, a)
            draw.FilledCircle(Bx, By, 4)

            r, g, b, a = colorEnd:GetValue()
            draw.Color(r, g, b, a)
            draw.FilledCircle(Ex, Ey, 4)
        end
    end
end)

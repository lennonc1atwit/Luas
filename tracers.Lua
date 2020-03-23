-- Local tracer Lua by Scape

-- TODO: Real m_vecViewOffset calculation
--		 Color tracers based on hit / no hit 
--		 Fix flicker on some expired tracers
--		 Fix tracer height during fakeduck
-- 		 Either wait for w2s offScreen bug fix or create my own w2s function

local ref = gui.Reference("Visuals", "World", "Extra");
local boxesCheckbox = gui.Checkbox(ref, "lua_boxes", "Tracer Boxes", true);
local tracerCheckbox = gui.Checkbox(ref, "lua_tracer", "Tracers", true);
local boxesColor = gui.ColorPicker(boxesCheckbox, "lua_boxes_color", "", 255, 0, 0, 255);
local tracerColor = gui.ColorPicker(tracerCheckbox, "lua_tracer_color", "", 255, 255, 0, 255);

local hitCount = 0;
local tempHitCount = 0;
local minViewOffset, maxViewOffset = 46, 64;
local localPlayer = entities.GetLocalPlayer();

hitData = {};
hitData.hitPos = {};
hitData.eyePos = {};
hitData.hitTime = {};
hitData.lifeSpan = {};

--change these to liking--
local cubeSize = 2;       -- bullet impact size
local tracerLifeSpan = 2; -- how long tracer stays onscreen before fading
local tracerFadeTime = 2; -- how long it takes tracer to fade after lifespan is reached

local function drawCubeFromCenter(size, center, r, g, b, a)
	local point1x, point1y = client.WorldToScreen(Vector3(center.x - size, center.y - size, center.z - size));
	local point2x, point2y = client.WorldToScreen(Vector3(center.x - size, center.y + size, center.z - size));
	local point3x, point3y = client.WorldToScreen(Vector3(center.x + size, center.y - size, center.z - size));
	local point4x, point4y = client.WorldToScreen(Vector3(center.x + size, center.y + size, center.z - size));
	local point5x, point5y = client.WorldToScreen(Vector3(center.x - size, center.y - size, center.z + size));
	local point6x, point6y = client.WorldToScreen(Vector3(center.x + size, center.y - size, center.z + size));
	local point7x, point7y = client.WorldToScreen(Vector3(center.x - size, center.y + size, center.z + size));
	local point8x, point8y = client.WorldToScreen(Vector3(center.x + size, center.y + size, center.z + size));
	
	draw.Color(r, g, b, a);
	draw.Line(point1x, point1y, point2x, point2y);
	draw.Line(point1x, point1y, point3x, point3y);
	draw.Line(point1x, point1y, point5x, point5y);
	
	draw.Line(point8x, point8y, point7x, point7y);
	draw.Line(point8x, point8y, point6x, point6y);
	draw.Line(point8x, point8y, point4x, point4y);
	
	draw.Line(point6x, point6y, point3x, point3y);
	draw.Line(point4x, point4y, point3x, point3y);
	draw.Line(point4x, point4y, point2x, point2y);
	draw.Line(point2x, point2y, point7x, point7y);
	draw.Line(point7x, point7y, point5x, point5y);
	draw.Line(point6x, point6y, point5x, point5y);
end

local function map(src, srcMax, srcMin, retMax, retMin)
	return (src - srcMin) / (srcMax - srcMin) * (retMax - retMin) + retMin;
end

local function getPlayerHeightEstimator()
	local m_flDuckAmount = localPlayer:GetPropFloat("m_flDuckAmount");
	local eyeOffset = map(m_flDuckAmount, 0, 1, maxViewOffset, minViewOffset);
	
	return eyeOffset;
end

local function eventHandler(event)
    if (event:GetName() == "bullet_impact") then
        local ent = entities.GetByUserID(event:GetInt("userid"));
        if (ent ~= nil and ent:GetIndex() == localPlayer:GetIndex()) then
            local hitPos = Vector3(event:GetFloat("x"), event:GetFloat("y"), event:GetFloat("z"));
            local m_vecOrigin = localPlayer:GetAbsOrigin();
			local m_vecViewOffset = getPlayerHeightEstimator();
			
			-- local m_vecViewOffset = localPlayer:GetPropVector("m_vecViewOffset"); ideal correct way to get Offset but not working currently
			-- local eyePos = Vector3(m_vecOrigin.x, m_vecOrigin.y, (m_vecOrigin.z + m_vecViewOffset.z));
			
			local eyePos = Vector3(m_vecOrigin.x, m_vecOrigin.y, (m_vecOrigin.z + m_vecViewOffset));

			table.insert(hitData.hitPos, hitPos);
			table.insert(hitData.eyePos, eyePos);
			table.insert(hitData.hitTime, globals.CurTime());
	
			hitCount = hitCount + 1;
        end
    end
end

local function hDraw()
    if (boxesCheckbox:GetValue() or tracerCheckbox:GetValue() and localPlayer ~= nil) then
	
		-- this code is redundant but necessary, 
		-- we dont want to change the for loop counter mid loop as we would lose the last index each loop
		-- so we just store the next hitCount in a temp var
        tempHitCount = hitCount;
		
        for index = 0, hitCount, 1 do
            if (hitData.hitTime[index] ~= nil and hitData.hitPos[index] ~= nil) then
			
                local lifeSpan = globals.CurTime() - hitData.hitTime[index];
				
                if (lifeSpan > tracerLifeSpan + tracerFadeTime) then
					table.remove(hitData.hitPos, index);
					table.remove(hitData.eyePos, index);
					table.remove(hitData.hitTime, index);
					table.remove(hitData.lifeSpan, index);
	
					tempHitCount = tempHitCount - 1;
                end
				
                if hitData.hitPos[index] ~= nil then
				
                    local fadeAlpha = 255;
					
                    if (lifeSpan > tracerLifeSpan) then
						local currLifeSpan = lifeSpan - hitData.lifeSpan[index]
						fadeAlpha =  map(currLifeSpan, tracerFadeTime, 0, 0, 255);
                    else
                        table.insert(hitData.lifeSpan, index, lifeSpan)
                    end
					
					if boxesCheckbox:GetValue() then
						local r, g, b, a = boxesColor:GetValue();
						
						draw.Color(r, g, b, fadeAlpha);
						drawCubeFromCenter(cubeSize, hitData.hitPos[index], r, g, b, fadeAlpha);
					end
					
					if tracerCheckbox:GetValue() then
						local r, g, b, a = tracerColor:GetValue();
						local xHit, yHit = client.WorldToScreen(hitData.hitPos[index]);
						local xHead, yHead = client.WorldToScreen(hitData.eyePos[index]);
						
						draw.Color(r, g, b, fadeAlpha);
						draw.Line(xHit, yHit, xHead, yHead);
					end
                end
            end
        end
		
        hitCount = tempHitCount;
    end
end

client.AllowListener("bullet_impact");
callbacks.Register("FireGameEvent", eventHandler);
callbacks.Register("Draw", hDraw);

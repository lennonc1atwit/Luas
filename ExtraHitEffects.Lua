-- Extra hit effects by Scape#4313
-- Gui references
local ref1 = gui.Reference("Visuals", "World", "Extra");
local ref2 = gui.Reference("Visuals", "World", "Extra", "Hit Effects");
local ref3 = gui.Reference("Visuals", "World", "Extra", "Hit Effects", "Sound");
local ref4 = gui.Reference("Visuals", "World", "Extra", "Hit Effects", "Marker");
-- Gui Setup
local multibox = gui.Multibox(ref1, "Hit Effects");
local optionGroupBox = gui.Groupbox(gui.Reference("Visuals", "World"), "Settings", 328, 218, 296, 100);
local settingsTab = gui.Combobox(optionGroupBox, "currentsettings", "Hit Effect Settings", "General", "Hitmarker", "Font", "Debug");
local soundEffect = gui.Checkbox(multibox, "hiteffects.sound", "Sound", false);
local skeletonEffect = gui.Checkbox(multibox, "hiteffects.skeleton", "Skeleton", false);
local damageEffect = gui.Checkbox(multibox, "hiteffects.damage", "Damage", false);
local hitgroupEffect = gui.Checkbox(multibox, "hiteffects.hitgroup", "Hit Group", false);
-- General options
local solidTime = gui.Slider(optionGroupBox, "extrahiteffects.solidtime", "Duration", 0, 0, 10, .1);
local fadeTime = gui.Slider(optionGroupBox, "extrahiteffects.fadetime", "Fade Duration", 2, 0, 10, .1);
local skeletonColorLink = gui.Checkbox(optionGroupBox, "extrahiteffectss.skeletonlink", "Inherit Skeleton Color", true);
local skeletonClr = gui.ColorPicker(optionGroupBox, "extrahiteffects.skeletonclr", "", 255, 255, 255, 255);
-- Hitmarker options
local hitMarkerType = gui.Combobox(optionGroupBox, "hitmarkertype", "Hitmarker", "Off", "Cube", "Cross", "Dot");
local cubeFilled = gui.Checkbox(optionGroupBox, "cube.fill", "Filled Cube", false);
local cubeSize = gui.Slider(optionGroupBox, "cube.size", "Cube Size", 2, .1, 10, .1);
local crossDynamic = gui.Checkbox(optionGroupBox, "cross.dynamic", "Dynamic Cross Size", false);
local crossOutline = gui.Checkbox(optionGroupBox, "cross.outline", "Outline", true);
local crossSize = gui.Slider(optionGroupBox, "cross.size", "Cross Size", 10, .1, 20, .1);
local crossGapSize = gui.Slider(optionGroupBox, "cross.gapsize", "Cross Gap Size", 2, .1, 5, .1);
local dotDynamic = gui.Checkbox(optionGroupBox, "dot.dynamic", "Dynamic Dot Size", false);
local dotSize = gui.Slider(optionGroupBox, "dot.size", "Dot Size", 2, .1, 10, .1);
local hitmarkerClr = gui.ColorPicker(optionGroupBox, "hitmarkerclr", "", 255, 255, 255, 255);
-- Text options
local dammageClr = gui.ColorPicker(optionGroupBox, "damageclr", "Damage Color", 255, 255, 255, 255);
local hitgroupClr = gui.ColorPicker(optionGroupBox, "hitgroupclr", "Hitgroup Color", 255, 255, 255, 255);
local fontSize = gui.Slider(optionGroupBox, "fontsize", "Font Size", 16, 1, 30, 1);
local fontName = gui.Editbox(optionGroupBox, "fontname", "Font Name"); 
-- Debug options
local debugMultibox = gui.Multibox(optionGroupBox, "Log Hits");
local predictedHitboxDebug = gui.Checkbox(debugMultibox, "debug.hitbox", "Hitbox", false);
local hitGroupNameDebug = gui.Checkbox(debugMultibox, "debug.hitgroup", "HitGroup", false);
local predictedBacktrackDebug = gui.Checkbox(debugMultibox, "debug.backtrack", "Backtrack Index", false);
local damageDebug = gui.Checkbox(debugMultibox, "debug.damage", "Damage", false);
-- Gui descriptions
fontName:SetDescription("Enter font name");
fontSize:SetDescription("Customize font size");
debugMultibox:SetDescription("Log hit information in cheat console");
dotDynamic:SetDescription("Render dot in world");
dotSize:SetDescription("Customize dot size");
cubeFilled:SetDescription("Colors faces of cube");
cubeSize:SetDescription("Customize cube size");
crossDynamic:SetDescription("Render cross in world");
crossOutline:SetDescription("Draw outline around cross");
crossSize:SetDescription("Customize cross size");
crossGapSize:SetDescription("Customize gap size");
skeletonColorLink:SetDescription("Use color from skeleton esp");
multibox:SetDescription("Effects when hitting an enemy");
hitMarkerType:SetDescription("Hitmarker style");
solidTime:SetDescription("Seconds before fading");
fadeTime:SetDescription("Seconds it takes to fade");
-- Gui finishing touches
skeletonClr:SetPosY(182);
hitmarkerClr:SetPosY(128);
crossSize:SetWidth(130);
crossSize:SetPosY(232);
crossGapSize:SetWidth(130);
crossGapSize:SetPosY(232);
crossGapSize:SetPosX(140);
fontName:SetValue("Tahoma");
fontName:SetWidth(130);
fontSize:SetWidth(130);
fontSize:SetPosX(140);
fontName:SetPosY(122);
ref2:SetInvisible(true);
ref4:SetValue(false);

-- Classes and global vars
local hitGroupText = {"GENERIC", "HEAD", "CHEST", "STOMACH", "LEFT ARM", "RIGHT ARM", "LEFT LEG", "RIGHT LEG", "NECK"};
local hitGroupStandards = {"HITGROUP_GENERIC", "HITGROUP_HEAD", "HITGROUP_CHEST", "HITGROUP_STOMACH", "HITGROUP_LEFTARM", "HITGROUP_RIGHTARM", "HITGROUP_LEFTLEG", "HITGROUP_RIGHTLEG", "HITGROUP_GEAR"};
local playerBoneConnections = {{1, 2}, {2,7}, {7, 6}, {6, 5}, {5, 4}, {4, 3}, {3, 9}, {3, 8}, {9, 11}, {8, 10}, {11, 13}, {10, 12}, {7, 18}, {18, 19}, {19, 15}, {7, 16}, {16, 17}, {17, 14}};
local conversion = {2, 0, 4, 2, 13, 14, 7, 8, 1};
local savedPlayers = {};
local impacts = {};
local hits = {};
local backtrackActive = false;

--- Hit class
local Hit = {
    dammage = 0,
    pos = {},
    skeletonVecs = {},
	created = 0;
}

function Hit:New(dmg, group, hitpos, skeleton)
    local newHit = {};
    setmetatable(newHit, self)
    self.__index = self;
    newHit.dammage = dmg;
    newHit.hitgroup = group;
	newHit.pos = hitpos;
	newHit.skeletonVecs = skeleton;
	newHit.created = globals.CurTime();
    return newHit;
end
-- Vector2 class
local Vector2 = {
    x = nil,
    y = nil;
}

function Vector2:New(xcord, ycord)
    local newVector2 = {};
    setmetatable(newVector2, self)
    self.__index = self;
    newVector2.x = xcord;
	newVector2.y = ycord;
    return newVector2;
end
-- Helper Funcs
local function map(src, srcMax, srcMin, retMax, retMin)
	return (src - srcMin) / (srcMax - srcMin) * (retMax - retMin) + retMin;
end

local function getClosestImpact(vec3)
	local bestIndex;
	local bestDistance = math.huge;
	
	for index = 1, #impacts do 
		local impact = impacts[index];
		
		if impact then
			local delta = impact - vec3;
			local distance = delta:Length();
			
			if distance < bestDistance then
				bestDistance = distance;
				bestIndex = index;
			end
		end
	end

	return bestIndex;
end

local function getClosestBackTrack(point, playerIndex, hitbox)
	local bestVecs;
	local bestIndex;
	local bestDistance = math.huge;
	local player = entities.GetByIndex(playerIndex);
	
	for index = 1, #savedPlayers[playerIndex] do
		if savedPlayers[playerIndex][index] then
			local hitboxVecs = savedPlayers[playerIndex][index][1];
			
			local hitboxPos = hitboxVecs[hitbox+1];
			if hitboxPos then
				local delta = (hitboxPos - point);
				local distance = delta:Length()
					
				if distance < bestDistance then
					bestDistance = distance;
					bestIndex = index;
				end
			end
		end
	end
	bestVecs = savedPlayers[playerIndex][bestIndex][1];

	return bestVecs, bestIndex;
end

local function drawCubeAtPoint(size, vec, alphaFill)
	local lineConnections = {{1, 2}, {1, 3}, {1, 5}, {8, 7}, {8, 6}, {8, 4}, {6, 3}, {4, 3}, {4, 2}, {2, 7}, {7, 5}, {6, 5}};
	local triangleConnections = {{1, 2, 3}, {1, 2 ,5}, {1, 3 ,5}, {8, 7, 6}, {8, 7, 4}, {8, 6, 4}, {3, 6, 5}, {3, 4, 6}, {2, 4, 7}, {2, 7, 5}, {3, 4, 2}, {6, 5, 7}};
	local points = {};
	
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x - size, vec.y - size, vec.z - size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x - size, vec.y + size, vec.z - size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x + size, vec.y - size, vec.z - size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x + size, vec.y + size, vec.z - size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x - size, vec.y - size, vec.z + size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x + size, vec.y - size, vec.z + size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x - size, vec.y + size, vec.z + size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x + size, vec.y + size, vec.z + size))));
	
	for i = 1, #lineConnections do
		local p1 = points[lineConnections[i][1]];
		local p2 = points[lineConnections[i][2]];
		
		if p1.x and p1.y and p2.x and p2.y then
			draw.Line(p1.x, p1.y, p2.x, p2.y);
		end
	end	
	
	if cubeFilled:GetValue() then
		local r, g, b, a = hitmarkerClr:GetValue();
		draw.Color(r, g, b, alphaFill);
		for i = 1, #triangleConnections do
			local p1 = points[triangleConnections[i][1]];
			local p2 = points[triangleConnections[i][2]];
			local p3 = points[triangleConnections[i][3]];
			
			if p1.x and p1.y and p2.x and p2.y and p3.x and p3.y then
				draw.Triangle(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
			end
		end
	end
end

local function drawCrossAtPoint(size, vec3, gap, alphaOutline)
	local x, y;
	local newSize, newGap;
	if crossDynamic:GetValue() then
		local localPlayer = entities.GetLocalPlayer();
		local localEye = localPlayer:GetAbsOrigin() + localPlayer:GetPropVector("localdata", "m_vecViewOffset[0]");
		local targetAngles = (localEye - vec3):Angles();
		local hitPoint = localEye + targetAngles:Forward() * -(vec3- localEye):Length();
		local hitxy = Vector2:New(client.WorldToScreen(hitPoint));
		
		local rightOut = Vector2:New(client.WorldToScreen(hitPoint + targetAngles:Right() * gap)).x;
		local leftOut = Vector2:New(client.WorldToScreen(hitPoint + targetAngles:Right() * -gap)).x;
		local rightIn = Vector2:New(client.WorldToScreen(hitPoint + targetAngles:Right() * (gap-size))).x;
		local leftIn = Vector2:New(client.WorldToScreen(hitPoint + targetAngles:Right() * -(gap-size))).x;
		
		
		if leftOut and rightOut and topOut and bottomOut then
			newSize = leftOut - rightOut;
			newGap = leftIn - rightIn;
		end
		
		x = hitxy.x;
		y = hitxy.y;
		
	else
		x, y = client.WorldToScreen(vec3)
		newSize = size;
		newGap = gap;
	end
	
	if x and y then -- This is real ugly not proud of this
		draw.Line(x + newGap, y + newGap, x + newSize, y + newSize);
		draw.Line(x - newGap, y - newGap, x - newSize, y - newSize);
		draw.Line(x + newGap, y - newGap, x + newSize, y - newSize);
		draw.Line(x - newGap, y + newGap, x - newSize, y + newSize);
			
		if crossOutline:GetValue() then
			draw.Color(0,0,0, alphaOutline);
			draw.Line(x + newGap - 1, y + newGap + 1, x + newSize - 1, y + newSize + 1);
			draw.Line(x + newGap + 1, y + newGap - 1, x + newSize + 1, y + newSize - 1);
			draw.Line(x - newSize - 1, y + newSize - 1, x - newSize + 1, y + newSize + 1);
			draw.Line(x - newGap - 1, y - newGap + 1, x - newSize - 1, y - newSize + 1);
			draw.Line(x - newGap + 1, y - newGap - 1, x - newSize + 1, y - newSize - 1);
			draw.Line(x + newSize - 1, y - newSize - 1, x + newSize + 1, y - newSize + 1);
			draw.Line(x + newGap - 1, y - newGap - 1, x + newSize - 1, y - newSize - 1);
			draw.Line(x + newGap + 1, y - newGap + 1, x + newSize + 1, y - newSize + 1);
			draw.Line(x - newSize - 1, y - newSize + 1, x - newSize + 1, y - newSize - 1);
			draw.Line(x - newGap - 1, y + newGap - 1, x - newSize - 1, y + newSize - 1);
			draw.Line(x - newGap + 1, y + newGap + 1, x - newSize + 1, y + newSize + 1);
			draw.Line(x + newSize - 1, y + newSize + 1, x + newSize + 1, y + newSize - 1);
			if newGap > .5 then
				draw.Line(x - newGap + 1, y + newGap + 1, x - newGap - 1, y + newGap - 1);
				draw.Line(x + newGap - 1, y - newGap - 1, x + newGap + 1, y - newGap + 1);
				draw.Line(x - newGap - 1, y - newGap + 1, x - newGap + 1, y - newGap - 1);
				draw.Line(x + newGap - 1, y + newGap + 1, x + newGap + 1, y + newGap - 1);
			end
		end
	end
	
end

local function drawDotAtPoint(size, vec3) 
	local localPlayer = entities.GetLocalPlayer();
	local localEye = localPlayer:GetAbsOrigin() + localPlayer:GetPropVector("localdata", "m_vecViewOffset[0]");
	local targetAngles = (localEye - vec3):Angles();
	
	local hitPoint = localEye + targetAngles:Forward() * -(vec3- localEye):Length();
	local hitxy = Vector2:New(client.WorldToScreen(hitPoint));
	
	local right = Vector2:New(client.WorldToScreen(hitPoint + targetAngles:Right() * size)).x;
	local left = Vector2:New(client.WorldToScreen(hitPoint + targetAngles:Right() * -size)).x;
	
	if left and right then
		local radius
		if dotDynamic:GetValue() then
			radius = (right - left) / 2;
		else
			radius = size;
		end
		
		draw.FilledCircle(hitxy.x, hitxy.y, radius);
	end
end
-- Main Body
-- gui stuffs
local function guiDraw()
	local settingSelection = settingsTab:GetValue();
	
	if soundEffect:GetValue() then
		ref3:SetValue(true);
	else
		ref3:SetValue(false);
	end
	
	if settingSelection == 0 then -- General
		solidTime:SetInvisible(false);
		fadeTime:SetInvisible(false);
		skeletonColorLink:SetInvisible(false);
		skeletonClr:SetInvisible(false);
		hitMarkerType:SetInvisible(true);
		hitmarkerClr:SetInvisible(true);
		cubeFilled:SetInvisible(true);
		cubeSize:SetInvisible(true);
		crossDynamic:SetInvisible(true);
		crossSize:SetInvisible(true);
		crossGapSize:SetInvisible(true);
		crossOutline:SetInvisible(true);
		dotDynamic:SetInvisible(true);
		dotSize:SetInvisible(true);
		dammageClr:SetInvisible(true);
		hitgroupClr:SetInvisible(true);
		fontSize:SetInvisible(true);
		fontName:SetInvisible(true);
		debugMultibox:SetInvisible(true);
		predictedHitboxDebug:SetInvisible(true);
		hitGroupNameDebug:SetInvisible(true);
		predictedBacktrackDebug:SetInvisible(true);
		damageDebug:SetInvisible(true);
	elseif settingSelection == 1 then -- Hitmarker
		local hitmarkerSelection = hitMarkerType:GetValue();
		if hitmarkerSelection == 0 then -- Off
			solidTime:SetInvisible(true);
			fadeTime:SetInvisible(true);
			skeletonColorLink:SetInvisible(true);
			skeletonClr:SetInvisible(true);
			hitMarkerType:SetInvisible(false);
			hitmarkerClr:SetInvisible(true);
			cubeFilled:SetInvisible(true);
			cubeSize:SetInvisible(true);
			crossDynamic:SetInvisible(true);
			crossSize:SetInvisible(true);
			crossGapSize:SetInvisible(true);
			crossOutline:SetInvisible(true);
			dotDynamic:SetInvisible(true);
			dotSize:SetInvisible(true);
			dammageClr:SetInvisible(true);
			hitgroupClr:SetInvisible(true);
			fontSize:SetInvisible(true);
			fontName:SetInvisible(true);
			debugMultibox:SetInvisible(true);
			predictedHitboxDebug:SetInvisible(true);
		elseif hitmarkerSelection == 1 then -- Cube
			solidTime:SetInvisible(true);
			fadeTime:SetInvisible(true);
			skeletonColorLink:SetInvisible(true);
			skeletonClr:SetInvisible(true);
			hitMarkerType:SetInvisible(false);
			hitmarkerClr:SetInvisible(false);
			cubeFilled:SetInvisible(false);
			cubeSize:SetInvisible(false);
			crossDynamic:SetInvisible(true);
			crossSize:SetInvisible(true);
			crossGapSize:SetInvisible(true);
			crossOutline:SetInvisible(true);
			dotDynamic:SetInvisible(true);
			dotSize:SetInvisible(true);
			dammageClr:SetInvisible(true);
			hitgroupClr:SetInvisible(true);
			fontSize:SetInvisible(true);
			fontName:SetInvisible(true);
			debugMultibox:SetInvisible(true);
		elseif hitmarkerSelection == 2 then -- Cross
			solidTime:SetInvisible(true);
			fadeTime:SetInvisible(true);
			skeletonColorLink:SetInvisible(true);
			skeletonClr:SetInvisible(true);
			hitMarkerType:SetInvisible(false);
			hitmarkerClr:SetInvisible(false);
			cubeFilled:SetInvisible(true);
			cubeSize:SetInvisible(true);
			crossDynamic:SetInvisible(false);
			crossSize:SetInvisible(false);
			crossGapSize:SetInvisible(false);
			crossOutline:SetInvisible(false);
			dotDynamic:SetInvisible(true);
			dotSize:SetInvisible(true);
			dammageClr:SetInvisible(true);
			hitgroupClr:SetInvisible(true);
			fontSize:SetInvisible(true);
			fontName:SetInvisible(true);
			debugMultibox:SetInvisible(true);
		elseif hitmarkerSelection == 3 then -- Dot
			solidTime:SetInvisible(true);
			fadeTime:SetInvisible(true);
			skeletonColorLink:SetInvisible(true);
			skeletonClr:SetInvisible(true);
			hitMarkerType:SetInvisible(false);
			hitmarkerClr:SetInvisible(false);
			cubeFilled:SetInvisible(true);
			cubeSize:SetInvisible(true);
			crossDynamic:SetInvisible(true);
			crossSize:SetInvisible(true);
			crossGapSize:SetInvisible(true);
			crossOutline:SetInvisible(true);
			dotDynamic:SetInvisible(false);
			dotSize:SetInvisible(false);
			dammageClr:SetInvisible(true);
			hitgroupClr:SetInvisible(true);
			fontSize:SetInvisible(true);
			fontName:SetInvisible(true);
			debugMultibox:SetInvisible(true);
		end
	elseif settingSelection == 2 then -- Font
		solidTime:SetInvisible(true);
		fadeTime:SetInvisible(true);
		skeletonColorLink:SetInvisible(true);
		skeletonClr:SetInvisible(true);
		hitMarkerType:SetInvisible(true);
		hitmarkerClr:SetInvisible(true);
		cubeFilled:SetInvisible(true);
		cubeSize:SetInvisible(true);
		crossDynamic:SetInvisible(true);
		crossSize:SetInvisible(true);
		crossGapSize:SetInvisible(true);
		crossOutline:SetInvisible(true);
		dotDynamic:SetInvisible(true);
		dotSize:SetInvisible(true);
		dammageClr:SetInvisible(false);
		hitgroupClr:SetInvisible(false);
		fontSize:SetInvisible(false);
		fontName:SetInvisible(false);
		debugMultibox:SetInvisible(true);
	elseif settingSelection == 3 then -- Debug
		solidTime:SetInvisible(true);
		fadeTime:SetInvisible(true);
		skeletonColorLink:SetInvisible(true);
		skeletonClr:SetInvisible(true);
		hitMarkerType:SetInvisible(true);
		hitmarkerClr:SetInvisible(true);
		cubeFilled:SetInvisible(true);
		cubeSize:SetInvisible(true);
		crossDynamic:SetInvisible(true);
		crossSize:SetInvisible(true);
		crossGapSize:SetInvisible(true);
		crossOutline:SetInvisible(true);
		dotDynamic:SetInvisible(true);
		dotSize:SetInvisible(true);
		dammageClr:SetInvisible(true);
		hitgroupClr:SetInvisible(true);
		fontSize:SetInvisible(true);
		fontName:SetInvisible(true);
		debugMultibox:SetInvisible(false);
	end
end
-- Event handler
local function hFireGameEvent(event)
	local localPlayer = entities.GetLocalPlayer();

	if event:GetName() == "player_hurt" then
		local attacker = entities.GetByUserID(event:GetInt("attacker"));
		local victim = entities.GetByUserID(event:GetInt("userid"));
		
		if attacker:GetIndex() == localPlayer:GetIndex() and attacker:GetIndex() ~= victim:GetIndex() then
			local hitGroupInt = event:GetInt("hitgroup") + 1;
			local hitBoxVec = victim:GetHitboxPosition(hitGroupStandards[hitGroupInt]);
			local impactIndex = getClosestImpact(hitBoxVec);
			local hitPos;

			if hitGroupInt == 1 then
				hitPos = hitBoxVec;
			else
				hitPos = impacts[impactIndex];
			end

			local hitBoxVecs = {};
			local bestIndex = 0;
			if backtrackActive and hitGroupInt ~= 0 then 
				hitBoxVecs, bestindex = getClosestBackTrack(hitPos, victim:GetIndex(), conversion[hitGroupInt]);
			else
				for index = 0, 19, 1 do
					local pos = victim:GetHitboxPosition(index);
					table.insert(hitBoxVecs, pos);
				end
			end
			
			local newhit = Hit:New(event:GetInt("dmg_health"), hitGroupInt, hitPos, hitBoxVecs);
			
			table.insert(hits, newhit);
			table.remove(impacts, impactIndex);
			
			if predictedBacktrackDebug:GetValue() or predictedHitboxDebug:GetValue() or damageDebug:GetValue() or hitGroupNameDebug:GetValue() then
				print("--- Hit Information ---");
				if predictedHitboxDebug:GetValue() then
					print("Predicted Hitbox: "..conversion[hitGroupInt]);
				end
				if predictedBacktrackDebug:GetValue() then
					print("Predicted Hitbox: "..bestindex.."/"..#savedPlayers[victim:GetIndex()]);
				end
				if hitGroupNameDebug:GetValue() then
					print(hitGroupStandards[hitGroupInt]);
				end
				if damageDebug:GetValue() then
					print(event:GetInt("dmg_health").." damage");
				end
				print("-----------------------");
				print(" ");
			end
		end
	elseif event:GetName() == "bullet_impact" then
		local attacker = entities.GetByUserID(event:GetInt("userid"));
		
		if attacker:GetIndex() == localPlayer:GetIndex() then
			local impactPos = Vector3(event:GetFloat("x"), event:GetFloat("y"), event:GetFloat("z"));
			
			table.insert(impacts, impactPos);
		end
	elseif event:GetName() == "round_start" or event:GetName() == "round_prestart" then
		savedPlayers = {};
	end
end
-- Effect Draw Code
local function hDraw()	
	draw.SetFont(draw.CreateFont(fontName:GetValue(), fontSize:GetValue(), 700, {0x200}));
	guiDraw();
	
	local alpha = 255;
	for index = 1, #hits do
		if hits[index] ~= nil then
			local hit = hits[index];
			local timeOnScreen = globals.CurTime() - hit.created;
			
			if timeOnScreen > solidTime:GetValue() + fadeTime:GetValue() then
				table.remove(hits, index);
				goto continue;
			end
			
			if fadeTime:GetValue() ~= 0 then
				alpha =  math.floor(map(math.max(timeOnScreen - solidTime:GetValue(), 0), fadeTime:GetValue(), 0, 0, 255));
			end
			
			-- Player skeleton based off hitgroups
			if skeletonEffect:GetValue() then
				local r, g, b, a;
				if skeletonColorLink:GetValue() then
					r, g, b, a = gui.GetValue("esp.overlay.enemy.skeleton.clr");
				else
					r, g, b, a = skeletonClr:GetValue();
				end
				draw.Color(r, g, b, alpha);
				
				for index = 1, #playerBoneConnections do
					local BoneConnection = playerBoneConnections[index];

					local x1, y1 = client.WorldToScreen(hit.skeletonVecs[BoneConnection[1]]);
					local x2, y2 = client.WorldToScreen(hit.skeletonVecs[BoneConnection[2]]);
						
					if x1 and y1 and x2 and y2 then
						draw.Line(x1, y1, x2, y2);
					end
				end
			end
			-- Hitmarker
			if hitMarkerType:GetValue() ~= 0 then
				local selection = hitMarkerType:GetValue();
				local r, g, b, a = hitmarkerClr:GetValue();
				draw.Color(r, g, b, alpha);
					
				if selection == 1 then -- Normal Cube
					if fadeTime:GetValue() ~= 0 then
						drawCubeAtPoint(cubeSize:GetValue(), hit.pos, math.floor(map(math.max(timeOnScreen - solidTime:GetValue(), 0), fadeTime:GetValue(), 0, 0, 100)));
					else
						drawCubeAtPoint(cubeSize:GetValue(), hit.pos, 100);
					end
					
				elseif selection == 2 then -- Cross					
					if fadeTime:GetValue() ~= 0 then
						drawCrossAtPoint(crossSize:GetValue(), hit.pos, crossGapSize:GetValue(), math.floor(map(math.max(timeOnScreen - solidTime:GetValue(), 0), fadeTime:GetValue(), 0, 0, 100)));
					else
						drawCrossAtPoint(crossSize:GetValue(), hit.pos, crossGapSize:GetValue(), 100);
					end
				elseif selection == 3 then -- Dot
					drawDotAtPoint(dotSize:GetValue(), hit.pos);
				end
			end

			local hitVec = Vector2:New(client.WorldToScreen(hit.pos));
			if hitVec.x and hitVec.y then
				-- Dammage number
				if damageEffect:GetValue() then
					local hitVec = Vector2:New(client.WorldToScreen(hit.pos));
					local r, g, b, a = dammageClr:GetValue();
					draw.Color(r, g, b, alpha);
						
					if alpha == 255 then
						draw.TextShadow(hitVec.x + fontSize:GetValue(), hitVec.y, hit.dammage);
						else
						draw.Text(hitVec.x + fontSize:GetValue(), hitVec.y, hit.dammage);
					end
				end
				
				-- Hitgroup text
				if hitgroupEffect:GetValue() then
					local r, g, b, a = hitgroupClr:GetValue();
					draw.Color(r, g, b, alpha);
					local w, h = draw.GetTextSize("hitGroupText[hit.hitgroup]");
						
					if alpha == 255 then
						draw.TextShadow(hitVec.x + fontSize:GetValue(), hitVec.y + h + 2, hitGroupText[hit.hitgroup]);
					else
						draw.Text(hitVec.x + fontSize:GetValue(), hitVec.y + h + 2, hitGroupText[hit.hitgroup]);
					end
				end
			end
		end
		::continue::
	end
	impacts = {};
end

local function hCreateMove(cmd)
	-- Backtrack fix
	local localPlayer = entities.GetLocalPlayer();
	local players = entities.FindByClass("CBasePlayer");
	local fakeLatency = 0;
	local backtrackFactor = 0;
	
	if gui.GetValue("rbot.master") and gui.GetValue("rbot.accuracy.posadj.backtrack") then
		backtrackFactor = 0.4;
		backtrackActive = true;
	elseif gui.GetValue("lbot.master") and gui.GetValue("lbot.posadj.backtrack") then
		backtrackFactor = gui.GetValue("lbot.extra.backtrack") / 1000;
		backtrackActive = true;
	end
	
	if gui.GetValue("misc.master") and gui.GetValue("misc.fakelatency.enable") then
		fakeLatency = gui.GetValue("misc.fakelatency.amount");
	end
	
	for i = 1, #players do
		local player = players[i];
		local playerIndex = player:GetIndex();
		
		if player:GetTeamNumber() ~= localPlayer:GetTeamNumber() and player:IsAlive() then
			
			local playerHitBoxVecs = {};
			for index = 0, 19, 1 do
				local pos = player:GetHitboxPosition(index);
				table.insert(playerHitBoxVecs, pos);
			end
			
			if not savedPlayers[playerIndex] then
				savedPlayers[playerIndex] = {};
			end
			
			table.insert(savedPlayers[playerIndex], {playerHitBoxVecs, globals.CurTime()});
			
			for index = 1, #savedPlayers[playerIndex] do
				if savedPlayers[playerIndex][index] then
					local savedData = savedPlayers[playerIndex][index][2];
					
					if savedData + backtrackFactor + fakeLatency < globals.CurTime() then
						table.remove(savedPlayers[playerIndex], index);
					end
				end
			end
		end
	end
end

client.AllowListener("bullet_impact");
client.AllowListener("player_hurt");
client.AllowListener("round_prestart");
client.AllowListener("round_start");

callbacks.Register("CreateMove", hCreateMove);
callbacks.Register("FireGameEvent", hFireGameEvent);
callbacks.Register("Draw", hDraw);
callbacks.Register("Unload", function()
	ref2:SetInvisible(false);	
end);

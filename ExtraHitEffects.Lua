
-- Gui Setup
local ref1 = gui.Reference("Visuals", "World", "Extra");
local ref2 = gui.Reference("Visuals", "World", "Extra", "Hit Effects");
local ref3 = gui.Reference("Visuals", "World", "Extra", "Hit Effects", "Sound");
local ref4 = gui.Reference("Visuals", "World", "Extra", "Hit Effects", "Marker");
ref2:SetInvisible(true);
ref4:SetValue(false);

local multibox = gui.Multibox(ref1, "Hit Effects");

local hitMarkerType = gui.Combobox(ref1, "hitmarkertype", "Hitmarker", "Off", "Cube", "Cross", "Dot");
local dammageClr = gui.ColorPicker(ref1, "damage.clr", "Damage Color", 255, 255, 255, 255);
local hitgroupClr = gui.ColorPicker(ref1, "hitgroup.clr", "Hitgroup Color", 255, 255, 255, 255);
local hitmarkerClr = gui.ColorPicker(ref1, "hitmarker.clr", "Hitmarker Color", 255, 255, 255, 255);
local solidTime = gui.Slider(ref1, "solidtime", "Duration", 3, 0, 10, .1);
local fadeTime = gui.Slider(ref1, "fadetime", "Fade Duration", 2, 0, 10, .1);

local soundEffect = gui.Checkbox(multibox, "hiteffects.sound", "Sound", false);
local skeletonEffect = gui.Checkbox(multibox, "hiteffects.skeleton", "Skeleton", false);
local damageEffect = gui.Checkbox(multibox, "hiteffects.damage", "Damage", false);
local hitgroupEffect = gui.Checkbox(multibox, "hiteffects.hitgroup", "Hit Group", false);	

multibox:SetDescription("Effects when hitting an enemy");
hitMarkerType:SetDescription("Hitmarker style");
solidTime:SetDescription("Seconds before fading");
fadeTime:SetDescription("Seconds it takes to fade");
-- Classes and global vars
local hitGroupText = {"GENERIC", "HEAD", "CHEST", "STOMACH", "LEFT ARM", "RIGHT ARM", "LEFT LEG", "RIGHT LEG", "NECK"};
local hitGroupStandards = {"HITGROUP_GENERIC", "HITGROUP_HEAD", "HITGROUP_CHEST", "HITGROUP_STOMACH", "HITGROUP_LEFTARM", "HITGROUP_RIGHTARM", "HITGROUP_LEFTLEG", "HITGROUP_RIGHTLEG", "HITGROUP_GEAR"};
local playerBoneConnections = {{1, 2}, {2,7}, {7, 6}, {6, 5}, {5, 4}, {4, 3}, {3, 9}, {3, 8}, {9, 11}, {8, 10}, {11, 13}, {10, 12}, {7, 18}, {18, 19}, {19, 15}, {7, 16}, {16, 17}, {17, 14}};

local hits = {};
local impacts = {};
local savedPlayers = {};

local backtrackActive = false;
 -- these dont warrant sliders imo but change if you want
local cubeSize = 2;
local crossSize = 8;
local markerGap = 2;
local dotSize = 6;

local fontSize = 16;
local font = draw.CreateFont("Tahoma", fontSize, 700, {0x200})
--- Hit class
local Hit = {
    dammage = 0,
    pos = 0,
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

local function getClosestBackTrack(vec3, playerIndex)
	local bestVecs;
	local bestIndex;
	local bestDistance = math.huge;
	
	for index = 1, #savedPlayers[playerIndex] do
		if savedPlayers[playerIndex][index] then
			local hitboxVecs = savedPlayers[playerIndex][index][1];
			
			for hitboxIndex = 0, 20, 1 do
				local hitboxPos = hitboxVecs[hitboxIndex];
				if hitboxPos then
					local delta = (hitboxPos - vec3);
					local distance = delta:Length()
					
					if distance < bestDistance then
						bestDistance = distance;
						bestIndex = index;
					end
				end
			end
		end
	end
	bestVecs = savedPlayers[playerIndex][bestIndex][1];

	return bestVecs;
end

local function drawCubeFromCenter(size, vec)
	local connections = {{1, 2}, {1, 3}, {1, 5}, {8, 7}, {8, 6}, {8, 4}, {6, 3}, {4, 3}, {4, 2}, {2, 7}, {7, 5}, {6, 5}};
	local points = {};
	
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x - size, vec.y - size, vec.z - size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x - size, vec.y + size, vec.z - size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x + size, vec.y - size, vec.z - size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x + size, vec.y + size, vec.z - size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x - size, vec.y - size, vec.z + size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x + size, vec.y - size, vec.z + size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x - size, vec.y + size, vec.z + size))));
	table.insert(points, Vector2:New(client.WorldToScreen(Vector3(vec.x + size, vec.y + size, vec.z + size))));
	
	for i = 1, #connections do
		local connection = connections[i];
		local p1 = points[connection[1]];
		local p2 = points[connection[2]];
		
		draw.Line(p1.x, p1.y, p2.x, p2.y);
	end
end

local function drawCrossFromCenter(size, vec, gap)
	draw.Line(vec.x + gap, vec.y + gap, vec.x + size + gap, vec.y + size + gap);
	draw.Line(vec.x - gap, vec.y - gap, vec.x - size - gap, vec.y - size - gap);
	draw.Line(vec.x - gap, vec.y + gap, vec.x - size - gap, vec.y + size + gap);
	draw.Line(vec.x + gap, vec.y - gap, vec.x + size + gap, vec.y - size - gap);
end

local function drawDot(size, vec) 
	draw.FilledCircle(vec.x, vec.y, size*2);
end
-- Main Body
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
			if backtrackActive then 
				hitBoxVecs = getClosestBackTrack(hitPos, victim:GetIndex());
			else
				for index = 0, 19, 1 do
					local pos = victim:GetHitboxPosition(index);
					table.insert(hitBoxVecs, pos);
				end
			end
			
			local newhit = Hit:New(event:GetInt("dmg_health"), hitGroupInt, hitPos, hitBoxVecs);
			
			table.insert(hits, newhit);
			table.remove(impacts, impactIndex);
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

local function hDraw()	
	-- Effect Draw Code
	draw.SetFont(font);
	local alpha = 255;
	
	if soundEffect:GetValue() then
		ref3:SetValue(true);
	else
		ref3:SetValue(false);
	end
	
	for index = 1, #hits do
		if hits[index] ~= nil then
			local hit = hits[index];
			local timeOnScreen = globals.CurTime() - hit.created;
			
			if timeOnScreen > solidTime:GetValue() + fadeTime:GetValue() then
				table.remove(hits, index);
				goto continue;
			end
			
			local hitVec = Vector2:New(client.WorldToScreen(hit.pos));
			if hitVec.x and hitVec.y then
				if fadeTime:GetValue() ~= 0 then
					alpha =  math.floor(map(math.max(timeOnScreen - solidTime:GetValue(), 0), fadeTime:GetValue(), 0, 0, 255));
				end
				-- Dammage number
				if damageEffect:GetValue() then
					local r, g, b, a = dammageClr:GetValue();
					draw.Color(r, g, b, alpha);
					
					if alpha == 255 then
						draw.TextShadow(hitVec.x + fontSize, hitVec.y, hit.dammage);
					else
						draw.Text(hitVec.x + fontSize, hitVec.y, hit.dammage);
					end
				end
				-- Hitgroup text
				if hitgroupEffect:GetValue() then
					local r, g, b, a = hitgroupClr:GetValue();
					draw.Color(r, g, b, alpha);
					local w, h = draw.GetTextSize("hitGroupText[hit.hitgroup]");
					
					if alpha == 255 then
						draw.TextShadow(hitVec.x + fontSize, hitVec.y + h + 2, hitGroupText[hit.hitgroup]);
					else
						draw.Text(hitVec.x + fontSize, hitVec.y + h + 2, hitGroupText[hit.hitgroup]);
					end
				end
				-- Hitmarker
				if hitMarkerType:GetValue() ~= 0 then
					local selection = hitMarkerType:GetValue();
					local r, g, b, a = hitmarkerClr:GetValue();
					draw.Color(r, g, b, alpha);
					
					if selection == 1 then
						drawCubeFromCenter(cubeSize, hit.pos);
					elseif selection == 2 then
						drawCrossFromCenter(crossSize, hitVec, markerGap);
					elseif selection == 3 then
						drawDot(dotSize, hitVec);
					end
				end
				-- Player skeleton based off hitgroups
				if skeletonEffect:GetValue() then
					local r, g, b, a = gui.GetValue("esp.overlay.enemy.skeleton.clr");
					draw.Color(r, g, b, alpha);
				
					for index = 1, #playerBoneConnections do
						local BoneConnection = playerBoneConnections[index];

						local x1, y1 = client.WorldToScreen(hit.skeletonVecs[BoneConnection[1]]);
						local x2, y2 = client.WorldToScreen(hit.skeletonVecs[BoneConnection[2]]);
						
						draw.Line(x1, y1, x2, y2);
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
	local players = entities.FindByClass("CCSPlayer");
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

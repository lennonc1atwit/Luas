-- Chicken Esp By Scape#4313
--
-- Notes:
-- Change max model size to your liking (100 is stupid big)
-- Feel free to use bounding box and color converter functions in your code
-- Sadly getMins and getMaxs doesnt account for model size so boxes will not scale
local VIS_CHIK = gui.Reference('VISUALS')
local chicktab = gui.Tab(VIS_CHIK, "chicktab.tab", "Chicken ESP")

local fontSize = 12;
local font = draw.CreateFont("Consolas", fontSize);
-- Gui Setup
local menuY = 368;
local menuX = 328;

-- Esp Gui
local espRef = gui.Groupbox(chicktab, 'Chicken ESP', 305, 5, 296, 500)

local chickenBox = gui.Checkbox(espRef, "chicken_box", "Box", false);
local chickenBoxColor = gui.ColorPicker(chickenBox, "chicken_box_color", "Chicken box color", 255, 255, 255, 255);
chickenBox:SetDescription("Draw 2D box around chicken");

local chickenSkeleton = gui.Checkbox(espRef, "chicken_skeleton", "Skeleton", false);
local chickenSkeletonColor = gui.ColorPicker(chickenSkeleton, "chicken_skeleton_color", "Chicken skeleton color", 255, 255, 255, 255);
chickenSkeleton:SetDescription("Draw chicken skeleton");

local chickenLeader = gui.Checkbox(espRef, "chicken_leader", "Leader's Name",      false);
local chickenLeaderColor = gui.ColorPicker(chickenLeader, "chicken_leader_color", "Chicken name color", 255, 255, 255, 255);
chickenLeader:SetDescription("Draw leader's name");
-- Model Gui
local modelRef = gui.Groupbox(chicktab, 'Chicken Model', 5, 5, 296, 500)

local chickenColor = gui.Combobox(modelRef, 'chickenColor', 'Chicken Color','Off','Solid', 'Rainbow')
local chickenColorSolid = gui.ColorPicker(modelRef, "chickenColorSolid", "Chicken Color", 255, 255, 255, 255);
local chickenRainbowSpeed = gui.Slider(modelRef, 'chickenRainbowSpeed', 'Chicken Rainbow Speed', 1.0, 0.25, 4.0,.01)
chickenColor:SetDescription("Change color of model");

local chickenModel = gui.Combobox(modelRef, 'chicken_model', "Chicken Theme", 'Default Chicken', 'Party Chicken', 'Ghost Chicken', 'Festive Chicken', 'Easter Chicken', 'Jack-o-Chicken');
chickenModel:SetDescription("Change chicken model");

local chickenSkin = gui.Combobox(modelRef, 'lua_ChickenSkin', 'Chicken Skin','Default', 'Other')
chickenSkin:SetDescription("Change chicken skin");

local chickenScale = gui.Slider(modelRef, "chicken_scale", "Chicken Scale", 1.0, 0.25, 10.0,.01); -- Highest ive gone is 100 and things get ugly
chickenModel:SetDescription("Change chicken scale");

local chickenAnimation = gui.Combobox(modelRef, 'chickenAnimation', 'Chicken Animation','Default', 'Anti-Aim', 'Bhop', 'Come at me bro')
chickenAnimation:SetDescription("Change chicken animation");

local chickenPartyMode = gui.Checkbox(modelRef, 'chickenPartyMode', 'Party Mode', false)
chickenPartyMode:SetDescription("Enable sv_partymode 1");


--Rainbox effect
local function Rainbow()
	local speed = chickenRainbowSpeed:GetValue()
	local r = math.floor(math.sin(globals.RealTime() * speed) * 127 + 128)
	local g = math.floor(math.sin(globals.RealTime() * speed + 2) * 127 + 128)
	local b = math.floor(math.sin(globals.RealTime() * speed + 4) * 127 + 128)
	return r, g, b
end

--Color converter
local function rgbToHex(rgb)
	local hexCode = '0x'

	for key, value in pairs(rgb) do
		local nextHex = ''

		while(value > 0)do
			local index = math.fmod(value, 16) + 1;
			value = math.floor(value / 16);
			nextHex = string.sub('0123456789ABCDEF', index, index) .. nextHex;			
		end

		if(string.len(nextHex) == 0)then
			nextHex = '00';

		elseif(string.len(nextHex) == 1)then
			nextHex = '0' .. nextHex;
		end

		hexCode = hexCode .. nextHex;
	end

	return hexCode;
end

-- Box esp (p1 through p8 are points for 3d box)
local function getBoundingBox(entity)
	local origin = entity:GetAbsOrigin();
	
	local mins = entity:GetMins() + origin;
	local maxs = entity:GetMaxs() + origin;

	local p1x, p1y = client.WorldToScreen(Vector3(mins.x, mins.y, mins.z));
	local p2x, p2y = client.WorldToScreen(Vector3(mins.x, maxs.y, mins.z));
	local p3x, p3y = client.WorldToScreen(Vector3(maxs.x, maxs.y, mins.z));
	local p4x, p4y = client.WorldToScreen(Vector3(maxs.x, mins.y, mins.z));
	local p5x, p5y = client.WorldToScreen(Vector3(maxs.x, maxs.y, maxs.z));
	local p6x, p6y = client.WorldToScreen(Vector3(mins.x, maxs.y, maxs.z));
	local p7x, p7y = client.WorldToScreen(Vector3(mins.x, mins.y, maxs.z));
	local p8x, p8y = client.WorldToScreen(Vector3(maxs.x, mins.y, maxs.z));
	local points = {{p1x, p1y}, {p2x, p2y}, {p3x, p3y}, {p4x, p4y}, {p5x, p5y}, {p6x, p6y}, {p7x, p7y}, {p8x, p8y}};
	
	
	local left = points[1][1];
	local top = points[1][2];
	local right = points[1][1];
	local bottom = points[1][2];

	for i = 1, #points do
		local point = points[i];
		
		if point[1] == nil or point[2] == nil then
			return {nil, nil, nil, nil};
		end
		
		if left > point[1] then
			left = point[1];
		end
		if bottom < point[2] then
			bottom = point[2];
		end
		if right < point[1] then
			right = point[1];
		end
		if top > point[2] then
			top = point[2];
		end
	end

	return left, top, right, bottom;
end

-- Bone esp
local function ChickenBoneESP(entity)
    local chickenBoneConnections = {{37, 35}, {35, 32}, {32, 20}, {20, 0}, {0, 18}, {18, 19}, {32, 28}, {28, 29}, {29, 31}, {32, 23}, {23, 24}, {24, 26}, {0, 1}, {1, 4}, {4, 6}, {6, 8}, {0, 9}, {9, 12}, {12, 16}, {16, 15}}    
    for i = 1, #chickenBoneConnections do
        local boneGroup = chickenBoneConnections[i]
        local x1, y1 = client.WorldToScreen(entity:GetBonePosition(boneGroup[1]))
        local x2, y2 = client.WorldToScreen(entity:GetBonePosition(boneGroup[2]))
        if x1 and x2 then
            draw.Line(x1, y1, x2, y2)
        end
    end
end

-- Esp and model main
local function hDraw()
	local chickens = entities.FindByClass("CChicken");
	local enable_party = chickenPartyMode:GetValue() and 1 or 0
	local party_mode = client.GetConVar('sv_party_mode')
	
	for i = 1, # chickens do
		local chicken = chickens[i];
		
		local leader = chicken:GetPropEntity("m_leader");
		local model = chicken:GetProp("m_nBody");
		local color = chicken:GetProp('m_clrRender');
		local scale = chicken:GetProp('m_flModelScale');
		local m_nSkin = chicken:GetProp('m_nSkin')
		local m_nSequence = chicken:GetProp('m_nSequence')

		-- Box esp
		local left, top, right, bottom = getBoundingBox(chicken);
		if chickenBox:GetValue() then
			if left ~= nil and top ~= nil and right ~= nil and bottom ~= nil then
			
				local r, g, b, a = chickenBoxColor:GetValue();
			
				draw.Color(r, g, b, a);
				draw.Line(left, bottom, left, top);
				draw.Line(left, bottom, right, bottom);
				draw.Line(right, top, left, top);
				draw.Line(right, top, right, bottom);
				draw.Color(255, 255, 255, 255);
			end
		end
		
		-- Skeleton esp
		if chickenSkeleton:GetValue() then
			local r, g, b, a = chickenSkeletonColor:GetValue();
			
			draw.Color(r, g, b, a);
			ChickenBoneESP(chicken);
			draw.Color(255, 255, 255, 255);
		end
		
		-- Name esp
		if chickenLeader:GetValue() then
			
			if left ~= nil and top ~= nil and right ~= nil then
				local playerName = leader:GetName();
				local name = "Wild chicken";
				
				if playerName then
					name = playerName.."'s chicken";
				end
				
				local textW, textH = draw.GetTextSize(name);
				local centerText = textW / 2;
				local centerB = left - ((left - right) / 2);
				
				local r, g, b, a = chickenLeaderColor:GetValue();
				
				draw.Color(r, g, b, a);
				draw.TextShadow(centerB - centerText, top - fontSize, name);
				draw.Color(255, 255, 255, 255);
			end
		end
		
		-- Model changer
		if model ~= chickenModel:GetValue() then
			chicken:SetProp('m_nBody', chickenModel:GetValue())
        end
		
		--Skin changer
			if m_nSkin ~= chicken_skin then
				chicken:SetProp('m_nSkin', chicken_skin)
			end
		
		--Animation
			if chickenAnimation:GetValue() == 0 then
				elseif chickenAnimation:GetValue() == 1 then
					if m_nSequence ~= -2 then
						chicken:SetProp('m_nSequence', -2)
					end
				elseif chickenAnimation:GetValue() == 2 then
					if m_nSequence ~= 9 then
						chicken:SetProp('m_nSequence', 9)
					end
				elseif chickenAnimation:GetValue() == 3 then
					if m_nSequence ~= 7 then
						chicken:SetProp('m_nSequence', 7)
					end
			end		
		
		-- Chams
		if chickenColor:GetValue() == 0 then
			chickenColorSolid:SetInvisible(true)
			chickenRainbowSpeed:SetInvisible(true)		
			if color ~= white then
				chicken:SetProp('m_clrRender', 0xFFFFFF);
			end

			elseif 	 chickenColor:GetValue() == 1 then
			chickenColorSolid:SetInvisible(false)
			chickenRainbowSpeed:SetInvisible(true)		
			local r, g, b, a = chickenColorSolid:GetValue();
			local chickenHex = rgbToHex({b,g,r});
			if color ~= chickenHex then
				chicken:SetProp('m_clrRender', chickenHex);
			end
			
			elseif 	 chickenColor:GetValue() == 2 then
			chickenColorSolid:SetInvisible(true)
			chickenRainbowSpeed:SetInvisible(false)		
			local chickenHex = rgbToHex({Rainbow()});
			if color ~= chickenHex then
				chicken:SetProp('m_clrRender', chickenHex);
			end

		else
		end
		
		-- Scale changer
		if scale ~= chickenScale:GetValue() then
			chicken:SetProp('m_flModelScale', chickenScale:GetValue())
        end
	end
	
	if party_mode ~= enable_party then
		client.SetConVar('sv_party_mode', enable_party, true)
	end

end
callbacks.Register("Draw", hDraw);

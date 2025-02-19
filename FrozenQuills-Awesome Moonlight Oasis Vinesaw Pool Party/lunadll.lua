local colliders = API.load("colliders");
local hit = false;
local angle = 0;
local positions = {};
local dTheta = 0.03;
 
local left = 700;
local right =  800 - left;
local up = 400;
local down = 800 - up;
local speed = 1.4;

local textblox = API.load("textblox");
textblox.npcPresets[156] = textblox.PRESET_SIGN


function setNpcSpeed(npcid, speed)
   local p = mem(0x00b25c18, FIELD_DWORD) -- Get the pointer to the NPC speed array
   mem(p + (0x4 * npcid), FIELD_FLOAT, speed)
end

local tt = 0
local blue = Graphics.loadImage("bluelights.png");
local red = Graphics.loadImage("redlights.png");
local green = Graphics.loadImage("greenlights.png");
local yellow = Graphics.loadImage("yellowlights.png");
local interval = 200;

local lightsVal = 0;

function onTick()
	if(player.section == 0 or player.section == 1 or player.section == 4 or player.section == 5) then
		tt = tt + 1;
		if tt >= 1000 then
			tt = 0;
		end
	end
end

local maxop = 0.6;
local maxheight = -180000;
local minheight = -179808;

function onDraw()
	if(player.section == 0 or player.section == 1 or player.section == 4 or player.section == 5) then
		local s = tt % interval;
		local op = maxop;
		
		if(player.section == 1) then 
			
			local height = math.clamp(player.y, maxheight, minheight);
			op = maxop * (height-minheight) / (maxheight - minheight);
		end
		
		if (s < interval/4) then
			Graphics.drawImage(blue,0,0,op);
		elseif s >= interval/4 and s < interval/2 then
			Graphics.drawImage(yellow,0,0,op);
		elseif s >= interval/2 and s < (interval*3)/4 then
			Graphics.drawImage(green,0,0,op);
		else
			Graphics.drawImage(red,0,0,op);
		end
	end
end
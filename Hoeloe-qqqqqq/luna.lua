local eventu = API.load("eventu");
local pnpc = API.load("pnpc");
local colliders = API.load("colliders");
local rng = API.load("rng");

local Q_L = Graphics.loadImage(Misc.resolveFile("q.png"));
local Q_S = Graphics.loadImage(Misc.resolveFile("q_s.png"));

local Q_Star = Graphics.loadImage(Misc.resolveFile("Qstar.png"));

local qheads = {}
for i=1,2 do
	qheads[i] = Graphics.loadImage(Misc.resolveFile("q-"..i..".png"))
end
local qdeath = Graphics.loadImage(Misc.resolveFile("death-q.png"));

local paused = false;
local Qdone = false;

local Qs = {}
local Qtrails = {}
local maxQtrails = 8000;
local trailPointer = 1;
local qHeads = {}

local first = true;

local firstQ = false;
local warpQ = false;

local speechPos = 1;

local switchhits = 0;

local levelend = false;

local noisechunk = nil;
local noisechannel = 17;
local stopNoise = false;
local noiseVol = 0;

local noiseTime = 5;

local powerupCache = 0;
local boxCache = 0;

local floorfall = false;

local spikesTimer;

local function setPlayerQ(isQhead)
	if(isQhead) then
		for i=1,2 do
			Graphics.sprites.mario[i].img = qheads[i];
		end
		Graphics.sprites.effect[3].img = qdeath;
	else
		Graphics.sprites.effect[3].img = nil;
		Player.setCostume(CHARACTER_MARIO, nil, true)
		Player.setCostume(CHARACTER_MARIO, "Demo-Centered", true)
	end
end

function onStart()
	noisechunk = Audio.SfxOpen("noise.ogg");
	Audio.SfxVolume(17,0);
	noisechannel = Audio.SfxPlayCh(17, noisechunk, -1);
	
	Graphics.sprites.npc[97].img = Q_Star;
	
	eventu.setTimer(noiseTime/128,
	function()
		if(stopNoise) then 
			Audio.SfxStop(noisechannel);
			eventu.breakTimer();
		else
			noiseVol = noiseVol + 1;
			if(noiseVol > 128) then
				noiseVol = 128;
			end
			Audio.SfxVolume(noisechannel,noiseVol);
		end
	end, true);
	
	eventu.setTimer(noiseTime, 
	function()	
		stopNoise = true;
		MusicOpen("q.ogg");
		player.x = -199936;
		player.y = -200160 - player:mem(0xD0,FIELD_DFLOAT) + 32;
		player:mem(0x15A,FIELD_WORD,0);
		Player.setCostume(CHARACTER_MARIO, "Demo-Centered", true)
		
		if(player.reservePowerup > 0) then
			boxCache = player.reservePowerup
			player.reservePowerup = 0;
		end
		if(player.powerup > PLAYER_BIG) then
			powerupCache = player.powerup;
			player.powerup = PLAYER_BIG;
			player:mem(0x16C, FIELD_BOOL, false);
			player:mem(0x16E, FIELD_BOOL, false);
			player:mem(0x120, FIELD_WORD, 0);
		end
	end);
end

function onLoadSection2()
	setPlayerQ(false);
	MusicStopFadeOut(1);
	eventu.setTimer(0.5,function() triggerEvent("Serac1"); end);
end

function onLoadSection3()
	Qs = {};
	Graphics.sprites.npc[97].img = nil;
end

local startTrail = -190592;
local endTrail = -189280;
local function getTrailTimer()
	if(player.section ~= 0 or player.x < startTrail) then
		return -1;
	else
		return math.ceil(math.lerp(15, 1, math.clamp((player.x - startTrail)/(endTrail - startTrail)),0,1));
	end
end

local function createQ()
				local hor = rng.randomInt(2) == 1;
				local tl = rng.randomInt(2) == 1;
				local minx = -5;
				local maxx = 5;
				local miny = -5;
				local maxy = 5;
				
				
				local c = Camera.get()[1];
				
				local x;
				
				if(not hor) then
					if(tl) then
						x = c.x - 32;
						minx = 0;
					else
						x = c.x+c.width + 32;
						maxx = 0;
					end
				else
					x = rng.random(0,c.width) + c.x;
				end
				
				local y;
				
				if(hor) then
					if(tl) then
						y = c.y - 32;
						miny = 0;
					else
						y = c.y + c.height + 32;
						maxy = 0;
					end
				else
					y = rng.random(0, c.height) + c.y;
				end
				
				local sx = math.random(minx,maxx);
				local sy = math.random(miny,maxy);
				while(sx == 0 and sy == 0) do
					sx = math.random(minx,maxx);
					sy = math.random(miny,maxy);
				end
				
				return { x = x, y = y, speedX = sx, speedY = sy, trails = {}, trailtimer = getTrailTimer()};
end

local function spawnQ()
	table.insert(Qs, createQ());
end

local function updateQs()
	local c = Camera.get()[1]
	
	--[[for i = #Qtrails,1,-1 do
		local v = Qtrails[i];
		if(v.x > c.x + c.width or v.x < c.x - 32 or
		   v.y > c.y + c.height or v.y < c.y - 32) then
			table.remove(Qtrails[i]);
			trailPointer = #Qtrails + 1;
		end
	end]]
	for k,v in ipairs(Qs) do
		if(not paused) then
			if(v.trailtimer > 0) then
				v.trailtimer = v.trailtimer-1;
				if(v.trailtimer == 0) then
					v.trailtimer = getTrailTimer();
					
					Qtrails[trailPointer] = {x = v.x, y = v.y};
					trailPointer = (trailPointer%maxQtrails)+1;
				end
			end
			v.x = v.x + v.speedX;
			v.y = v.y + v.speedY;
			if(v.x > c.x + c.width + 128 or v.x < c.x - 128 or
				v.y > c.y + c.height + 128 or v.y < c.y - 128) then
				Qs[k] = createQ();
			end
		end
	end
end

local trailverts = {};
local trailtxs = {};

local function drawQs()
	local i = 1;
	for _,v in ipairs(Qtrails) do
		trailverts[i], 		trailverts[i+1] 	= v.x, 		v.y;
		trailverts[i+2], 	trailverts[i+3] 	= v.x+32, 	v.y;
		trailverts[i+4], 	trailverts[i+5] 	= v.x, 		v.y+32;
		trailverts[i+6], 	trailverts[i+7]		= v.x, 		v.y+32;
		trailverts[i+8], 	trailverts[i+9]		= v.x+32, 	v.y;
		trailverts[i+10], 	trailverts[i+11] 	= v.x+32, 	v.y+32;
		
		trailtxs[i], 	trailtxs[i+1] 	= 0, 0;
		trailtxs[i+2], 	trailtxs[i+3] 	= 1, 0;
		trailtxs[i+4], 	trailtxs[i+5] 	= 0, 1;
		trailtxs[i+6], 	trailtxs[i+7]	= 0, 1;
		trailtxs[i+8], 	trailtxs[i+9]	= 1, 0;
		trailtxs[i+10], trailtxs[i+11] 	= 1, 1;
		
		i = i+12;
	end
	
	for j=#trailverts,i,-1 do
		table.remove(trailverts,i);
		table.remove(trailtxs,i);
	end
	
	Graphics.glDraw{vertexCoords = trailverts, textureCoords=trailtxs, sceneCoords = true, texture = Q_S, priority = -70};
	
	for k,v in ipairs(Qs) do
		Graphics.drawImageToSceneWP(Q_S,v.x,v.y,-70);
	end
end

local function splitQ(newID, size, base)
			Animation.spawn(125,base.x+size/2,base.y+size/4);
			Audio.playSFX(61);
			local x = base.x;
			local y = base.y;
			eventu.setFrameTimer(5, function()
				local l = NPC.spawn(newID,x-size,y+size/2, player.section);
				local r = NPC.spawn(newID,x+size,y+size/2, player.section);
			end);
end

local splits = {[117] = {118, 64, 0.75}, [118] = {120, 32, 1}, [119] = {117, 128, 0.25}}

function onNPCKill(event, npc, reason)
	if(splits[npc.id]) then
		local size = splits[npc.id][2];
		splitQ(splits[npc.id][1], size, npc);
	elseif(npc.id == 120) then
		Animation.spawn(63,npc.x+8,npc.y+4);
		Audio.playSFX(61);
	end
end

local function updateSplitQs()
	for k,v in ipairs(NPC.get({120, 118, 117, 119},player.section)) do
		local speed;
		local size;
		if(v.id == 120) then
			speed = 2;
			size = 16;
		elseif(splits[v.id]) then
			speed = splits[v.id][3];
			size = splits[v.id][2];
		end
		
		if(player.x + player.width*0.5 < v.x+size) then
			v.speedX = math.lerp(v.speedX,-speed,0.2);
			v.direction = DIR_LEFT;
		elseif(player.x + player.width*0.5 > v.x+size) then
			v.direction = DIR_RIGHT;
			v.speedX = math.lerp(v.speedX,speed,0.2);
		else
			v.speedX = 0;
		end
		if(player.y + player.height*0.5 > v.y+size) then
			v.speedY = math.lerp(v.speedY,speed,0.2);
		elseif(player.y + player.height*0.5 < v.y+size) then
			v.speedY = math.lerp(v.speedY,-speed,0.2);
		else
			v.speedY = 0;
		end
	end
end


local function updateFallingQs()
	for _,v in ipairs(NPC.get(79,player.section)) do
		local w = pnpc.wrap(v)
		if(w.data.shake == nil or w.data.shake == 0) then
			w.x = w:mem(0xA8, FIELD_DFLOAT);
		end
		if(w.data.fallen == nil) then
			w.data.fallen = false;
			w.data.shake = 0;
		end
		if(w:mem(0x0A,FIELD_WORD) == 2) then
			w.speedY = 0;
			playSFX(37);
		end
		if(w.data.fallen and w.data.shake ~= 0) then
			w.x = w:mem(0xA8, FIELD_DFLOAT) + w.data.shake;
			w.data.shake = -w.data.shake;
		end
		if(not w.data.fallen) then
			w.y = w:mem(0xB0, FIELD_DFLOAT);
		end
		if(not w.data.fallen and math.abs(player.x - w.x) < 96) then
			w.data.fallen = true;
			w.data.shake = 4;
			eventu.setTimer(0.4, 
			function()
				w.data.shake = 0;
				w.speedY = 16;
			end);
		end
		if(colliders.collide(player,colliders.Box(w.x,w.y+48,32,16))) then
			player:harm();
		end
		
		local innerBox = colliders.Box(w.x+12,w.y+12,8,8);
		if(colliders.collide(player,innerBox) and player:mem(0x140,FIELD_WORD) < 120 and player:mem(0x122,FIELD_WORD) ~= 2 and player:mem(0x13E, FIELD_WORD) == 0) then
					player:kill();
		end;
	end
end

local function updateSpeech()
	if(player.section ~= 1) then return; end;
	
	if(player.x > -179700 + speechPos*600) then
		triggerEvent("Speech"..speechPos);
		speechPos = speechPos + 1;
	end
end

function onExitLevel()
	if(boxCache > 0) then
		player.reservePowerup = boxCache;
	end
	if(powerupCache > player.powerup) then
		player.powerup = powerupCache;
	end
end

function onTick()
	if(spikesTimer ~= nil) then
		if(player:mem(0x122,FIELD_WORD) == 0 or player:mem(0x122,FIELD_WORD) == 7 or player:mem(0x122,FIELD_WORD) == 500) then
			eventu.resumeTimer(spikesTimer);
		else
			eventu.pauseTimer(spikesTimer);
		end
	end
	
	if(player.section == 4) then return; end;
	if(first) then
			for i=0,10,1 do
				spawnQ();
			end
			first = false;
	
			for _,v in ipairs(NPC.get(94,player.section)) do
				if(v.x > -195200) then -- and v.x < -193600) then
					table.insert(qHeads,pnpc.wrap(v));
				end
			end
			
			table.sort(qHeads, function(a,b) return a.x < b.x; end);
	end
	
	if(player:mem(0x13E,FIELD_WORD) > 0 or winState() ~= 0) then
			MusicStopFadeOut(1);
	end
	
	
	updateQs();
	
	updateSplitQs();
	
	updateFallingQs();
	
	updateSpeech();
	
	for _,v in ipairs(NPC.get({97, 89, 94},player.section)) do
		--Star
		if(v.id == 97 and player.section == 1) then
			if(not levelend and colliders.speedCollide(player,v)) then
				triggerEvent("FinalSpeech");
				levelend = true;
			end
		--RinkQ
		elseif(v.id == 89) then
			local b,s = colliders.bounce(player,v);
			if(b and s) then
				colliders.bounceResponse(player);
			elseif(colliders.collide(player,v)) then
				player:harm();
			end
			if(v.speedY == 0) then
				v.speedY = 1.5;
			end
			local speed = 1;
			if(v.collidesBlockBottom) then
				v.speedY = -speed;
			end
			if(v.collidesBlockLeft) then
				v.direction = -v.direction
				v.speedX = speed;
			end
			if(v.collidesBlockUp) then
				v.speedY = speed;
			end
			if(v.collidesBlockRight) then
				v.direction = -v.direction
				v.speedX = -speed;
			end
		--Q-head
		elseif(v.id == 94) then
			if(player.x < v.x) then
				v.direction = DIR_LEFT;
			elseif(player.x > v.x) then
				v.direction = DIR_RIGHT;
			end
		end
	end
	
	--Initial Q
	if(player.section == 0 and player.x > -199200 and not paused and not Qdone) then
		paused = true;
		Misc.pause();
		Defines.levelFreeze=true;
		eventu.run(	function() 
						eventu.waitSeconds(1.38, true);
						MusicPlay();
						eventu.waitSeconds(1.62, true);
						Misc.unpause();
						Defines.levelFreeze=false;
						paused = false;
						Qdone = true;
					end);
	end
	
	if(player.section == 3) then
		if(not floorfall) then
			eventu.setTimer(1, function()
				Defines.earthquake = 16;
				Audio.playSFX("smash.ogg");
			end);
			floorfall = true;
		end
	end
end

function onDraw()
	drawQs();
	
	if(paused and not Qdone) then
		Graphics.drawImageWP(Q_L,0,0,4);
	end
end

function onEvent(name)
	if(name == "BecomeQ") then
		if(not firstQ) then
			eventu.setFrameTimer(64, function() 
										setPlayerQ(true);
										eventu.setTimer(1, function() setPlayerQ(false); end);
									 end);
			firstQ = true;
		end
		qHeads[6].msg = string.gsub(qHeads[6].msg.str,"%a","q");
	end
	
	for i=1,8,1 do
		if(name == "SpeakQhead"..i) then
			qHeads[i].msg = string.gsub(qHeads[i].msg.str,"%a","q");
			break;
		end
	end
	
	if(name == "SpeakQhead9") then
		if(not warpQ) then
			eventu.setTimer(3, 
			function() 
				player:mem(0x15A,FIELD_WORD,1);
				player.x = player.x + 8992;
				player.y = player.y + 20000;
				MusicStopFadeOut(0);
				triggerEvent("freedom");
				MusicPlay();
			end);
			warpQ = true;
		end
		qHeads[9].msg = string.gsub(qHeads[9].msg.str,"%a","q");
	end
	
	if(name == "Speech5") then
			setPlayerQ(true);
			eventu.setTimer(1, function() setPlayerQ(false); end);
	end
	
	if(name == "Speech7") then
			setPlayerQ(true);
			eventu.setTimer(0.75, function() setPlayerQ(false); end);
			eventu.setTimer(1.25, function() setPlayerQ(true); end);
			eventu.setTimer(1.5, function() setPlayerQ(false); end);
	end
	
	if(name == "Speech9") then
			setPlayerQ(true);
			eventu.setTimer(0.5, function() setPlayerQ(false); end);
			eventu.setTimer(0.75, function() setPlayerQ(true); end);
			eventu.setTimer(1, function() setPlayerQ(false); end);
			eventu.setTimer(1.15, function() setPlayerQ(true); end);
			eventu.setTimer(1.25, function() setPlayerQ(false); end);
	end
	
	if(name == "Speech10") then
			eventu.setTimer(1, function() setPlayerQ(true); end);
	end
	
	if(switchhits < 4) then
		if(name == "Switch1") then
			if(switchhits == 2) then
				switchhits = 3;
			else
				switchhits = 0;
			end
		end
		if(name == "Switch2") then
			if(switchhits == 0) then
				switchhits = 1;
			else
				switchhits = 0;
			end
		end
		if(name == "Switch3") then
			if(switchhits == 3) then
				switchhits = 4;
				triggerEvent("showdoor");
			else
				switchhits = 0;
			end
		end
		if(name == "Switch4") then
			if(switchhits == 1) then
				switchhits = 2;
			else
				switchhits = 0;
			end
		end
	end
	
	if(name=="Serac4") then
		local l = findlayer("Spikes");
		l.speedY = 0.5;
		MusicOpen("q2.ogg");
		MusicPlay();
		spikesTimer = eventu.setFrameTimer(16*(32/l.speedY), 
			function()
				l.speedY = 0;
				MusicStopFadeOut(1);
				playSFX(37);
				triggerEvent("Rescue1");
			end);
	end
	
	if(name=="LevelEnd1") then
		eventu.setFrameTimer(lunatime.toTicks(4), function()
			winState(1);
		end);
	end
end
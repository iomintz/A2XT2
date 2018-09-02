local rng = API.load ("rng")


local darkness = API.load("darkness")


function round(num) 
    if num >= 0 then return math.floor(num+.5) 
    else return math.ceil(num-.5) end
end

local encroach = 40
local bun = 0
local yeah = 0
local moon = 0
local stars = 0
local dense = 1.0
local musak = 97
local framecount = 0
local nextLoop = 5

local imgIndex = 1
local topsArray, sidesArray = {}, {}

for  i=1,5  do
	topsArray[i] = Graphics.loadImage("tops"..tostring(i)..".png")
	sidesArray[i] = Graphics.loadImage("sides"..tostring(i)..".png")
end

local tops = topsArray[imgIndex]
local sides = sidesArray[imgIndex]

local full = Graphics.loadImage("full.png")
local lamp = Graphics.loadImage("lamp.png")

local field = darkness.Create{falloff=Misc.resolveFile("falloff_jitter.glsl"), uniforms = {noise = Graphics.loadImage("noise.png"), time = 0}, sections={0,2,3,4}}
local plight = darkness.Light(0,0,0,1,Color.white);
field:AddLight(plight);

function onStart()
	Audio.SeizeStream(-1)
	plight:Attach(player);
end


function boolDefault (args)
	local returnval
	
	i = 1;
	while  i <= #args  do
		if  args[i] ~= nil  then
			returnval = args[i]
			break;
		else
			i = i+1
		end
	end
	
	return returnval;
end


function manageDarkness (props)
	local controlAudio = boolDefault {props.controlAudio, true}
	local shrinkIfDead = boolDefault {props.shrinkIfDead, true}
	local useMoon = boolDefault {props.useMoon, false}
	local altAudio = boolDefault {props.altAudio, false}
	local superShrink = boolDefault {props.superShrink, false}
	local showWhiteCircle = boolDefault {props.showWhiteCircle, true}
	local shrinkRate = props.shrinkRate  or  0.08
	local growRate = props.growRate  or  0.02
		
	encroach = props.forcedVal  or  encroach
	
	local lampTouched = false
	
	
	-- RANDOM DARKNESS FRAMES
	framecount = (framecount + 1) % nextLoop
	
	if  framecount == 0  then
		local oldIndex = imgIndex
		
		while oldIndex == imgIndex  do
			imgIndex = rng.randomInt (1, #topsArray)
		end

		tops = topsArray [imgIndex]
		sides = sidesArray [imgIndex]
		nextLoop = rng.randomInt (5,15)
	end
	
	if(lunatime.tick()%8 == 0) then
		field.uniforms.time = field.uniforms.time + 1;
	end
	plight.radius = (150-encroach)/150 * 760;
	--[[
	--CREATE DARKNESS
	--bottom
		Graphics.drawImageToScene (tops,player.x - (134 + encroach),player.y + player.height - 32 + (166 - (encroach*2.45)))

	--top
		Graphics.drawImageToScene (tops,player.x - 760 + (166 + encroach),player.y + player.height - 32 - 1440 - (134 - (encroach*2.45)))

	--left
		Graphics.drawImageToScene (sides,player.x - 760 - (134 - (encroach*2.45)),player.y + player.height - 32 - (134 + encroach))

	--right	
		Graphics.drawImageToScene (sides,player.x + (166 - (encroach*2.45)),player.y + player.height - 32 - 1440 + (166 + encroach))
]]
	--	Text.print(encroach,400,300)

	
	--DARKNESS ABATED WHEN TOUCH LAMP
	for _, b in pairs (BGO.getIntersecting(player.x, player.y, player.x + player.width, player.y + player.height)) do
		if (b.id == 95 or b.id == 96) then
			encroach = encroach - (encroach * growRate)
			lampTouched = true
		end
	end

	
	-- MOON MANAGEMENT
	if  (useMoon)  then
		if  moon == false  then  lampTouched = true;  end;
	end
	
	
	--DRAW WHITE CIRCLE FOR LAMP
	if (not lampTouched)  and  showWhiteCircle  then
		for _, b in pairs(BGO.get()) do
			if (b.id == 96) then
				Graphics.drawImageToSceneWP(lamp,b.x,b.y,1.1)
			end
		end
	end

	
	--TIGHTEN CIRCLE
	if (encroach < 150 and not lampTouched) then
		if  superShrink  then
			encroach = encroach + (encroach * shrinkRate)
		else
			encroach = encroach + shrinkRate
		end
	end

	if (encroach < 40) then
		encroach = 40
	end

	
	if  controlAudio  then
		if  altAudio  then
			if (encroach > 65 and encroach < 130) then
			Audio.MusicVolume(round(0 + ((encroach - 65) * 1.5)))
			elseif (encroach > 130) then
			Audio.MusicVolume(round(97.5))
			end
		else
			--AUDIO STUFF
			if (encroach > 85 and encroach < 130) then
				Audio.MusicVolume(100 - ((encroach - 85) * 2))
			elseif (encroach > 130) then
				Audio.MusicVolume(5)
			end
		end
		
		if (Audio.MusicIsPlaying () == -1) then
			Audio.MusicPlay ()
		end
	end
	
	
	if  shrinkIfDead  then
		--DEAD
		if (player:mem (0x13E,FIELD_WORD) ~= 0) then
			Audio.MusicStop ()
	--		Graphics.drawImage(full,0,0)
			if (encroach < 150) then
				encroach = encroach + 2.5
			end
		end
	end
end



function onLoopSection0 ()
	manageDarkness {}
end


function onLoadSection1 ()
	Audio.MusicOpen ("banditcamp2.ogg")
	Audio.MusicPlay ()
	Audio.MusicVolume (100)
end


function onLoopSection1 ()
	-- If the player dies, stop the music
	if (player:mem(0x13E,FIELD_WORD) ~= 0) then
		Audio.MusicStop ()
	end
end

function onLoopSection2 ()
	local bun = 40 + ((player.y + 160000) / 16.8)
	manageDarkness {forcedVal = bun}
end


function onLoadSection3()
	Audio.MusicOpen ("noise.ogg")
	Audio.MusicVolume (0)
	Audio.MusicPlay ()
end

function onLoopSection3()
	manageDarkness {showWhiteCircle=false, shrinkIfDead=false}
end


function onLoadSection4()
	Audio.MusicStop()
end

function onLoopSection4()
	manageDarkness {}
end



function onLoadSection5 ()
	encroach = 150
	Audio.MusicOpen ("noise.ogg")
	Audio.MusicVolume (round(97.5))
	Audio.MusicPlay ()
end

function onLoopSection5 ()
	manageDarkness {superShrink=true, growRate=0.08, shrinkRate=0.08, shrinkIfDead=false, useMoon=true, altAudio=true}
end




function onEvent(eventname)
	if eventname == "axe" then
		moon = 1
	elseif eventname == "curtain" then
		stars = 1
	end
end




--OUTER SPACE STUFF !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
function onLoopSection7 ()
	if (stars == 0) then
		if (musak >= 0) then
			Audio.MusicVolume(round(musak))
			musak = musak - 0.25
		elseif (musak < 0) then
			Audio.MusicStop()
		end
	end

	if (dense > 0) then
		Graphics.drawImage(full,0,0,dense)
		if (stars == 1) then
			Audio.MusicOpen("wilderness2.ogg")
			Audio.MusicVolume(100)
			Audio.MusicPlay()
			dense = dense - 0.001
		end
	end
end

function onLoopSection6 ()
	if (dense > 0) then
		Graphics.drawImage (full,0,0,dense)
		dense = dense - 0.001
	end
end





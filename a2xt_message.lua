local npcManager = API.load("npcManager")
local textblox = API.load("textblox")
local animatx = API.load("animatx")
local cman = API.load("cameraman")
local eventu = API.load("eventu")
local imagic = API.load("imagic")
local pnpc = API.load("pnpc")
local colliders = API.load("colliders")
local defs = API.load("expandedDefines")
--local console = API.load("console")

local rng = API.load("rng")

local a2xt_settings = API.load("a2xt_settings")
local a2xt_hud = API.load("a2xt_hud")
local a2xt_pause = API.load("a2xt_pause")
local a2xt_scene = API.load("a2xt_scene")
local a2xt_voice = API.load("a2xt_voice")
local a2xt_message = {}

local messageInvincibile = 0;


function a2xt_message.onInitAPI()
	registerEvent (a2xt_message, "onStart", "onStart", false)
	registerEvent (a2xt_message, "onTick", "onTick", false)
	registerEvent (a2xt_message, "onCameraDraw", "onCameraDraw", false)
	registerEvent (a2xt_message, "onDraw", "onDraw", false)
	registerEvent (a2xt_message, "onMessageBox", "onMessageBox", false)
	
	registerCustomEvent(a2xt_message, "onMessageEnd");
	registerCustomEvent(a2xt_message, "onMessage");
end


textblox.presetProps[textblox.PRESET_BUBBLE].borderTable = {
                                                            ulImg   = textblox.IMGREF_BUBBLE_BORDER_UL,
                                                            uImg    = textblox.IMGREF_BUBBLE_BORDER_U,
                                                            urImg   = textblox.IMGREF_BUBBLE_BORDER_UR,
                                                            rImg    = textblox.IMGREF_BUBBLE_BORDER_R,
                                                            drImg   = textblox.IMGREF_BUBBLE_BORDER_DR,
                                                            dImg    = textblox.IMGREF_BUBBLE_BORDER_D,
                                                            dlImg   = textblox.IMGREF_BUBBLE_BORDER_DL,
                                                            lImg    = textblox.IMGREF_BUBBLE_BORDER_L,
                                                            thick   = 16
                                                           }
textblox.presetProps[textblox.PRESET_BUBBLE].xMargin = 0
textblox.presetProps[textblox.PRESET_BUBBLE].yMargin = 8

textblox.presetProps[textblox.PRESET_SIGN].instant = true

textblox.presetProps[4] = table.join(
                                     {borderTable={col=0x00000000}, boxColor=0x00000000},
                                     table.clone(textblox.presetProps[textblox.PRESET_BUBBLE])
                                    )
textblox.presetProps[5] = table.join(
                                     {boxType=nil,
                                      borderTable={
                                                   ulImg   = Graphics.loadImage(Misc.resolveFile("graphics/HUD/speakerBorderUL.png")),
                                                   uImg    = textblox.IMGREF_BUBBLE_BORDER_U,
                                                   urImg   = Graphics.loadImage(Misc.resolveFile("graphics/HUD/speakerBorderUR.png")),
                                                   rImg    = textblox.IMGREF_BUBBLE_BORDER_R,
                                                   drImg   = Graphics.loadImage(Misc.resolveFile("graphics/HUD/speakerBorderDR.png")),
                                                   dImg    = textblox.IMGREF_BUBBLE_BORDER_D,
                                                   dlImg   = Graphics.loadImage(Misc.resolveFile("graphics/HUD/speakerBorderDL.png")),
                                                   lImg    = textblox.IMGREF_BUBBLE_BORDER_L,
                                                   thick   = 16,
                                                   col     = 0xFFFFFFFF
                                                  },
                                     tailTex = Graphics.loadImage(Misc.resolveFile("graphics/HUD/speakerTail.png"))},
                                     table.clone(textblox.presetProps[textblox.PRESET_BUBBLE])
                                    )


--***************************
--** Variables             **
--***************************
local iconSeqs = {[1]="2p2,3,4,5", [2]="2p2,3,4,5", [3]="2p2,3,4,5", [4]="2p2,3,4,5", [5]="2p2,3,4p2,5", [6]="2p2,3,4p2,3"}
local iconSet = animatx.Set {sheet=Graphics.loadImage(Misc.resolveFile("graphics/HUD/icon_talk.png")), states=6, frames=5, sequences=iconSeqs}

local uiFont = A2XT_FONT_MAIN

local lastNameWidth = -8

local nameBarName = ""
local nameBarFade = 0

local thoughtBubbleImg = Graphics.loadImage(Misc.resolveFile("graphics/HUD/thoughtBubble.png"))
local thoughtBubbleBallImg = Graphics.loadImage(Misc.resolveFile("graphics/HUD/thoughtBubbleBall.png"))

local playerScreenX,playerScreenY = 0,0
local playerSideX,playerSideY = 0,0

local blipSound = Audio.SfxOpen(Misc.resolveFile("sound/grab.ogg"))
local confirmSound = Audio.SfxOpen(Misc.resolveFile("sound/message.ogg"))

local blockablenpclist = {};

-- Prompt stuff
a2xt_message.promptChoiceStr = ""
a2xt_message.promptChoice = 0
a2xt_message.promptChosen = false

-- "Wait for"-related variables
local mostRecentMessage = nil

-- Dialogue logging
local textLogLimit = 50
if  SaveData.textLog == nil  then
	SaveData.textLog = {}
end

-- Presets
a2xt_message.type = {bubble=textblox.PRESET_BUBBLE, system=textblox.PRESET_SYSTEM, sign=textblox.PRESET_SIGN, textonly=4, intercom=5}


-- Add strings and functions to this table indexed by a keyword and use that keyword as the newMsg string
a2xt_message.presetSequences = {}
a2xt_message.presetSequences._multipageTest = "Beginning multi-page test.<page>AAAAAAAAAAAAAAAA<page>AAAAAAAAAAAAAAAAAAAA<page>AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA<page>*inhales*<page>AAAAAAAAAAoh hi there<page>Test concluded.  Check the message API's presetSequences._multipageTest to see the code for this sequence."

local yesTable = {"Sure","K","Arrighty","ACCEPT","Radicola","Yeh","Okie doke","Aw HELL yea","Neat beans","Sure","Sure, why not","YES","All of my yes","Totes","Okay","I guess","Great!","Awesome!","Heck yeah!","Fully approve.","This pleases me","I'm down with it.","Righteous","I see no problem with this.","Meh, whatever.","*Shake excitedly*","I feel good about this.","Full steam ahead!","*sigh*, if I have to...","Aye me bucko","You have my attention","Oh, very much so.","Most definitely","Yes yes yes yes yes yes yes","*nod solemnly*","Supersauce","*resigning nod*","I'm leaning yes","My mind says no but my heart says yes","Jump up, superstar"};
local noTable = {"Lame.","Nah","No","NO","Are you serious...?","no no no no no no no no no","Don't","Do not","Do not want","DECLINE","*growl in contempt*","I dunno...","NO. BAD.","MAKE IT STOP","Nnnnnnope!","Goodbye!","NEGATIVE","STRONGLY DISAGREE","DECLINE","*Excessive display of disapproval*","Maybe next time","Downright bogus","Negatory, good buddy","Who put you on the planet?","Think of the consequences, you fool!","How about no?","Count me out.","No. Just, no.","I don't even","Never.","You will regret this.","*piercing gaze*","Despair engulfs me.","why","Do I have to answer that?","A curse upon thee!","*Exaggerated gesture of disgust*"}
local cancelTable = {"Never mind.","On second thought...","This was a mistake!","I changed my mind","Opt out","*Immediate regret*","Okay, let's not","Common sense just kicked in","Wait, I'm a dumb","Forget it"}--,"Wait, did you really think I was going to do that thing?  Well, you were WRONG.  Don't ever judge a book by its cover."}


function a2xt_message.getYesOption()
	return rng.irandomEntry(yesTable);
end

function a2xt_message.getNoOption()
	return rng.irandomEntry(noTable);
end

function a2xt_message.getCancelOption()
	return rng.irandomEntry(cancelTable);
end

a2xt_message.presetSequences._promptTest = function(args)
	local talker = args.npc

	a2xt_message.promptChosen = false
	a2xt_message.showMessageBox {target=talker, type="bubble", text="Now testing the prompt system."}
	a2xt_message.waitMessageEnd()

	-- PROMPT 1: YES/NO
	a2xt_message.showMessageBox {target=talker, type="bubble", text="If options are not specified for a prompt, a basic YES or NO choice is provided.<br>The text for the two options are randomly selected.", closeWith="prompt", instant=true}
	--a2xt_message.waitMessageDone()

	a2xt_message.showPrompt()
	a2xt_message.waitPrompt()

	a2xt_message.showMessageBox {target=talker, type="bubble", text="You responded with option "..tostring(a2xt_message.promptChoice)..":<br>"..a2xt_message.promptChoiceStr}
	a2xt_message.waitMessageEnd()

	-- PROMPT 2:  MULTIPLE-CHOICE, BRANCHING
	a2xt_message.promptChosen = false
	a2xt_message.showMessageBox {target=talker, type="bubble", text="The options in this prompt are manually defined.", closeWith="prompt"}
	a2xt_message.waitMessageDone()

	a2xt_message.showPrompt{options={"Option 1","Option 2","Choice 3","Item D","Option 5","This is a unique branch"}}
	a2xt_message.waitPrompt()

	if  a2xt_message.promptChoice == 6  then
		a2xt_message.showMessageBox {target=talker, type="bubble", text="You picked the unique branch so I'mma do an extra thing now."}
		a2xt_message.waitMessageEnd()

		cman.playerCam[1]:Queue {time=1, angle=90, easeBoth=cman.EASE.QUAD}
		cman.playerCam[1]:Queue {time=1, angle=-90, easeBoth=cman.EASE.QUAD}
		cman.playerCam[1]:Queue {time=0.5, angle=0, easeBoth=cman.EASE.QUAD}
		eventu.waitSeconds(3)
	else
		a2xt_message.showMessageBox {target=talker, type="bubble", text="You responded with option "..tostring(a2xt_message.promptChoice)..":<br>"..a2xt_message.promptChoiceStr}
		a2xt_message.waitMessageEnd()
	end

	a2xt_message.showMessageBox {target=talker, type="bubble", text="Test concluded.  Check the message API's presetSequences._promptTest to see the code for this sequence."}
	a2xt_message.waitMessageEnd()
	eventu.waitSeconds(0.1)
	
	--windowDebug("Test")
	a2xt_scene.endScene()
end

--***************************
--** Utility Functions     **
--***************************
local function quickparse_perchar(a)
	local t = a:sub(2,-2):split("/");
	return t[player.character] or t[1];
end

function a2xt_message.quickparse(msg)
	if(isTownLevel()) then
		return (msg:gsub("(%b[])", quickparse_perchar))
	else
		return msg;
	end
end


local function logText (text, name)
	if  #SaveData.textLog > textLogLimit  then
		table.remove(SaveData.textLog, 1)
	end
	table.insert(SaveData.textLog, {text=text,name=name})
end


local function addItem (str, item)
	local newStr = string.gsub(str, "%[item%]", item)
	return newStr;
end
local function getItemList (ids, names, prices)
	local options = {}
	for  i=1,#ids  do
		local id = ids[i]
		options[i] = names[id].." ("..tostring(prices[id]).."rc)"
	end
	return options
end


local function lerp (minVal, maxVal, percentVal)
	return (1-percentVal) * minVal + percentVal*maxVal;
end
local function invLerp (minVal, maxVal, amountVal)
	return  (amountVal-minVal) / (maxVal - minVal)
end
local function uiBox (args)
	return a2xt_hud.window (args)
end



--***************************
--** Coroutines            **
--***************************
local function cor_talkZoomIn (args)
	-- Zoom the camera in
	while (cman.playerCam[1] == nil)  do
		eventu.waitFrames(0, true)
	end
	local cam = cman.playerCam[1]
	cam:Transition {time=0.75, targets={player, {x=args.npc.x+args.npc.width*0.5, y = args.npc.y+args.npc.height*0.5}}, zoom=1.4, easeBoth=cman.EASE.QUAD, runWhilePaused = true}
end
local function cor_talkZoomOut()
	while (cman.playerCam[1] == nil)  do
		eventu.waitFrames(0)
	end
	local cam = cman.playerCam[1]

	-- End the cutscene and zoom back out
	cam:Transition {time=0.5, targets={player}, zoom=1, easeBoth=cman.EASE.QUAD}
end

local function checkForSpace(player, npc, range, direction, dbg)
	local px,py = npc.x+npc.width*0.5, player.y;
	local blockList = nil;
	local npcList = nil;
	if(direction == 1) then
		local castbox = colliders.Box(npc.x+npc.width*0.5, player.y, range + player.width, player.height);
		blockList = colliders.getColliding{a = castbox, b = defs.BLOCK_SOLID, btype=colliders.BLOCK};
		npcList = colliders.getColliding{a = castbox, b = blockablenpclist, btype=colliders.NPC};
	else
		local castbox = colliders.Box(npc.x+npc.width*0.5 - range - player.width, player.y, range + player.width, player.height)
		blockList = colliders.getColliding{a = castbox, b = defs.BLOCK_SOLID, btype=colliders.BLOCK};
		npcList = colliders.getColliding{a = castbox, b = blockablenpclist, btype=colliders.NPC};
	end
	blockList = table.append(blockList, npcList);
	if(#blockList > 0) then
		for i = 1,3 do
			py = py + player.height * 0.25;
			local b, p, n, obj = colliders.raycast({px,py}, {direction * range, 0}, blockList, dbg or false)
			if(b and (math.abs(n.x) > 0.65 or obj.y <= player.y-16)) then
				return false;
			end
		end
	end
	return true;
end

local function cor_positionPlayer (args)
	local npc = args.npc
	if  npc ~= nil  then  npc = pnpc.wrap(npc);  end;

	-- Move player into position
	local d = 0
	local settings = npcManager.getNpcSettings(npc.id);
	local range = (settings.talkrange or 32);
	
	local l = checkForSpace(player, npc, range, -1)
	local r = checkForSpace(player, npc, range, 1)
	local timeout = lunatime.toTicks(0.5);
	if(l or r) then
		--old radial distance
		--[[while (math.abs(d) < range and timeout > 0)  do
			local dx = (npc.x+npc.width*0.5) - (player.x+player.width*0.5);
			local dy = (npc.y+npc.height*0.5) - (player.y+player.height*0.5);
			d = math.sqrt(dx*dx + dy*dy)]]
		while (math.abs(d) < range and timeout > 0)  do
			d = (npc.x+npc.width*0.5) - (player.x+player.width*0.5);
			
			local noturn = settings.noturn or npc.data.noturn;
			if(not noturn) then
				if  l and (player.x + player.width*0.5 <= npc.x + npc.width*0.5 or not r) then
					npc.direction = -1
				elseif r and (player.x + player.width*0.5 > npc.x + npc.width*0.5 or not l)  then
					npc.direction = 1
				end
			end
			
			if((not r or player.x + player.width*0.5 <= npc.x + npc.width*0.5 or (noturn and npc.direction == -1)) and l) then
				player.speedX = -2
				player:mem(0x106, FIELD_WORD, -1)
			elseif  (r)  then
				player.speedX = 2
				player:mem(0x106, FIELD_WORD, 1)
			else --we ain't going anywhere
				break;
			end
			timeout = timeout - 1;
			eventu.waitFrames(0)
		end
	end
	
	player.speedX = 0
	
	if  (player.x + player.width*0.5 < npc.x + npc.width*0.5)  then
		player:mem(0x106, FIELD_WORD, 1)
	elseif  (player.x + player.width*0.5 > npc.x + npc.width*0.5)  then
		player:mem(0x106, FIELD_WORD, -1)
	end
	
	eventu.waitSeconds(0.25)
	eventu.signal("playerPositioned")
end

local function cor_cleanupAfterNPC (args)
	while (a2xt_scene.inCutscene) do
		eventu.waitFrames(0)
	end
	eventu.run (cor_talkZoomOut)
end

local talkNPC = nil;

local function cor_talkToNPC (args)
	-- PNPC wrap the npc
	local npc = args.npc;
	if  npc ~= nil  then  
		npc = pnpc.wrap(npc);

		-- Zoom the camera in and position the player
		eventu.run (cor_talkZoomIn, args)
		eventu.run (cor_positionPlayer, args)
		eventu.waitSignal("playerPositioned")
	end
	
	if(not isOverworld and freezesWhileTalking()) then
		Misc.pause();
	end
	messageInvincibile = 32;

	if  npc ~= nil  then  
		-- Start the cleanup routine
		eventu.run(cor_cleanupAfterNPC)
	end
	
	a2xt_message.promptChosen = false;

	-- Check for indexed cutscenes or message strings
	local extMessage;
	if  npc ~= nil  then  
		extMessage = a2xt_message.presetSequences[npc.data.event]
	end
	if  type(extMessage) == "function"  then

		local t = string.trim(args.text);
		if(#t < 1) then
			t = nil;
		end
		-- Run the new cutscene
		a2xt_scene.startScene {interrupt=true, scene=extMessage, sceneArgs={npc=npc, text=t}}

	else
		local messageText = args.text
		if  type(extMessage) == "string"  then
			messageText = extMessage
		end

		-- Start the message box
		local bubble;
		if  npc ~= nil  then  
			bubble = a2xt_message.showMessageBox {target=npc, x=npc.x,y=npc.y, text=messageText}
		else
			bubble = a2xt_message.showMessageBox{x=400, y=300, text=messageText, screenSpace = true}
		end
		
		while (not bubble.deleteMe) do
			eventu.waitFrames(0, true)
		end
		
		a2xt_message.endMessage();
		
		a2xt_scene.endScene()
	end
	talkNPC = npc;
end

local function getBubbleTarget(obj)
	local x,y = obj.x + obj.width*0.5, obj.y + obj.height*0.5;
	if(obj.__type == "NPC") then
		x = x + NPC.config[obj.id].gfxoffsetx*(-obj.direction)
	end
	return x,y
end

local function cor_manageMessage(bubbleTarget, bubble)

	-- Log the pages
	local pagesLogged = 0

	local condType = bubbleTarget.closeWith  or  "default"
	local conditionMet = false

	while  (not conditionMet)  do
		local conditions = {
		                    default = bubble.deleteMe,
		                    prompt  = a2xt_message.promptChosen
		                   }
		
		conditionMet = conditions[condType] or conditions[default]
		---[[
		local cam = cman.playerCam[1]
		if  cam ~= nil  then
			if  bubbleTarget.obj ~= nil  then
				local screenX,screenY = cam:SceneToScreenPoint (getBubbleTarget(bubbleTarget.obj))

				local offYOverride = bubbleTarget.offY
				if  bubbleTarget.obj ~= player  then
					offYOverride = offYOverride - (42 * cam.zoom)
				end


				bubbleTarget.x = screenX + cam.cam.x + bubbleTarget.offX
				bubbleTarget.y = screenY + cam.cam.y + offYOverride
				

				if(bubbleTarget.keepOnscreen) then
					local wid,hei = bubbleTarget.obj.width, bubbleTarget.obj.height;
					local origx,origy = bubbleTarget.x,bubbleTarget.y
					bubbleTarget.x = math.max(math.min(bubbleTarget.x, cam.zoomedRight-wid),cam.zoomedLeft+wid);
					bubbleTarget.y = math.max(math.min(bubbleTarget.y , cam.zoomedBottom-hei),cam.zoomedTop+hei);
					local maxDist = 32;
					if(math.abs(bubbleTarget.x - origx) > maxDist or math.abs(bubbleTarget.y - origy) > maxDist) then
						bubble.hasTail = false;
					else
						bubble.hasTail = bubbleTarget.hasTail;
					end
				else
					bubble.hasTail = bubbleTarget.hasTail;
				end
			end
			--]]
			--windowDebug(tostring(bubbleTarget.x).."/n"..tostring(bubble.x))
			
			if(bubbleTarget.screenSpace) then
				bubbleTarget.x = bubbleTarget.initialArgs.x + cam.cam.x
				bubbleTarget.y = bubbleTarget.initialArgs.y + cam.cam.y
			end
			-- Log each page as it happens
			if  pagesLogged < bubble.latestPage  then
				if(bubble.voiceclips ~= nil and bubble.voiceclips[bubble.latestPage]) then
					a2xt_voice.Play(a2xt_voice.char[bubble.voice], bubble.voiceclips[bubble.latestPage]);
				elseif(bubble.voiceclip) then
					a2xt_voice.Play(a2xt_voice.char[bubble.voice], bubble.voiceclip);
				end
				
				pagesLogged = bubble.latestPage
				logText (bubble.pages[pagesLogged], bubbleTarget.name)
			end
		end

		--Text.dialog("doneyo")
		eventu.waitFrames(0, true)
	end
	-- Close the bubble now that the conditions have been met
	if  (not bubble.deleteMe)  then
		bubble:closeSelf ()
	end
end


--***************************
--** API Member Functions  **
--***************************

function a2xt_message.dumpTextLog ()
	if  SaveData.textLog ~= nil  then

		local currentName = SaveData.textLog[1].name
		local textLogFile = io.open ("dialogueDump.txt", "w")
		textLogFile:write(currentName..":")

		for  _,v in ipairs(SaveData.textLog)  do
			-- Write the current name
			if  v.name ~= currentName  then
				local nameStr = v.name  or  ""
				textLogFile:write("\n\n"..nameStr..":")
				currentName = v.name
			end
			textLogFile:write("\n"..v.text)
		end
	end
end

function a2xt_message.textLogToConsole ()
	if  SaveData.textLog ~= nil  then

		local currentName = SaveData.textLog[1].name
	--	console.print(currentName..":")

		for  _,v in ipairs(SaveData.textLog)  do
			-- Write the current name
			if  v.name ~= currentName  then
				local nameStr = v.name  or  ""
			--	console.print(" ")
			--	console.print(nameStr..":")
				currentName = v.name
			end
			--console.print(v.text)
		end
	end
end


function a2xt_message.perCharString(args)
	if  type(args) == "string"  then
		return quickparse_perchar(args)
	else
		return ""
	end
end

function a2xt_message.endMessage()
	if(Misc.isPausedByLua()) then
		Misc.unpause();
	end
	a2xt_pause.Unblock();
end

--[[showMessageBox args:
	strings: text,closeWith(auto,prompt)
	objects: target
	bools:   keepOnscreen,hasTail,screenSpace,instant,inputClose,inputProgress
	enums:   type
	numbers: x,y,width,height,offX,offY,finishDelay
	tables:  bloxProps
--]]
function a2xt_message.showMessageBox (args)
	if  type(args) ~= "table"  then
		args = {text=args}
	end


	-- Get the preset to use + indirect target management to account for offsets from camera manipulation
	local presetToUse = textblox.npcPresets.all
	local messageCtrl = {
	                     name      = nameBarName,
	                     obj       = args.target,
	                     x         = args.x          or  300,
	                     y         = args.y          or  400,
	                     offX      = args.offX       or  0,
	                     offY      = args.offY       or  0,
	                     closeWith = args.closeWith,
	                     keepOnscreen = args.keepOnscreen or false,
	                     hasTail = args.hasTail,
	                     screenSpace = args.screenSpace or false,
	                     initialArgs = args,
	                    }

	if(messageCtrl.hasTail == nil) then 
		messageCtrl.hasTail = true
	end

	-- Determine preset and logged name based on target
	if  args.target ~= nil  then
		messageCtrl.x = args.target.x + messageCtrl.offX
		messageCtrl.y = args.target.y + messageCtrl.offY

		-- If the target is an NPC, determine the preset based on the target's NPC ID
		if  args.target.__type == "NPC"  then
			presetToUse = textblox.npcPresets[args.target.id]  or  presetToUse

			-- If the target is an NPC, also try and get the NPC's name for the text logger
			local ptarget = pnpc.wrap(args.target)
			if  ptarget.data.name ~= nil  then
				messageCtrl.name = ptarget.data.name
			end

		-- If the target is a player, get the player character
		elseif  args.target.__type == "Player"  then
			messageCtrl.name = CHARACTER_NAME[args.target.character]
		end
	else
		presetToUse = a2xt_message.type.sign
	end
	if  args.type ~= nil  then
		presetToUse = a2xt_message.type[args.type]  or  presetToUse
	end

	-- Copy properties from preset + any additional ones specified in the arguments
	local props = {}
	for  k,v in pairs (textblox.presetProps[presetToUse])  do
		props[k] = v
	end

	props.trackTarget    = messageCtrl
	props.pauseGame      = false
	props.z              = 2

	for  _,v in ipairs{"width","height","speed","instant","inputClose","inputProgress","finishDelay"}  do
		props[v] = args[v]  or  props[v]
	end
	
	if(args.screenSpace) then
		props.bind = textblox.BIND_SCREEN
	else
		props.bind = textblox.BIND_SCENE
	end

	if  args.closeWith ~= nil  then
		props.inputClose = false
		if  args.closeWith == "auto"  then
			props.inputProgress = false
			props.autoClose = true
		end
	end

	if  args.bloxProps ~= nil  then
		for  k,v in pairs (args.bloxProps)  do
			props[k] = v
		end
	end

	-- Provide default text
	local text = args.text  or  props.text  or  "NO TEXT SPECIFIED"

	-- Handle all special tags
	text = string.gsub(text, "(%[price%s*)(%d*)(%])", function (a,b,c)
		return b.."rc"
	end)


	-- Create a textblox block and set up some management/reference stuff
	local bubble = textblox.Block (messageCtrl.x,messageCtrl.y, text, props)
	
	messageCtrl.hasTail = bubble.hasTail;
	
	bubble.closeSound = "sound/text-next.ogg"
	bubble.finishSound = ""
	bubble.typeSounds = {"sound/text-blip1.ogg", "sound/text-blip2.ogg"}
	bubble.typeSoundChunks = {};
	
	for  k,v in pairs (bubble.typeSounds)  do
		bubble.typeSoundChunks[k] = Audio.SfxOpen (textblox.getPath (v))
	end
	
	bubble.voice = args.voice or "default";
	bubble.voiceclips = args.voiceclips;
	bubble.voiceclip = args.voiceclip;
	
	if  args.closeWith == "auto"  then
		bubble.closeSound = "";
		bubble.finishSound = "";
		if((args.startSound ~= nil or (bubble.typeSounds ~= nil and #bubble.typeSounds > 0)) and #text < 10) then
			Audio.playSFX(textblox.getPath (args.startSound or rng.irandomEntry(bubble.typeSounds)));
			bubble.typeSounds = {};
		end
	end
	
	eventu.run (cor_manageMessage, messageCtrl, bubble)
	mostRecentMessage = bubble

	-- Return the newly-created bubble
	return bubble
end
function a2xt_message.showPrompt(args)
	if  args == nil  then  args = {};  end;
	
	a2xt_message.promptChoice = 0
	local options = args.options  or  {a2xt_message.getYesOption(), a2xt_message.getNoOption()}


	a2xt_message.promptChoice = 1
	a2xt_message.promptChosen = false
	a2xt_message.promptChoiceStr = ""


	local optionsShown = args.optionsShown  or  #options
	local topOption = 1
	local maxTopOption = #options-optionsShown+1

	local fullStr = options[1]
	if  #options > 1  then
		for i=2,optionsShown  do
			fullStr = fullStr.."<br>"..options[i]
		end
	end

	local barWidth, barHeight = textblox.printExt (fullStr, {x=-2000,y=0,z=0.1, alpha=bga, font=uiFont, halign=textblox.ALIGN_MID,valign=textblox.ALIGN_MID})
	barWidth = barWidth+110
	barHeight = barHeight+60

	local sideX = args.sideX  or  playerSideX
	local sideY = args.sideY  or  playerSideY

	local barX = 400 - sideX*(350 - 0.5*barWidth)
	local barY = 300 - sideY*(250 - 0.5*barHeight)

	local maxScrollTicks = 15
	local scrollTickDelay = 7
	local scrollTicks = 0

	eventu.run (function()

		cman.playerCam[1]:Transition {time=0.75, xOffset=-barWidth*0.25*sideX, easeBoth=cman.EASE.QUAD}
		eventu.waitSeconds(0.5)
		while (not a2xt_message.promptChosen) do

			-- Scroll handling
				if  math.abs(scrollTicks) == maxScrollTicks  then
					local scrollSign = scrollTicks/math.abs(scrollTicks)
					scrollTicks = scrollTicks - (scrollSign*scrollTickDelay)
				end

				if  not a2xt_scene.currInputs.up  and  not a2xt_scene.currInputs.down  then
					scrollTicks = 0
				elseif  a2xt_scene.currInputs.up  then
					scrollTicks = scrollTicks-1

				elseif  a2xt_scene.currInputs.down  then
					scrollTicks = scrollTicks+1
				end


			-- Cursor movement
				if      (a2xt_scene.currInputs.up  and  not a2xt_scene.prevInputs.up)  or  scrollTicks == -maxScrollTicks  then
					Audio.SfxPlayObj(blipSound,0)
					a2xt_message.promptChoice = math.max(1, a2xt_message.promptChoice-1)
					a2xt_message.promptChoiceStr = options[a2xt_message.promptChoice]
					if  a2xt_message.promptChoice == topOption  then
						topOption = math.max(1, topOption-1)
					end

				elseif  (a2xt_scene.currInputs.down  and  not a2xt_scene.prevInputs.down)  or  scrollTicks == maxScrollTicks  then
					Audio.SfxPlayObj(blipSound,0)
					a2xt_message.promptChoice = math.min(#options, a2xt_message.promptChoice+1)
					a2xt_message.promptChoiceStr = options[a2xt_message.promptChoice]
					if  a2xt_message.promptChoice == topOption + optionsShown-1  then
						topOption = math.min(topOption+1, maxTopOption)
					end

				elseif  a2xt_scene.currInputs.left  and  not a2xt_scene.prevInputs.left  then
					Audio.SfxPlayObj(blipSound,0)
					a2xt_message.promptChoice = 1
					a2xt_message.promptChoiceStr = options[1]
					topOption = 1

				elseif  a2xt_scene.currInputs.right  and  not a2xt_scene.prevInputs.right  then
					Audio.SfxPlayObj(blipSound,0)
					a2xt_message.promptChoice = #options
					a2xt_message.promptChoiceStr = options[a2xt_message.promptChoice]
					topOption = maxTopOption
				end


				-- Confirm
				if  a2xt_scene.currInputs.jump  and  not a2xt_scene.prevInputs.jump  then
					Audio.SfxPlayObj(confirmSound,0)
					a2xt_message.promptChosen = true
					cman.playerCam[1]:Transition {time=0.75, xOffset=0, easeBoth=cman.EASE.QUAD}

					-- Log the player's choice
					logText (a2xt_message.promptChoiceStr, CHARACTER_NAME[player.character])

					--eventu.signal ("_promptEnded")
				end

				-- Draw the options and stuff
				if  (not a2xt_message.promptChosen)  then
					for  i=1,8  do
						local timeLoop = ((lunatime.tick()+i*32)/256)%1
						local bubbleBall = imagic.Create{primitive=imagic.TYPE_BOX, 
						                                 x=lerp(playerScreenX,barX, 0.1 + 0.9*timeLoop),
						                                 y=lerp(playerScreenY,barY, timeLoop) + 10*math.sin(math.rad(-270*timeLoop)),
						                                 width=lerp(0,30, timeLoop),
						                                 height=lerp(0,30, timeLoop),
						                                 align=imagic.ALIGN_CENTRE,
						                                 texture=thoughtBubbleBallImg,
						                                 scene=false
						                                };
						bubbleBall:Draw {priority=0.9, colour=0xFFFFFFFF}
					end

					local timeLoop = (lunatime.tick()/256)%1
					local xAdd,yAdd = 8*math.sin(math.rad(360*timeLoop)), 8*math.sin(math.rad(90 + 360*timeLoop))
					local optionsBar = uiBox{image=thoughtBubbleImg, x=barX+xAdd, y=barY+yAdd, width=barWidth,height=barHeight}
					optionsBar:Draw{priority=6, colour=0xFFFFFFFF, bordercolour=0xFFFFFFFF};

					
					for  j=1,optionsShown  do
						local i = j+topOption-1
						local optionStr = options[i]
						if  a2xt_message.promptChoice == i  then
							optionStr = "<color rainbow><lt><wave 2> "..optionStr.." <wave 0><color rainbow><gt>"
						end
						local textAlpha = 1
						if  (j == 1  and  topOption ~= 1)  or  (j == optionsShown  and  topOption < maxTopOption)  then
							textAlpha = 0.5
						end
						textblox.printExt (optionStr, {x=barX+xAdd, y=barY + yAdd - 0.5*barHeight + 10 + j*(uiFont.charHeight*uiFont.scaleY + uiFont.leading), z=7, alpha=textAlpha, color=0x000000FF, font=uiFont, halign=textblox.ALIGN_MID,valign=textblox.ALIGN_MID})
					end
				end

				eventu.waitFrames(0)
			end
		end
	)
end

function a2xt_message.waitMessageDone(message)
	if  message == nil  then
		message = mostRecentMessage
	end
	local messageStillExists = true

	eventu.run (function ()
		while (messageStillExists)  do
			messageStillExists = (message ~= nil)
			if  messageStillExists  then
				messageStillExists = not (message.currentPage >= #message.pages  and  message.finished)
			end

			eventu.waitFrames(0)
		end
		eventu.signal("_messageDone")
	end)

	return eventu.waitSignal("_messageDone")
end
function a2xt_message.waitMessagePage(message, page)
	if  message == nil  then
		message = mostRecentMessage
	end
	local messageStillExists = true

	eventu.run (function ()
		while (messageStillExists)  do
			messageStillExists = (message ~= nil)
			if  messageStillExists  then
				messageStillExists = not (message.currentPage >= page)
			end

			eventu.waitFrames(0, true)
		end
		eventu.signal("_messageDone")
	end)

	return eventu.waitSignal("_messageDone")
end
function a2xt_message.waitMessageEnd(message, canResumeWhilePaused)
	if  message == nil  then
		message = mostRecentMessage
	end
	local messageStillExists = true

	eventu.run (function ()
		while (messageStillExists)  do
			messageStillExists = (message ~= nil)
			if  messageStillExists  then
				messageStillExists = not message.deleteMe
			end

			eventu.waitFrames(0, canResumeWhilePaused)
		end
		eventu.signal("_messageEnd")
	end)

	return eventu.waitSignal("_messageEnd")
end
function a2xt_message.waitPrompt()
	eventu.run(function ()
		while (not a2xt_message.promptChosen)  do
			eventu.waitFrames(0)
		end
		eventu.waitSeconds(0.35)
		eventu.signal("_promptEnded")
	end)


	return eventu.waitSignal("_promptEnded")
end

local nameBarObj = nil;


--***************************
--** Events                **
--***************************
function a2xt_message.onStart()
	blockablenpclist = table.iclone(defs.NPC_ALL);
	for i = #blockablenpclist,1,-1 do
		if(defs.NPC_POWERUP_MAP[blockablenpclist[i]] or defs.NPC_MOUNT_MAP[blockablenpclist[i]] or (NPC.config[blockablenpclist[i]].nohurt and not NPC.config[blockablenpclist[i]].playerblock)) then
			table.remove(blockablenpclist, i);
		end
	end
end

function a2xt_message.onTick()
	if(not a2xt_scene.inCutscene and talkNPC) then
		a2xt_message.onMessageEnd(talkNPC);
		Misc.unpause();
		talkNPC = nil;
	end
	
	if(messageInvincibile > 0) then
		messageInvincibile = messageInvincibile - 1;
		player:mem(0x140, FIELD_WORD, 2);
		player:mem(0x142, FIELD_WORD, 0);
		if(messageInvincibile == 0) then
			player:mem(0x140, FIELD_WORD, 0);
		end
	end
end

function a2xt_message.onDraw()
		--Text.print(tostring(player:mem(0x10A, FIELD_WORD)), 20, 300)
		
		if  a2xt_scene.inCutscene or nameBarName == nil or nameBarName == "" then
			nameBarFade = 0
		else
			local bgalpha = 0.75;
			local bga = math.floor(nameBarFade*bgalpha*255);

			local transitionSpeed = 0.5;
			
			local y = 300 + 150*playerSideY;
			if(nameBarObj ~= nil) then
				y = lerp(nameBarObj.y, 300 + 150*playerSideY, transitionSpeed);
			end
			local strWidth = textblox.printExt (nameBarName, {x=400,y=y,z=0.1, alpha=bga, font=uiFont, halign=textblox.ALIGN_MID,valign=textblox.ALIGN_MID})

			if(nameBarObj == nil) then
				nameBarObj = uiBox {x=400,y=300 + 150*playerSideY, width=strWidth+80, height=70}
			end
			nameBarObj.x = 400
			nameBarObj.y = y
			nameBarObj.border.x = nameBarObj.x;
			nameBarObj.border.y = nameBarObj.y;
			nameBarObj:Draw{priority=0.01, colour=0x07122700+bga, bordercolour = 0xFFFFFF00+bga};
		end
end


function a2xt_message.onCameraDraw(camindex)
	if(camindex > 1) then return end;
	
	-- Free reference to the most recent message if necessary
	if  mostRecentMessage ~= nil  then
		if  mostRecentMessage.destroyMe  then
			mostRecentMessage = nil
		end
	end

	-- Other stuff
	local lastNameBar = nameBarName;
	nameBarName = ""

	local closestNpc = a2xt_message.getTalkNPC()
	local cam = Camera.get()[1]
	local excam = cman.playerCam[1]
	if  excam ~= nil  then
		playerScreenX,playerScreenY = excam:SceneToScreenPoint (player.x+player.width*0.5, player.y+player.height-32)
		playerSideX, playerSideY = (400-playerScreenX)/math.abs(400-playerScreenX), (300-playerScreenY)/math.abs(300-playerScreenY)
	end

	if  closestNpc ~= nil  and  not a2xt_scene.inCutscene  then
		nameBarFade = math.min (nameBarFade+0.2, 1)
	else
		nameBarFade = math.max (nameBarFade-0.2, 0)
	end


	-- Main icon update loop
	if  not a2xt_scene.inCutscene  then
		for  k,v in ipairs (NPC.getIntersecting(cam.x-48, cam.y-64, cam.x+cam.width+64, cam.y+cam.height+64))  do
			-- If the NPC qualifies
			v = pnpc.wrap(v)
			if(v.id == 979) then --Is a chest
				v.msg = " ";
			else
				if(v.data) then --Is not a generator
					if(v.data.event and v.msg == "") then
						v.msg = " ";
					end
					if  v.friendly  and  v.msg ~= nil and v.msg ~= "" and  not v.isHidden  and  not v:mem(0x64, FIELD_BOOL)  then
						

						--A2XT quick-parse
						if(v.data.name == nil and isTownLevel()) then
							local nm,msg = v.msg:match("^([^{}]+):%s*(.+)$");
							if(nm ~= nil and msg ~= nil) then
								v.data.name = nm;
								v:mem(0x4C, FIELD_STRING, msg);
							end
						end
						
						-- Initialize the pnpc data
						if  v.data.a2xt_message == nil then
							v.data.a2xt_message = {
												   iconSpr = iconSet:Instance {x=v.x+v.width*0.5, y=v.y-(v.data.iconOffset or 0), z=1, alpha=0, state=v.data.talkIcon or 1, scale=2, speed=0, yAlign=animatx.ALIGN.BOTTOM, sceneCoords=false, visible=true},
												   talkedTo = false,
												   currScale = 1
												  }
						end

						-- Alpha based on distance
						local data = v.data.a2xt_message

						data.delete = false
						data.iconSpr.x = v.x+v.width*0.5+NPC.config[v.id].gfxoffsetx*(-v.direction)
						data.iconSpr.y = v.y-(v.data.iconOffset or 8)

						if  excam ~= nil  then
							data.iconSpr.x, data.iconSpr.y =  excam:SceneToScreenPoint(data.iconSpr.x, data.iconSpr.y)
						end
						
						local dx = (v.x+v.width*0.5) - (player.x+player.width*0.5);
						local dy = (v.y+v.height*0.5) - (player.y+player.height*0.5);
						local d = math.sqrt(dx*dx + dy*dy)

						if  (v.msg ~= nil  and  v.msg ~= "")  or  v.data.scene ~= nil  or  v.data.routine ~= nil  then
							data.iconSpr.alpha = lerp(0.4, 1, math.max(0, invLerp(256,16, d)))

							-- UI changes when player is adjacent;  swell icon, name bar
							if  v == closestNpc  and  d < 48  then
								if  v.data.name ~= nil then
									nameBarName = v.data.name
									if(lastNameBar ~= v.data.name) then
										nameBarObj = nil;
									end
								end
								data.currScale = math.min(2, data.currScale+0.2)
							else
								data.currScale = math.max(1, data.currScale-0.2)
							end

							if  data.currScale >= 1.5  then
								if  data.iconSpr.frame == 1  then  data.iconSpr.frame = 2;  end;
								data.iconSpr.speed = 1
								data.iconSpr.scale = data.currScale
								if(data.iconSpr.state == 4 and v.data.price) then
									textblox.printExt (v.data.price, {x=data.iconSpr.x + 2,y=data.iconSpr.y - 52,z=1, alpha=bga, font=textblox.FONT_SPRITEDEFAULT3X2, halign=textblox.ALIGN_MID,valign=textblox.ALIGN_MID})
								end
							else
								data.iconSpr.frame = 1
								data.iconSpr.speed = 0
								data.iconSpr.scale = 2*data.currScale
							end
						end
						
						data.iconSpr:Draw();
					end
				end
			end
		end
	end
end

function a2xt_message.getTalkNPC()
	local best = nil;
	local distance = math.huge;
	for _,v in ipairs(NPC.getIntersecting(player.x,player.y,player.x+player.width,player.y+player.height)) do
		if(v:mem(0x44,FIELD_BOOL)) then
			local dx = (v.x+v.width*0.5) - (player.x+player.width*0.5);
			local dy = (v.y+v.height*0.5) - (player.y+player.height*0.5);
			if(dx*dx + dy*dy < distance) then
				best = v;
			end
		end
	end
	
	if  best ~= nil  then
		best = pnpc.wrap(best)
	end
	return best;
end

function a2xt_message.talkToNPC(npc, message)
	if  not a2xt_scene.inCutscene  then
		if(npc ~= nil) then
			message = message or a2xt_message.quickparse(tostring(npc.msg));
		end
		messageInvincibile = 999999;
		a2xt_scene.startScene{scene=cor_talkToNPC, sceneArgs={npc=npc, text=message}, noletterbox=(npc==nil)}
		a2xt_pause.Block();
	end
	
	a2xt_message.onMessage(npc, message);
end

function a2xt_message.onMessageBox(eventObj, message)
	if(eventObj.cancelled) then return end;
	local npc = nil;
	if(player.upKeyPressing) then
		npc = a2xt_message.getTalkNPC();
	end
	
	a2xt_message.talkToNPC(npc, a2xt_message.quickparse(message));
	eventObj.cancelled = true
end
--[[
function a2xt_npcs.onMessage (eventObj, message, npc)
end]]



return a2xt_message
local imagic = API.load("imagic")
local eventu = API.load("eventu")

local leveldata = API.load("a2xt_leveldata")
local message = API.load("a2xt_message")
local scene = API.load("a2xt_scene")
local archives = API.load("a2xt_archives")
local bgm = API.load("a2xt_bgm")

local pendSpr = Graphics.loadImage("pendulum.png")
local reflections = Graphics.CaptureBuffer(800,600);

local sanctuary = API.load("a2xt_leeksanctuary");
sanctuary.world = 3;


Block.config[1262].frames = 4;


local function archiveSectionPages (args, group, folderName)
	local talker = args.npc

	message.promptChosen = false
	message.showMessageBox {target=talker, text="<gt>Accessing "..folderName.."...<pause 0.1>", type="system", closeWith="prompt"}
	message.waitMessageDone();

	-- Set up prompt
	local keys,names,bios = archives.GetUnlockedBios(group)

	local namePages = {}
	if  #names > 8  then
		for i=1,#names  do
			--windowDebug(names[i]..":\n\n"..bios[i])
			local pageNum = math.floor(i/8)+1
			if  namePages[pageNum] == nil  then  namePages[pageNum] = {};  end;
			table.insert(namePages[pageNum], names[i])
		end
	else
		namePages = {names}
	end


	-- Begin prompt loop
	local loopBroken = false
	local currentPage = 1

	while  (not loopBroken)  do

		-- Set up page controls and cancel option
		local extraOptions = {}
		local nextNum = -1
		local prevNum = -1
		local cancelNum = -1

		if  #namePages > 1  then
			if  currentPage > 1  then
				extraOptions[#extraOptions+1] = "Previous page"
				prevNum = #extraOptions
			end
			if  currentPage < #namePages  then
				extraOptions[#extraOptions+1] = "Next page"
				nextNum = #extraOptions
			end
		end
		extraOptions[#extraOptions+1] = message.getCancelOption()
		cancelNum = extraOptions[#extraOptions]


		-- Call prompt
		local currentNames = namePages[currentPage]

		message.promptChosen = false
		message.showPrompt{options=table.append(currentNames, extraOptions), sideX=-1}
		message.waitPrompt()


		-- If the player has chosen a character name, show the bio
		if  message.promptChoice <= #currentNames  then
			local keyIndex = (currentPage-1)*8 + message.promptChoice
			local key = keys[keyIndex]

			archives.UpdateBioReadExtent(group,key)
			names[keyIndex] = archives.GetBioProperty (group,key,"name")
			namePages[currentPage][message.promptChoice] = names[keyIndex]

			message.showMessageBox{target=talker, text=bios[keyIndex], type="system", bloxProps={autosizeRatio=10/3}}
			message.waitMessageEnd()

		-- Otherwise, if the player cancelled
		elseif  message.promptChoice == #currentNames + #extraOptions  then
			loopBroken = true

		-- Otherwise
		else
			local extraNum = message.promptChoice-#currentNames

			-- If the player has chosen next page
			if extraNum == nextNum  then
				currentPage = currentPage+1

			-- If the player has chosen previous page
			elseif  extraNum == prevNum  then
				currentPage = currentPage-1
			end

			message.promptChosen = false
			message.showMessageBox {target=talker, text="<gt>Accessing "..folderName.."...<pause 0.1>", type="system", closeWith="prompt"}
		end

		-- Yield
		eventu.waitFrames(0)
	end
	names[#names+1] = message.getCancelOption()

	message.endMessage();
	scene.endScene();
end

local function archiveSection (args, group, folderName)
	local talker = args.npc

	message.promptChosen = false
	message.showMessageBox {target=talker, text="<gt>Accessing "..folderName.."...<pause 0.1>", type="system", closeWith="prompt"}
	message.waitMessageDone();

	-- Set up prompt
	local keys,names,bios = archives.GetUnlockedBios(group)
	local optionTable = table.append(names, {message.getCancelOption()})


	-- Begin prompt loop
	local loopBroken = false
	local currentPage = 1

	while  (not loopBroken)  do

		-- Call prompt
		message.promptChosen = false
		message.showPrompt{options=optionTable, optionsShown=8, sideX=-1}
		message.waitPrompt()


		-- If the player cancelled
		if  message.promptChoice == #optionTable  then
			loopBroken = true

		-- Otherwise, if the player has chosen a character name, show the bio
		else
			local keyIndex = message.promptChoice
			local key = keys[keyIndex]

			archives.UpdateBioReadExtent(group,key)
			names[keyIndex] = archives.GetBioProperty (group,key,"name")
			optionTable[message.promptChoice] = names[keyIndex]

			message.showMessageBox{target=talker, text=bios[keyIndex], type="system", bloxProps={autosizeRatio=10/3}}
			message.waitMessageEnd()
		end

		-- Yield
		eventu.waitFrames(0)
	end

	message.endMessage();
	scene.endScene();
end




message.presetSequences.MessageTest = function(args)
	local talker = args.npc

	message.showMessageBox {target=talker, text="Testing sign messages.", type="sign"}
	message.waitMessageEnd();

	message.showMessageBox {target=talker, text="Testing bubble messages."}
	message.waitMessageEnd();

	message.showMessageBox {target=talker, text="Testing system messages.", type="system"}
	message.waitMessageEnd();

	message.showMessageBox {target=talker, text="Testing boxless messages.", type="textonly"}
	message.waitMessageEnd();

	message.showMessageBox {target=talker, text="Testing intercom messages.", type="intercom"}
	message.waitMessageEnd();

	message.endMessage();
	scene.endScene();
end


message.presetSequences.archiveDebug = function(args)
	local talker = args.npc

	message.promptChosen = false
	message.showMessageBox {target=talker, text="<gt>Accessing admin tools...<pause 0.1>", type="system", closeWith="prompt"}
	message.waitMessageDone();


	-- Set up the prompt
	local optionsList = {"Reset notifications", "Reset world override"}
	for  i=2,10  do
		optionsList[#optionsList+1] = "Set world override to "..tostring(i)
	end
	local cancelNum = -1
	optionsList[#optionsList+1] = message.getCancelOption()
	cancelNum = #optionsList


	-- Show the prompt
	message.showPrompt{options=optionsList, sideX=-1}
	message.waitPrompt()

	-- Reset notifications
	if  message.promptChoice == 1  then
		message.showMessageBox {target=talker, text="<gt>All profile notifications reset.", type="system"}
		message.waitMessageEnd();

		SaveData.biosRead = {}

	-- Reset override
	elseif  message.promptChoice == 2  then
		message.showMessageBox {target=talker, text="<gt>World assumption reset.", type="system"}
		message.waitMessageEnd();
		archives.SetBioDebugWorld(nil)

	-- Cancel
	elseif  message.promptChoice == cancelNum  then
		

	-- Set override
	else
		message.showMessageBox {target=talker, text="<gt>Assuming the player is in world "..tostring(message.promptChoice-1)..".  All bios up to this world are now unlocked.", type="system"}
		message.waitMessageEnd();
		archives.SetBioDebugWorld(message.promptChoice-1)
	end

	message.endMessage();
	scene.endScene();
end

message.presetSequences.archiveChars = function(args)
	return archiveSection (args, "characters", "character profiles")
end

message.presetSequences.archiveSpecies = function(args)
	return archiveSection (args, "species", "specie files")
end

message.presetSequences.archiveLocales = function(args)
	return archiveSection (args, "locations", "universal atlas")
end

message.presetSequences.archiveEpochs = function(args)
	return archiveSection (args, "epochs", "epoch data")
end

message.presetSequences.archiveEvents = function(args)
	return archiveSection (args, "events", "event records")
end

message.presetSequences.archiveTerms = function(args)
	return archiveSection (args, "terms", "glossary")
end

message.presetSequences.jukebox = function(args)
	return message.presetSequences.jukeboxNormal(args)
end




function onStart()
	for  i=0,1  do
		SaveData["world"..i].unlocked=true
		SaveData["world"..i].superleek=true
	end
	SaveData["world2"].unlocked=true
end

function onLoadSection1(playerIndex)
	Audio.resetMciSections()
end


local gearAnimTimer = 6;
local GM_FRAME = readmem(0x00B2BEA0, FIELD_DWORD)

local function get_block_frame(id)
	return readmem(GM_FRAME + 2*(id-1), FIELD_WORD)
end
local function set_block_frame(id, v)
	return writemem(GM_FRAME + 2*(id-1), FIELD_WORD, v)
end

function onDraw()

	--Gear animation
	if gearAnimTimer > 0 then
		gearAnimTimer = gearAnimTimer -1;
	else
		gearAnimTimer = 6;
		set_block_frame(1262, (get_block_frame(1262)+1)%4)
	end
	
	--Gear fading for perspective
	local gearfadeverts = {}
	local gearfadecols = {}
	for _,v in ipairs(Block.get(1262, player.section)) do
		v.speedX = 4/7;
		local x = v.x;
		local w = v.width*0.45;
		local a1 = 0.75;
		local a2 = 0;
		local la = a1;
		local ra = a2;
		for i = 1,2 do
		
			table.insert(gearfadeverts, x)		table.insert(gearfadeverts, v.y)
			table.insert(gearfadeverts, x+w)	table.insert(gearfadeverts, v.y)
			table.insert(gearfadeverts, x)		table.insert(gearfadeverts, v.y+v.height)
			table.insert(gearfadeverts, x)		table.insert(gearfadeverts, v.y+v.height)
			table.insert(gearfadeverts, x+w)	table.insert(gearfadeverts, v.y)
			table.insert(gearfadeverts, x+w)	table.insert(gearfadeverts, v.y+v.height)
			
			table.insert(gearfadecols, 0) table.insert(gearfadecols, 0)  table.insert(gearfadecols, 0)  table.insert(gearfadecols, la)
			table.insert(gearfadecols, 0) table.insert(gearfadecols, 0)  table.insert(gearfadecols, 0)  table.insert(gearfadecols, ra)
			table.insert(gearfadecols, 0) table.insert(gearfadecols, 0)  table.insert(gearfadecols, 0)  table.insert(gearfadecols, la)
			table.insert(gearfadecols, 0) table.insert(gearfadecols, 0)  table.insert(gearfadecols, 0)  table.insert(gearfadecols, la)
			table.insert(gearfadecols, 0) table.insert(gearfadecols, 0)  table.insert(gearfadecols, 0)  table.insert(gearfadecols, ra)
			table.insert(gearfadecols, 0) table.insert(gearfadecols, 0)  table.insert(gearfadecols, 0)  table.insert(gearfadecols, ra)
			
			
			local c = la;
			la = ra;
			ra = c;
			x = v.x+v.width - w;
		end
	end
	
	Graphics.glDraw{vertexCoords = gearfadeverts, vertexColors = gearfadecols, sceneCoords = true, priority = -90}

	-- Pendulum section
	if  player.section == 0  then

		-- Pendulum
		local pendPercent = math.sin(math.rad(lunatime.tick()))
		imagic.Draw {primitive=imagic.TYPE_BOX, align=imagic.ALIGN_TOP,
		             color=0xFFFFFF00 + 32 + 32*(1-math.abs(pendPercent)),
		             x=-200000+400, y=-200600-150, priority=-95, scene=true,
		             width=pendSpr.width*2, height=pendSpr.height*2, 
		             texture=pendSpr, rotation=55*pendPercent}

		-- Reflection
		reflections:captureAt(-2);
		local cam = Camera.get()[1]
		local reflectY = -200160 - cam.y;
		local th = (reflectY/600);
		local stretchFactor = 1;
		local brightness = 0.1;
		Graphics.glDraw {
		                 vertexCoords = {0,reflectY,800,reflectY,800,600,0,600}, 
		                 textureCoords = {0,th,1,th,1,(th*2-1)*stretchFactor,0,(th*2-1)*stretchFactor}, 
		                 vertexColors = {brightness,brightness,brightness,0, brightness,brightness,brightness,0, 0,0,0,0, 0,0,0,0},
		                 primitive = Graphics.GL_TRIANGLE_FAN, 
		                 texture=reflections, 
		                 priority = -2,
		};
	end
end
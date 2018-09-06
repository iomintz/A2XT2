local scene = API.load("a2xt_scene");
local actors = API.load("a2xt_actor");
local eventu = API.load("eventu");
local message = API.load("a2xt_message");
local cman = API.load("cameraman");
local pnpc = API.load("pnpc");
local imagic = API.load("imagic");
local checkpoints = API.load("checkpoints");

local boss = API.load("a2xt_boss");

boss.SuperTitle = "Grand High Ingoopinator"
boss.Name = "Noctel"

boss.MaxHP = 10;
boss.TitleDisplayTime = 160;

actors.groundY = -200192;

local bossAPI = {};

local cp = checkpoints.create{x = 0, y = 0, section = 0, actions = 
				function()
					player.x = Section(bossAPI.section).boundary.left + 80;
					player.y = -200192 - player.height;
					bossAPI.Begin(true); 
					
				end}

local function chooseText(demo, iris, kood, raocow, sheath)
	if(player.character == CHARACTER_DEMO) then
		return demo;
	elseif(player.character == CHARACTER_IRIS) then
		return iris;
	elseif(player.character == CHARACTER_RAOCOW) then
		return raocow;
	elseif(player.character == CHARACTER_KOOD) then
		return kood;
	elseif(player.character == CHARACTER_SHEATH) then
		return sheath;
	end
end

local capeimg = Graphics.loadImage("cape.png");
local capeObj = nil;

local function cor_intro()
	local p = actors.Player.ToActor();
	actors.ToActors {ACTOR_NOCTEL}
	ACTOR_NOCTEL.direction = DIR_RIGHT
	
	local cam = cman.playerCam[1]
	cam.targets={}
	local camx = -200000+400
	local camy = -200600+300
	cam.x = camx;
	cam.y = camy;
	
	playMusic(1)
	
	cam:Queue{time=0.5, zoom=1.1, x = camx, y = camy}
	
	eventu.waitSeconds(1.2);
	ACTOR_NOCTEL.direction = DIR_LEFT
	eventu.waitSeconds(0.2);
	ACTOR_NOCTEL:Talk{text = "Nyehehe...We've been expecting you..."}
	message.waitMessageEnd()
	eventu.waitSeconds(0.5);
	p:Talk{text = chooseText(
								"Who the heck are you?",
								"Wha...who the heck are you?",
								"Who are you and what do you want?!",
								"Um...who are you?",
								"Um...who are you?"
							)}
	message.waitMessageEnd()
	eventu.waitSeconds(0.2);
	ACTOR_NOCTEL:Walk(-1);
	cam:Queue{time=2, zoom=1.4, x = camx-64, y = camy}	
	eventu.waitFrames(64);
	ACTOR_NOCTEL:Talk{text = "I am the leader of the organization that knows everything..."}
	eventu.waitFrames(64);
	ACTOR_NOCTEL:Walk(0);
	message.waitMessageEnd()
	ACTOR_NOCTEL:Talk{text = "Noctel."}
	message.waitMessageEnd()
	eventu.waitSeconds(2);
	p:Talk{text = chooseText(
								"That's a stupid name.",
								"That name is one of the dumbest names ever.",
								"That name REEKS of tyranny and terror.",
								"That name is...kinda dumb.",
								"Oh."
							)}
	message.waitMessageEnd()
	ACTOR_NOCTEL:Talk{text = "You clearly don't know ANYTHING about the great Goopinati Organization. We strike fear in the citizens of Grass Place Town."}
	message.waitMessageEnd()
	ACTOR_NOCTEL:Talk{text = "We control everything. The shops, the banks, the economy, the events of the world... the lives of the people here."}
	message.waitMessageEnd()
	ACTOR_NOCTEL:Talk{text = "We enforce the Goopa rule. We use Furba corpses for an energy-efficent power source."}
	message.waitMessageEnd()
	p:Jump{strength=4}
	p:Pose("shocked")
	p:Talk{text = chooseText(
								"Oh, ew.",
								"That's insane!",
								"You monsters!",
								"Woah...why would you murder Furbas like that?!",
								"Oh..."
							)}
	message.waitMessageEnd()
	eventu.waitSeconds(0.5);
	p:Pose("idle")
	ACTOR_NOCTEL:Talk{text = "Heh...I can see you're already afraid. And just to let you know..."}
	message.waitMessageEnd()
	ACTOR_NOCTEL:Talk{text = "...I have one of those Super Leeks you're looking for."}
	message.waitMessageEnd()
	ACTOR_NOCTEL:Talk{text = "I know you want it...and we'll battle for it."}
	message.waitMessageEnd()
	
	playMusic(0)
	
	cam:Queue{time=0.2, zoom=2, x = ACTOR_NOCTEL.x-32, y = ACTOR_NOCTEL.y - 64}
	ACTOR_NOCTEL:Pose("spin")
	local s = ACTOR_NOCTEL.gfx.speed;
	ACTOR_NOCTEL.gfx.speed = 10;
	ACTOR_NOCTEL:Talk{text = "En garde!"}
	eventu.waitSeconds(0.5);
	ACTOR_NOCTEL:Pose("idle2")
	capeObj = imagic.Create{primitive = imagic.TYPE_BOX, texture = capeimg, width = 32, height = 32, x = ACTOR_NOCTEL.x, y = ACTOR_NOCTEL.y-48, scene=true}
	ACTOR_NOCTEL.gfx.speed = s;
	message.waitMessageEnd()
	cam:Queue{time=0.5, zoom=1, x = camx, y = camy}
	scene.endScene();
	eventu.waitSeconds(0.5);
	actors.Player:BecomePlayer();
	
	playMusic(2)
	cp:collect();
	
	boss.Start(false);
end

local function cor_introCheckpoint()
	actors.ToActors {ACTOR_NOCTEL}
	ACTOR_NOCTEL.direction = DIR_LEFT
	ACTOR_NOCTEL.x = ACTOR_NOCTEL.x-128
	actors.Player:BecomePlayer();
	ACTOR_NOCTEL.gfx.frame = 5
	eventu.waitFrames(2);
	ACTOR_NOCTEL:Pose("idle2")
	
	boss.Start(true);
end

local bossBegun = false;
function bossAPI.Begin(fromCheckpoint)
	if(not bossBegun) then
		registerEvent(bossAPI, "onTick");
		registerEvent(bossAPI, "onDraw");
		
		if(fromCheckpoint) then
			eventu.run(cor_introCheckpoint);
		else
			scene.startScene{scene=cor_intro}
		end
		bossBegun = true;
	end
end

local firstTick = true
function bossAPI.onTick()
	if(firstTick and boss.Active) then
		playMusic(2)
		firstTick = false;
	end
	
	if(capeObj ~= nil) then
		capeObj.x = capeObj.x + 8;
		capeObj.y = capeObj.y - 1;
		capeObj:rotate(-1);
		if(capeObj.x > -199200) then
			capeObj = nil;
		end
	end
end

function bossAPI.onDraw()
	if(capeObj ~= nil) then
		capeObj:Draw(-65);
	end
end

return bossAPI;
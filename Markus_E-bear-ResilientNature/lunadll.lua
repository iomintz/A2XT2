local particles = loadSharedAPI("particles");

local leaves = particles.Emitter(0, 0, Misc.resolveFile("particles/p_leaves.ini"), 1);

leaves:AttachToCamera(Camera.get()[1]);

function onStart()
	leaves.enabled = true;
end

function onCameraUpdate()
    leaves:Draw();
end

function onLoop()

	for  k,v in pairs(NPC.get(26, -1))  do
		v.speedX = 0
		v.speedY = 0
	end
end
 function saveFileInit()
	saveVersion = GetInt("savegame.mod.molotovVersion")
	enableEmberFire = GetBool("savegame.mod.molotovEmberfire")
	maxMolotovCount = GetInt("savegame.mod.molotovMaxMolotovCount")
	emberCount = GetInt("savegame.mod.molotovEmberCount")
	maxWorldEmbers = GetInt("savegame.mod.molotovMaxWorldEmbers")
	silencedMolotov = GetBool("savegame.mod.molotovSilencedMolotov")
	unlimitedAmmo = GetBool("savegame.mod.molotovUnlimitedAmmo")
	breakWindows = GetBool("savegame.mod.molotovBreakGlass")
	
	if saveVersion == nil then saveVersion = 0 end
	
	if saveVersion < 3 then
		saveVersion = 3
		SetInt("savegame.mod.molotovVersion", 3)
		
		enableEmberFire = true
		SetBool("savegame.mod.molotovEmberfire", enableEmberFire)
		
		maxMolotovCount = 100
		SetInt("savegame.mod.molotovMaxMolotovCount", maxMolotovCount)
		
		emberCount = 15
		SetInt("savegame.mod.molotovEmberCount", emberCount)
		
		maxWorldEmbers = 100
		SetInt("savegame.mod.molotovMaxWorldEmbers", maxWorldEmbers)
	end
	
	if saveVersion < 4 then
		saveVersion = 4
		SetInt("savegame.mod.molotovVersion", 4)
		
		silencedMolotov = false
		SetBool("savegame.mod.molotovSilencedMolotov", silencedMolotov)
	end
	
	if saveVersion < 5 then
		saveVersion = 5
		SetInt("savegame.mod.molotovVersion", 5)
		DebugPrint("The molotov now has new sounds!")
		DebugPrint("If you wish to continue using silenced molotov, you can reenable it in the settings.")
		DebugPrint("This reset only happens once. This message will not appear again.")
		DebugPrint("And will go away when you enter the game or something uses the debug console.")
		
		silencedMolotov = false
		SetBool("savegame.mod.molotovSilencedMolotov", silencedMolotov)
	end
	
	if saveVersion < 6 then
		saveVersion = 6
		SetInt("savegame.mod.molotovVersion", 6)
		
		unlimitedAmmo = false
		SetBool("savegame.mod.molotovUnlimitedAmmo", unlimitedAmmo)
	end
	
	if saveVersion < 7 then
		breakWindows = true
		SetBool("savegame.mod.molotovBreakGlass", breakWindows)
	end
end


local bottleshatterSFX = {}
local d_lines = {}

molotov = {
	shellNum = 1,
	maxShells =  GetInt("savegame.mod.molotovMaxMolotovCount"),
	shells = {},
	defaultShell = {
		active = false, 
		gravity = Vec(0, -160, 0),
		velocity = 100,
		explode = false,
		hitNormal = nil,
		embers = GetInt("savegame.mod.molotovEmberCount")
	},
}

molotovEmbers = {
	shellNum = 1,
	maxShells =  GetInt("savegame.mod.molotovMaxWorldEmbers"),
	shells = {},
	defaultShell = {
		active = false,
		static = false,
		gravity = Vec(0, -160, 0),
		velocity = 100,
		burnHits = GetBool("savegame.mod.molotovEmberFire"),
		lifetime = 2,
		particleSize = 0.1
	},
}



function init()
	saveFileInit()
	RegisterTool("molotov", "Molotov Cocktail", "MOD/vox/molotov.vox")
	SetBool("game.tool.molotov.enabled", true)

	if unlimitedAmmo then
		SetFloat("game.tool.molotov.ammo", 0)
	end
	
	--bottleShatterSnd = LoadSound("MOD/snd/bottleshatter_original_sound.ogg")
	
	for i=1, 3 do
		bottleshatterSFX[i] = LoadSound("MOD/snd/bottleshatter_0.ogg")
	end
	
	for i=1, molotov.maxShells do
		molotov.shells[i] = deepcopy(molotov.defaultShell)
	end
	
	for i=1, molotovEmbers.maxShells do
		molotovEmbers.shells[i] = deepcopy(molotovEmbers.defaultShell)
	end
end

function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)	
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function Shoot()
	local ct = GetCameraTransform()
	local fwdpos = TransformToParentPoint(ct, Vec(0, 0, -2))
	local gunpos = TransformToParentPoint(ct, Vec(0, 0, -1))
	local direction = VecSub(fwdpos, gunpos)
	
	molotov.shells[molotov.shellNum] = deepcopy(molotov.defaultShell)
	local loadedShell = molotov.shells[molotov.shellNum] 
	loadedShell.active = true
	loadedShell.pos = gunpos
	loadedShell.predictedBulletVelocity = VecScale(direction, loadedShell.velocity)

	molotov.shellNum = (molotov.shellNum % #molotov.shells) + 1
	
	if unlimitedAmmo then
		SetFloat("game.tool.molotov.ammo", GetFloat("game.tool.molotov.ammo") + 1)
	else
		SetFloat("game.tool.molotov.ammo", GetFloat("game.tool.molotov.ammo") - 1)
	end
end

function CreateSingleEmber(proj, directionScale, enableGravity)
	local direction = rndVec(directionScale)

	molotovEmbers.shells[molotovEmbers.shellNum] = deepcopy(molotovEmbers.defaultShell)

	local loadedShell = molotovEmbers.shells[molotovEmbers.shellNum] 
	loadedShell.active = true
	loadedShell.static = not enableGravity
	loadedShell.pos = proj.pos
	loadedShell.predictedBulletVelocity = VecScale(direction, loadedShell.velocity)

	molotovEmbers.shellNum = (molotovEmbers.shellNum % #molotovEmbers.shells) + 1

	return loadedShell
end

function ExplodeEmbers(proj)
	local fire = CreateSingleEmber(proj, 0, false)
	fire.particleSize = 0.3
	fire.lifetime = fire.lifetime * 2
	for i = 1, proj.embers do
		CreateSingleEmber(proj, 0.2, true)
	end
end

function MolotovOperations(projectile)
	projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(projectile.gravity, GetTimeStep()/4)))
	local point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()/4))
	local dir = VecNormalize(VecSub(point2, projectile.pos))
	local distance = VecLength(VecSub(point2, projectile.pos))
	
	local hit, distToHit, normal = QueryRaycast(projectile.pos, dir, distance, 0, breakWindows)
	
	
	if breakWindows then
		local hitTransparant, distT = QueryRaycast(projectile.pos, dir, distance * 2, 0, false)
		local hitNonTransparant, distNonT = QueryRaycast(projectile.pos, dir, distance * 2, 0, true)
		
		local hitWindow = hitTransparant and not hitNonTransparant
		
		if hitWindow then
			local hitPoint = VecAdd(projectile.pos, VecScale(dir, distT))
			MakeHole(hitPoint, 1)
		end
	end
	
	if hit then
		projectile.explode = true
		projectile.hitNormal = normal
	else
		projectile.pos = point2
	end
end

function MolotovEmberOperations(projectile)
	projectile.predictedBulletVelocity = VecAdd(projectile.predictedBulletVelocity, (VecScale(projectile.gravity, GetTimeStep()/4)))
	local point2 = VecAdd(projectile.pos, VecScale(projectile.predictedBulletVelocity, GetTimeStep()/4))
	local dir = VecNormalize(VecSub(point2, projectile.pos))
	local distance = VecLength(VecSub(point2, projectile.pos))
	local hit, dist, normal = QueryRaycast(projectile.pos, dir, distance)
	if hit and projectile.burnHits then
		SpawnFire(projectile.pos)
	end	
	
	if hit then
		local dot = VecDot(normal, projectile.predictedBulletVelocity)
		projectile.predictedBulletVelocity = VecSub(projectile.predictedBulletVelocity, VecScale(normal, dot))
	else
		projectile.pos = point2
	end
end

function drawLines(dt)
	for i = #d_lines, 1, -1 do
		local currLine = d_lines[i]
		DrawLine(currLine.p1, currLine.p2, currLine.r, currLine.g, currLine.b, currLine.a)
		currLine.lifetime = currLine.lifetime - dt
		
		if currLine.lifetime <= 0 then
			table.remove(d_lines, i, 1)
		end
	end
end

function tick(dt)
	drawLines(dt)
	
	local ct = GetCameraTransform()
	local gunpos = TransformToParentPoint(ct, Vec(0.25, -0.2, -0.8))
	if GetString("game.player.tool") == "molotov" then
	
		if GetBool("game.player.canusetool") and (GetFloat("game.tool.molotov.ammo") > 0 or unlimitedAmmo)  and GetPlayerVehicle() == 0 then
			if InputPressed("lmb") then
				Shoot()
			end
		
			local b = GetToolBody()
			if b ~= 0 then
				--local shapes = GetBodyShapes(b)
		
				--Add some light
				--local p = TransformToParentPoint(GetBodyTransform(body), Vec(0, 0, -2))
				--PointLight(p, 1, 0.5, 0.7, math.random(10, 15) / 10)
				
				SpawnParticle("fire", gunpos, Vec(-0.25, 0.5, 0), 0.3, 0.5)
			end
		end
	end
	
	for key, shell in ipairs(molotov.shells) do
		if shell.active and shell.explode then
			shell.active = false
			--Explosion(shell.pos, 0.001)
			SpawnFire(shell.pos)
			ExplodeEmbers(shell)
			for i = 1, 10 do
				local randVec = rndVec(0.5)
				--SpawnFire(VecAdd(randVec, shell.pos))
				--SpawnParticle("fire", VecAdd(randVec, shell.pos), rndVec(1), 0.5, 1)
			end
			
			if not silencedMolotov then
				local soundId = math.random(1, #bottleshatterSFX)
				PlaySound(bottleshatterSFX[soundId], shell.pos, 5)
			end
		end

		if shell.active then
			MolotovOperations(shell)
			SpawnParticle("fire", shell.pos, 0.5, 0.5, 0.5)
		end
	end
	
	for key, shell in ipairs(molotovEmbers.shells) do
		if shell.active then
			if not shell.static then
				MolotovEmberOperations(shell)
			end
			
			if shell.lifetime > 0 then
				shell.lifetime = shell.lifetime - dt
				
				SpawnParticle("smoke", shell.pos, 0.5, shell.particleSize * 1.2, 1.0)
				SpawnParticle("fire", shell.pos, 0.5, shell.particleSize, 1.0)
				
			else
				shell.active = false
			end
		end
	end
end


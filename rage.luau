local Shared = _G.NemesisShared
local Players = Shared.Services.Players
local RunService = Shared.Services.RunService
local Workspace = Shared.Services.Workspace
local ReplicatedStorage = Shared.Services.ReplicatedStorage
local player = Shared.Player
local Notification = Shared.Notification

-- ============================================
-- Variables
-- ============================================
local RAGE_ENABLED = false
local RAGE_HITPART = "Head"
local RAGE_HITCHANCE = 100
local RAGE_HITCHANCE_ENABLED = false
local RAGE_AUTOSHOOT = false
local RAGE_NOSPREAD = false
local AIRSHOT_ACTIVE = false
local AUTO_EQUIP_SSG = false
local FIRE_RATE = 0.1
local FIRE_RATE_AWP = 1.2
local MAX_DISTANCE = 1000
local lastShot = 0

local PREDICTION_ENABLED = true
local PREDICTION_STRENGTH = 1.2
local BULLET_SPEED = 800

local ping = 0
local lastPingUpdate = 0
local PING_UPDATE_RATE = 1

local activePlayers = {}
local lastPlayerListUpdate = 0
local PLAYER_LIST_UPDATE_RATE = 0.5

-- MinDamage
local MIN_DAMAGE_ENABLED = false
local MIN_DAMAGE_VALUE = 0
local BASE_DAMAGE = 54

local BODY_PART_MULTIPLIERS = {
	["Head"] = 4.0,
	["UpperTorso"] = 1.0,
	["LowerTorso"] = 1.0,
	["Torso"] = 1.0,
	["HumanoidRootPart"] = 1.0,
	["LeftUpperArm"] = 0.75,
	["LeftLowerArm"] = 0.75,
	["LeftHand"] = 0.75,
	["RightUpperArm"] = 0.75,
	["RightLowerArm"] = 0.75,
	["RightHand"] = 0.75,
	["LeftUpperLeg"] = 0.6,
	["LeftLowerLeg"] = 0.6,
	["LeftFoot"] = 0.6,
	["RightUpperLeg"] = 0.6,
	["RightLowerLeg"] = 0.6,
	["RightFoot"] = 0.6,
	["Left Leg"] = 0.6,
	["Right Leg"] = 0.6,
}

local MIN_DAMAGE_PRIORITY = {
	{name = "Legs", parts = {"LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg"}, multiplier = 0.6},
	{name = "Arms", parts = {"LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand", "Left Arm", "Right Arm"}, multiplier = 0.75},
	{name = "Body", parts = {"UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}, multiplier = 1.0},
	{name = "Head", parts = {"Head"}, multiplier = 4.0},
}

-- ============================================
-- Functions
-- ============================================
local function calculatePotentialDamage(partName, distance)
	local multiplier = BODY_PART_MULTIPLIERS[partName] or 0.5
	local damage = BASE_DAMAGE * multiplier
	if distance > 300 then
		damage = damage * 0.3
	elseif distance > 200 then
		damage = damage * 0.5
	elseif distance > 100 then
		damage = damage * 0.8
	end
	return math.floor(damage)
end

local function isAlive()
	local char = player.Character
	if not char then return false end
	local hum = char:FindFirstChild("Humanoid")
	return hum and hum.Health > 0
end

local function isEnemy(target)
	if player.Team and target.Team then
		return player.Team ~= target.Team
	end
	return true
end

local function isInAir()
	local char = player.Character
	if not char then return true end

	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return true end

	if hum.FloorMaterial == Enum.Material.Air then
		return true
	end

	if math.abs(hrp.AssemblyLinearVelocity.Y) > 2 then
		return true
	end

	return false
end

local function getGun()
	local char = player.Character
	if not char then return nil end

	for _, item in pairs(char:GetChildren()) do
		if item:IsA("Tool") then
			local remotes = item:FindFirstChild("Remotes")
			if remotes then
				local fireShot = remotes:FindFirstChild("FireShot")
				if fireShot then
					return {type = "AWP", fireShot = fireShot, fireRate = FIRE_RATE_AWP}
				end

				local castRay = remotes:FindFirstChild("CastRay")
				local hole = item:FindFirstChild("Hole")
				if castRay and hole then
					return {type = "CastRay", castRay = castRay, hole = hole, fireRate = FIRE_RATE}
				end
			end
		end
	end

	return nil
end

local function getTargetPart(char, distance)
	if AIRSHOT_ACTIVE then
		return char:FindFirstChild("Head")
	end
	
	if MIN_DAMAGE_ENABLED then
		for _, priorityGroup in ipairs(MIN_DAMAGE_PRIORITY) do
			for _, partName in ipairs(priorityGroup.parts) do
				local part = char:FindFirstChild(partName)
				if part then
					local damage = calculatePotentialDamage(partName, distance)
					if damage >= MIN_DAMAGE_VALUE then
						return part
					end
				end
			end
		end
		return nil
	end

	if RAGE_HITPART == "Head" then
		return char:FindFirstChild("Head")
	end
	if RAGE_HITPART == "Body" then
		return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
	end
	if RAGE_HITPART == "Arms" then
		return char:FindFirstChild("RightUpperArm") or char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Right Arm") or char:FindFirstChild("Left Arm")
	end
	if RAGE_HITPART == "Legs" then
		return char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Right Leg") or char:FindFirstChild("Left Leg")
	end
	return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function hasClearLineOfSight(fromPos, toPart, ignoreChar)
	if not toPart or not toPart.Parent then return false end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {ignoreChar, player.Character}
	params.IgnoreWater = true

	local dir = toPart.Position - fromPos
	local res = Workspace:Raycast(fromPos, dir, params)

	if not res then
		return true
	end

	return res.Instance:IsDescendantOf(toPart.Parent)
end

local function isPartVisible(targetPart, targetChar)
	if not targetPart or not targetPart.Parent then return false end
	if not isAlive() then return false end

	local myChar = player.Character
	if not myChar then return false end
	local myHead = myChar:FindFirstChild("Head")
	if not myHead then return false end

	local origin = myHead.Position
	local targetPos = targetPart.Position
	local dir = targetPos - origin
	local dist = dir.Magnitude

	if dist < 0.1 then return true end
	if dist > MAX_DISTANCE then return false end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude    
	params.FilterDescendantsInstances = {myChar}
	params.IgnoreWater = true

	local unit = dir.Unit
	local curOrigin = origin

	for _ = 1, 6 do
		local res = Workspace:Raycast(curOrigin, targetPos - curOrigin, params)

		if not res then return true end

		local hit = res.Instance

		if hit and hit:IsDescendantOf(targetChar) then
			return true
		end

		if hit then
			local name = hit.Name:lower()
			local isHamik = name:find("hamik") or name:find("paletka")
			local isSoft = hit.Transparency > 0.3 or hit.CanCollide == false or hit.CanQuery == false

			if isHamik or isSoft then
				curOrigin = res.Position + unit * 0.2
				continue
			end
		end

		return false
	end

	return false
end

local function predictPosition(part, rootPart)
	if not PREDICTION_ENABLED or not rootPart then return part.Position end

	local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.new()
	if velocity.Magnitude < 2 then return part.Position end

	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	local distance = (part.Position - Workspace.CurrentCamera.CFrame.Position).Magnitude
	local travelTime = distance / BULLET_SPEED
	local pingTime = ping / 2
	local dynamicTime = math.clamp(pingTime + travelTime, 0.05, 0.22)

	local predictedPos = part.Position + (horizontalVelocity * dynamicTime * PREDICTION_STRENGTH)

	return predictedPos
end

local function updateActivePlayersList()
	table.clear(activePlayers)
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player and isEnemy(targetPlayer) then
			local targetChar = targetPlayer.Character
			if targetChar then
				local hum = targetChar:FindFirstChild("Humanoid")
				local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and rootPart then
					table.insert(activePlayers, {
						player = targetPlayer,
						character = targetChar,
						humanoid = hum,
						rootPart = rootPart
					})
				end
			end
		end
	end
end

local function findTarget()
	if not isAlive() then return nil end

	local char = player.Character
	local myHead = char and char:FindFirstChild("Head")
	if not myHead then return nil end

	local now = tick()
	if now - lastPlayerListUpdate >= PLAYER_LIST_UPDATE_RATE then
		lastPlayerListUpdate = now
		updateActivePlayersList()
	end

	local bestTarget
	local bestDist = MAX_DISTANCE

	for _, data in ipairs(activePlayers) do
		if not data.humanoid or data.humanoid.Health <= 0 then continue end
		if not data.rootPart or not data.rootPart.Parent then continue end

		local dist = (data.rootPart.Position - myHead.Position).Magnitude
		if dist > bestDist then continue end

		local part = getTargetPart(data.character, dist)
		if not part then continue end

		if AIRSHOT_ACTIVE then
			if not hasClearLineOfSight(myHead.Position, part, data.character) then
				continue
			end
		else
			if not isPartVisible(part, data.character) then
				continue
			end
		end

		bestDist = dist
		bestTarget = {
			player = data.player,
			character = data.character,
			targetPart = part,
			rootPart = data.rootPart,
			distance = dist
		}
	end

	return bestTarget
end

-- Auto Equip SSG
local AUTO_EQUIP_TOOL_NAME = "SSG-08"
local autoEquippedOnce = false

local function equipSSGOnce()
	if not AUTO_EQUIP_SSG or autoEquippedOnce then return end

	local char = player.Character
	if not char then return end
	
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local currentTool = char:FindFirstChildOfClass("Tool")
	if currentTool and currentTool.Name == AUTO_EQUIP_TOOL_NAME then
		autoEquippedOnce = true
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end

	local tool = backpack:FindFirstChild(AUTO_EQUIP_TOOL_NAME)
	if tool and tool:IsA("Tool") then
		hum:EquipTool(tool)
		autoEquippedOnce = true
		Notification:Notify({
			Title = "Auto Equip",
			Content = "Equipped SSG-08",
			Duration = 2,
			Icon = "check"
		})
	end
end

player.CharacterAdded:Connect(function()
	autoEquippedOnce = false
end)

-- Main Loop
RunService.Heartbeat:Connect(function()
	equipSSGOnce()

	if not RAGE_ENABLED then return end
	if not isAlive() then return end

	local inAir = isInAir()
	AIRSHOT_ACTIVE = RAGE_NOSPREAD and inAir

	if RAGE_AUTOSHOOT and inAir and not RAGE_NOSPREAD then
		return
	end

	local gun = getGun()
	if not gun then return end

	if not RAGE_AUTOSHOOT then
		return
	end

	local currentTime = tick()
	if currentTime - lastShot < gun.fireRate then return end

	if currentTime - lastPingUpdate >= PING_UPDATE_RATE then
		lastPingUpdate = currentTime
		ping = player:GetNetworkPing()
	end

	local target = findTarget()
	if not target then return end

	if RAGE_HITCHANCE_ENABLED and not AIRSHOT_ACTIVE then
		local roll = math.random(1, 100)
		if roll > RAGE_HITCHANCE then
			return
		end
	end

	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return end

	local targetPos = PREDICTION_ENABLED
		and predictPosition(target.targetPart, target.rootPart)
		or target.targetPart.Position

	if gun.type == "AWP" then
		local origin = head.Position
		local dirVec = targetPos - origin
		if dirVec.Magnitude < 0.01 then return end

		local direction = dirVec.Unit
		local ok = pcall(function()
			gun.fireShot:FireServer(origin, direction, target.targetPart)
		end)

		if ok then
			lastShot = currentTime
			if Shared.Functions.createTracer then
				task.defer(function()
					Shared.Functions.createTracer(origin, targetPos)
				end)
			end
		end

	elseif gun.type == "CastRay" then
		if not gun.hole or not gun.hole.Parent then return end

		local origin = gun.hole.Position
		local dirVec = targetPos - origin
		if dirVec.Magnitude < 0.01 then return end

		local direction = dirVec.Unit
		local ray = Ray.new(origin, direction * 1000)

		local ok = pcall(function()
			gun.castRay:FireServer(ray, targetPos, target.player, target.targetPart)
		end)

		if ok then
			lastShot = currentTime
			if Shared.Functions.createTracer then
				task.defer(function()
					Shared.Functions.createTracer(origin, targetPos)
				end)
			end
		end
	end
end)

-- Export to Shared
Shared.Settings.RAGE_ENABLED = RAGE_ENABLED
Shared.Settings.RAGE_HITPART = RAGE_HITPART
Shared.Settings.RAGE_HITCHANCE = RAGE_HITCHANCE
Shared.Settings.RAGE_HITCHANCE_ENABLED = RAGE_HITCHANCE_ENABLED
Shared.Settings.RAGE_AUTOSHOOT = RAGE_AUTOSHOOT
Shared.Settings.RAGE_NOSPREAD = RAGE_NOSPREAD
Shared.Settings.AUTO_EQUIP_SSG = AUTO_EQUIP_SSG
Shared.Settings.MAX_DISTANCE = MAX_DISTANCE
Shared.Settings.PREDICTION_ENABLED = PREDICTION_ENABLED
Shared.Settings.PREDICTION_STRENGTH = PREDICTION_STRENGTH
Shared.Settings.MIN_DAMAGE_ENABLED = MIN_DAMAGE_ENABLED
Shared.Settings.MIN_DAMAGE_VALUE = MIN_DAMAGE_VALUE

Shared.Functions.setRageEnabled = function(v) RAGE_ENABLED = v end
Shared.Functions.setRageHitpart = function(v) RAGE_HITPART = v end
Shared.Functions.setRageHitchance = function(v) RAGE_HITCHANCE = v end
Shared.Functions.setRageHitchanceEnabled = function(v) RAGE_HITCHANCE_ENABLED = v end
Shared.Functions.setRageAutoshoot = function(v) RAGE_AUTOSHOOT = v end
Shared.Functions.setRageNospread = function(v) RAGE_NOSPREAD = v end
Shared.Functions.setAutoEquipSSG = function(v) AUTO_EQUIP_SSG = v end
Shared.Functions.setMaxDistance = function(v) MAX_DISTANCE = v end
Shared.Functions.setPredictionEnabled = function(v) PREDICTION_ENABLED = v end
Shared.Functions.setPredictionStrength = function(v) PREDICTION_STRENGTH = v end
Shared.Functions.setMinDamageEnabled = function(v) MIN_DAMAGE_ENABLED = v end
Shared.Functions.setMinDamageValue = function(v) MIN_DAMAGE_VALUE = v end

print("✅ Rage Module Loaded")

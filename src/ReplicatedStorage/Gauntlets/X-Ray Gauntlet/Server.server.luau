local Tool = script.Parent

local Remote = Tool:WaitForChild("Remote")
local VisibilityRemote = Tool:WaitForChild("VisibilityRemote")
local Handle = Tool:WaitForChild("Handle")

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local FriendlyFire = false

local ArmMesh

local HitAble = false
local HitWindup = 0.15
local HitWindow = 0.75
local HitDamage = 15
local HitVictims = {}

local SwingAble = true
local SwingRestTime = 2

----------------------------------------------------
-- INVIS SETTINGS
----------------------------------------------------
local INVIS_DURATION = 5
local INVIS_COOLDOWN = 5

-- FOOTSTEP SETTINGS
local FOOTSTEP_LIFETIME = 3
local FOOTSTEP_SIZE = Vector3.new(0.8, 0.08, 1.2)
local FOOTSTEP_MOVE_DISTANCE = 2.5 -- how far they need to move before another step spawns

-- invisStates[player] = {
--   active = false,
--   cooldownUntil = 0,
--   token = 0,
--   originalTransparency = {},
--   footstepConnection = nil,
--   lastFootstepPos = Vector3,
--   nextFoot = "Left"
-- }
local invisStates = {}

----------------------------------------------------
-- HELPERS
----------------------------------------------------

local function getPlayer()
	local char = Tool.Parent
	return Players:GetPlayerFromCharacter(char)
end

local function contains(t, v)
	for _, val in pairs(t) do
		if val == v then
			return true
		end
	end
	return false
end

local function tagHuman(human)
	local tag = Instance.new("ObjectValue")
	tag.Value = getPlayer()
	tag.Name = "creator"
	tag.Parent = human
	Debris:AddItem(tag, 2)
end

local function sameTeam(otherHuman)
	local player = getPlayer()
	local otherPlayer = Players:GetPlayerFromCharacter(otherHuman.Parent)

	if player and otherPlayer then
		if player == otherPlayer then
			return true
		end
		if otherPlayer.Neutral then
			return false
		end
		return player.TeamColor == otherPlayer.TeamColor
	end

	return false
end

local function checkTeams(otherHuman)
	return not (sameTeam(otherHuman) and not FriendlyFire)
end

local function getState(player)
	if not invisStates[player] then
		invisStates[player] = {
			active = false,
			cooldownUntil = 0,
			token = 0,
			originalTransparency = {},
			footstepConnection = nil,
			lastFootstepPos = nil,
			nextFoot = "Left",
		}
	end
	return invisStates[player]
end

----------------------------------------------------
-- COMBAT
----------------------------------------------------

local function onTouched(part)
	if part:IsDescendantOf(Tool.Parent) then return end
	if not HitAble then return end

	if part.Parent and part.Parent:FindFirstChild("Humanoid") then
		local human = part.Parent.Humanoid

		if contains(HitVictims, human) then return end

		local root = part.Parent:FindFirstChild("HumanoidRootPart")
		if root and not root.Anchored then
			local myRoot = Tool.Parent:FindFirstChild("HumanoidRootPart")
			if myRoot and checkTeams(human) then
				local delta = root.Position - myRoot.Position

				human.Sit = true
				tagHuman(human)
				human:TakeDamage(HitDamage)
				table.insert(HitVictims, human)

				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
				bv.Velocity = delta.Unit * 128
				bv.Parent = root
				Debris:AddItem(bv, 0.05)

				if Handle:FindFirstChild("Smack") then
					Handle.Smack.Pitch = math.random(90, 110) / 100
					Handle.Smack.TimePosition = 0.15
					Handle.Smack:Play()
				end
			end
		end
	end
end

local function onEquip()
	local char = Tool.Parent
	local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")

	if rightArm and Tool:FindFirstChild("ArmMesh") then
		local arm = Tool.ArmMesh:Clone()
		arm.Parent = rightArm
		ArmMesh = arm
	end
	
	local hum = char:FindFirstChild("Humanoid")
	if hum then
		hum.Died:Connect(function()
			stopInvis(getPlayer(), false)
		end)
	end
end

local function onUnequip()
	if ArmMesh then
		ArmMesh:Destroy()
		ArmMesh = nil
	end
end

local function onLeftDown(player)
	if not SwingAble then return end

	SwingAble = false
	task.delay(SwingRestTime, function()
		SwingAble = true
	end)

	HitVictims = {}

	Remote:FireClient(player, "PlaySwing")

	task.delay(HitWindup, function()
		HitAble = true
		task.delay(HitWindow, function()
			HitAble = false
		end)
	end)

	task.delay(0.25, function()
		if Handle:FindFirstChild("Boom") then
			Handle.Boom.Pitch = math.random(80, 100) / 100
			Handle.Boom:Play()
		end
	end)
end

----------------------------------------------------
-- FOOTSTEPS
----------------------------------------------------

local function createFootstep(position, footSide)
	local step = Instance.new("Part")
	step.Name = "InvisibleFootstep"
	step.Anchored = true
	step.CanCollide = false
	step.CanQuery = false
	step.CanTouch = false
	step.Size = FOOTSTEP_SIZE
	step.Material = Enum.Material.SmoothPlastic
	step.Color = Color3.fromRGB(0, 0, 0)
	step.Transparency = 0.85
	step.TopSurface = Enum.SurfaceType.Smooth
	step.BottomSurface = Enum.SurfaceType.Smooth

	-- slight left/right variation so it looks like actual footsteps
	local xOffset = (footSide == "Left") and -0.6 or 0.6
	step.Position = position + Vector3.new(xOffset, 0.03, 0)

	step.Parent = workspace

	-- fade out
	task.spawn(function()
		local fadeTime = FOOTSTEP_LIFETIME
		local start = tick()
		while step.Parent and tick() - start < fadeTime do
			local alpha = (tick() - start) / fadeTime
			step.Transparency = 0.15 + (0.85 * alpha)
			task.wait(0.05)
		end
		if step and step.Parent then
			step:Destroy()
		end
	end)
end

local function startFootsteps(player)
	local state = getState(player)
	local char = player.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end

	if state.footstepConnection then
		state.footstepConnection:Disconnect()
		state.footstepConnection = nil
	end

	state.lastFootstepPos = root.Position
	state.nextFoot = "Left"

	state.footstepConnection = RunService.Heartbeat:Connect(function()
		if not state.active then return end
		if not char.Parent then return end
		if humanoid.MoveDirection.Magnitude <= 0.05 then return end

		local currentPos = root.Position
		if not state.lastFootstepPos then
			state.lastFootstepPos = currentPos
			return
		end

		local dist = (currentPos - state.lastFootstepPos).Magnitude
		if dist >= FOOTSTEP_MOVE_DISTANCE then
			-- raycast downward so the footprint sits on the ground
			local rayOrigin = currentPos + Vector3.new(0, 2, 0)
			local rayDirection = Vector3.new(0, -8, 0)

			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {char}

			local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

			if result then
				createFootstep(result.Position, state.nextFoot)

				if state.nextFoot == "Left" then
					state.nextFoot = "Right"
				else
					state.nextFoot = "Left"
				end
			end

			state.lastFootstepPos = currentPos
		end
	end)
end

local function stopFootsteps(player)
	local state = getState(player)
	if state.footstepConnection then
		state.footstepConnection:Disconnect()
		state.footstepConnection = nil
	end
	state.lastFootstepPos = nil
end

----------------------------------------------------
-- INVISIBILITY
----------------------------------------------------

local function setCharacterInvisible(char, state)
	state.originalTransparency = {}

	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name ~= "HumanoidRootPart" then
				state.originalTransparency[obj] = obj.Transparency
				obj.Transparency = 1
			end
		elseif obj:IsA("Decal") then
			state.originalTransparency[obj] = obj.Transparency
			obj.Transparency = 1
		end
	end
end

local function restoreCharacterVisibility(state)
	for obj, oldTransparency in pairs(state.originalTransparency) do
		if obj and obj.Parent then
			if obj:IsA("BasePart") or obj:IsA("Decal") then
				obj.Transparency = oldTransparency
			end
		end
	end
	state.originalTransparency = {}
end

local function stopInvis(player, startCooldown)
	local state = getState(player)
	if not state.active then return end

	state.active = false
	state.token += 1

	stopFootsteps(player)

	local char = player.Character
	if char then
		restoreCharacterVisibility(state)
	end

	VisibilityRemote:FireClient(player, "StopVision")

	if startCooldown then
		state.cooldownUntil = tick() + INVIS_COOLDOWN
		VisibilityRemote:FireClient(player, "CooldownStarted", INVIS_COOLDOWN)
	end
end

local function startInvis(player)
	local state = getState(player)

	if state.active then
		stopInvis(player, true)
		return
	end

	if tick() < state.cooldownUntil then
		local timeLeft = math.max(0, state.cooldownUntil - tick())
		VisibilityRemote:FireClient(player, "CooldownRemaining", timeLeft)
		return
	end

	local char = player.Character
	if not char then return end
	if not char:FindFirstChildOfClass("Humanoid") then return end

	state.active = true
	state.token += 1
	local myToken = state.token

	setCharacterInvisible(char, state)
	startFootsteps(player)

	VisibilityRemote:FireClient(player, "StartVision", INVIS_DURATION)

	task.delay(INVIS_DURATION, function()
		local currentState = invisStates[player]
		if not currentState then return end
		if currentState.active and currentState.token == myToken then
			stopInvis(player, true)
		end
	end)
end

----------------------------------------------------
-- REMOTE
----------------------------------------------------

local function onRemote(player, action)
	local character = player.Character
	if not character or Tool.Parent ~= character then
		return
	end

	if action == "LeftDown" then
		onLeftDown(player)
	elseif action == "ToggleInvis" then
		startInvis(player)
	end
end
----------------------------------------------------
-- CONNECTIONS
----------------------------------------------------

Tool.Equipped:Connect(onEquip)
Tool.Unequipped:Connect(onUnequip)
Handle.Touched:Connect(onTouched)
Remote.OnServerEvent:Connect(onRemote)

Players.PlayerRemoving:Connect(function(player)
	stopFootsteps(player)
	invisStates[player] = nil
end)
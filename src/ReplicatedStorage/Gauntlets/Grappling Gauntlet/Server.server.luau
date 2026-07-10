local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Handle = Tool:WaitForChild("Handle")

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

--====================================================
-- SETTINGS
--====================================================

local FriendlyFire = false

-- MELEE
local HitAble = false
local HitWindup = 0.15
local HitWindow = 0.75
local HitDamage = 15
local HitVictims = {}
local SwingAble = true
local SwingRestTime = 2

-- GRAPPLE
local GrappleCooldown = 2
local GrappleRange = 300
local GrappleSpeed = 110
local GrappleDuration = 2.5
local GrappleLift = 10
local GrappleOnCooldown = {}

local ActiveGrapples = {}

local ArmMesh

--====================================================
-- UTIL
--====================================================

local function getPlayer()
	return Players:GetPlayerFromCharacter(Tool.Parent)
end

-- CLEANUP on Round End
workspace:GetAttributeChangedSignal("MatchActive"):Connect(function()
	if not workspace:GetAttribute("MatchActive") then
		local p = getPlayer()
		if p then stopGrapple(p) end
	end
end)

local function tagHuman(h)
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = getPlayer()
	tag.Parent = h
	Debris:AddItem(tag, 2)
end

local function sameTeam(otherHuman)
	local p = getPlayer()
	local op = Players:GetPlayerFromCharacter(otherHuman.Parent)
	if p and op then
		if p == op then return true end
		if op.Neutral then return false end
		return p.TeamColor == op.TeamColor
	end
	return false
end

local function canHit(otherHuman)
	return not (sameTeam(otherHuman) and not FriendlyFire)
end

--====================================================
-- MELEE (UNCHANGED BUT STABLE)
--====================================================

local function onTouched(part)
	if part:IsDescendantOf(Tool.Parent) then return end
	if not HitAble then return end

	local model = part.Parent
	if not model then return end

	local hum = model:FindFirstChild("Humanoid")
	if not hum then return end

	if HitVictims[hum] then return end

	local root = model:FindFirstChild("HumanoidRootPart")
	local myRoot = Tool.Parent:FindFirstChild("HumanoidRootPart")
	if not root or not myRoot then return end

	if root.Anchored then return end
	if not canHit(hum) then return end

	HitVictims[hum] = true

	hum.Sit = true
	tagHuman(hum)
	hum:TakeDamage(HitDamage)

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9,1e9,1e9)
	bv.Velocity = (root.Position - myRoot.Position).Unit * 120
	bv.Parent = root
	Debris:AddItem(bv, 0.05)
end

--====================================================
-- HOOK VISUAL
--====================================================

local function makeHook(pos)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.45,0.45,0.45)
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255,0,0)
	p.Anchored = true
	p.CanCollide = false
	p.Position = pos
	p.Parent = workspace

	local att = Instance.new("Attachment")
	att.Parent = p

	return p, att
end

local function makeBeam(a0,a1)
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Width0 = 0.15
	b.Width1 = 0.15
	b.LightEmission = 1
	b.Color = ColorSequence.new(Color3.fromRGB(255,0,0))
	b.Parent = Tool
	return b
end

--====================================================
-- CLEANUP
--====================================================

local function cleanup(data)
	if not data then return end
	if data.LV then data.LV:Destroy() end
	if data.RootAtt then data.RootAtt:Destroy() end
	if data.Hook then data.Hook:Destroy() end
	if data.Beam then data.Beam:Destroy() end
	if data.Anchor then data.Anchor:Destroy() end
end

local function stopGrapple(player)
	local d = ActiveGrapples[player]
	if not d then return end
	d.Active = false
	cleanup(d)
	ActiveGrapples[player] = nil
end

--====================================================
-- GRAPPLE CORE (FIXED + SPIDERMAN FEEL)
--====================================================

local function startGrapple(player, mousePos)
	if GrappleOnCooldown[player] then return end

	local char = player.Character
	if not char or Tool.Parent ~= char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	stopGrapple(player)

	-- ALWAYS use root as origin (fixes "doesn't grapple")
	local origin = root.Position

	local direction = mousePos - origin
	if direction.Magnitude < 2 then return end
	direction = direction.Unit * GrappleRange

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char, Tool}
	params.IgnoreWater = true

	local ray = workspace:Raycast(origin, direction, params)
	if not ray then return end

	local hitPos = ray.Position

	-- cooldown
	GrappleOnCooldown[player] = true
	task.delay(GrappleCooldown, function()
		GrappleOnCooldown[player] = nil
	end)

	-- root attachment
	local rootAtt = Instance.new("Attachment")
	rootAtt.Parent = root

	-- hook
	local hook, hookAtt = makeHook(origin)
	local beam = makeBeam(rootAtt, hookAtt)

	-- anchor point (NO MOVEMENT = NO JITTER)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2,0.2,0.2)
	anchor.Position = hitPos
	anchor.Parent = workspace

	local anchorAtt = Instance.new("Attachment")
	anchorAtt.Parent = anchor

	local data = {
		Player = player,
		Root = root,
		RootAtt = rootAtt,
		Hook = hook,
		Beam = beam,
		Anchor = anchor,
		Active = true,
		VelocityMemory = Vector3.zero
	}

	ActiveGrapples[player] = data

	-- instant hook travel (feels responsive)
	hook.Position = hitPos

	-- LinearVelocity (smooth physics)
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = rootAtt
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.MaxForce = math.huge
	lv.Parent = root
	data.LV = lv

	local startTime = tick()

	while data.Active do
		local target = anchor.Position
		local delta = target - root.Position
		local dist = delta.Magnitude

		hook.Position = target

		-- auto stop
		if dist < 5 then break end
		if tick() - startTime > GrappleDuration then break end

		local dir = delta.Unit

		-- SMOOTHING (Spider-Man feel)
		data.VelocityMemory = data.VelocityMemory:Lerp(dir, 0.25)

		local speed = GrappleSpeed * math.clamp(dist / 30, 0.4, 1)

		local up = 0
		if target.Y > root.Position.Y + 2 then
			up = GrappleLift
		end

		lv.VectorVelocity =
			data.VelocityMemory * speed +
			Vector3.new(0, up, 0)

		RunService.Heartbeat:Wait()
	end

	stopGrapple(player)
end

--====================================================
-- SWING + REMOTE
--====================================================

local function onLeftDown()
	if not SwingAble then return end

	SwingAble = false
	task.delay(SwingRestTime, function()
		SwingAble = true
	end)

	task.delay(HitWindup, function()
		HitAble = true
		task.delay(HitWindow, function()
			HitAble = false
		end)
	end)

	HitVictims = {}

	local p = getPlayer()
	if p then
		Remote:FireClient(p, "PlayAnimation", "Swing")
	end
end

local function onRemote(player, func, ...)
	if player ~= getPlayer() then return end

	if func == "LeftDown" then
		onLeftDown()

	elseif func == "Grapple" then
		local pos = ...
		if typeof(pos) == "Vector3" then
			startGrapple(player, pos)
		end
	end
end

--====================================================
-- CONNECTIONS
--====================================================

Tool.Equipped:Connect(function()
	local char = Tool.Parent
	local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
	if arm and Tool:FindFirstChild("ArmMesh") then
		ArmMesh = Tool.ArmMesh:Clone()
		ArmMesh.Parent = arm
	end
end)

Tool.Unequipped:Connect(function()
	local p = getPlayer()
	if p then stopGrapple(p) end
	if ArmMesh then ArmMesh:Destroy() end
end)

Handle.Touched:Connect(onTouched)
Remote.OnServerEvent:Connect(onRemote)

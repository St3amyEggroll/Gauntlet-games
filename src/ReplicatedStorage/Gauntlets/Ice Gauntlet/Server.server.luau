local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Handle = Tool:WaitForChild("Handle")

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FriendlyFire = false
local ArmMesh

local HitAble = false
local HitWindup = 0.15
local HitWindow = 0.75
local HitDamage = 15
local HitVictims = {}

local SwingAble = true
local SwingRestTime = 2

local AbilityActive = false
local AbilityCooldown = false
local CooldownTime = 10
local FreezeDuration = 3

local ActiveFreezes = {}

local Stat = ReplicatedStorage:WaitForChild("Stat")

local function getPlayer()
	local character = Tool.Parent
	return Players:GetPlayerFromCharacter(character)
end

local function unfreezeTarget(human)
	local data = ActiveFreezes[human]
	if not data then return end

	if human and human.Parent and human.Health > 0 then
		human.WalkSpeed = data.WalkSpeed
		human.JumpPower = data.JumpPower

		-- Reset Physics
		for _, part in pairs(human.Parent:GetChildren()) do
			if part:IsA("BasePart") then
				part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5) -- Default Roblox physics
			end
		end
	end

	if data.Ice and data.Ice.Parent then
		data.Ice:Destroy()
	end

	ActiveFreezes[human] = nil
end

local function cleanupIce()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "RoundIceBlock" then
			obj:Destroy()
		end
	end
	for human, _ in pairs(ActiveFreezes) do
		unfreezeTarget(human)
	end
	table.clear(ActiveFreezes)
end

Stat.Changed:Connect(function()
	if Stat.Value == "Match Over." then
		cleanupIce()
	end
end)

local function contains(tbl, value)
	for _, v in ipairs(tbl) do
		if v == value then return true end
	end
	return false
end

local function tagHuman(human)
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = getPlayer()
	tag.Parent = human
	Debris:AddItem(tag, 2)
end

local function sameTeam(otherHuman)
	local player = getPlayer()
	local otherPlayer = Players:GetPlayerFromCharacter(otherHuman.Parent)
	if player and otherPlayer then
		if player == otherPlayer then return true end
		if otherPlayer.Neutral then return false end
		return player.TeamColor == otherPlayer.TeamColor
	end
	return false
end

local function checkTeams(otherHuman)
	return not (sameTeam(otherHuman) and not FriendlyFire)
end

local function freezeTarget(human)
	if not human or human.Health <= 0 then return end
	if ActiveFreezes[human] then unfreezeTarget(human) end

	local character = human.Parent
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local ice = Instance.new("Part")
	ice.Name = "RoundIceBlock"
	ice.Size = Vector3.new(5, 7, 5)
	ice.Material = Enum.Material.Ice
	ice.Color = Color3.fromRGB(150, 220, 255)
	ice.Transparency = 0.45
	ice.Anchored = false
	ice.CanCollide = true
	ice.Parent = workspace
	ice.CFrame = root.CFrame

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ice
	weld.Part1 = root
	weld.Parent = ice

	-- Make slippery
	local phys = PhysicalProperties.new(0.3, 0, 0)
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.CustomPhysicalProperties = phys
		end
	end

	ActiveFreezes[human] = {
		Ice = ice,
		WalkSpeed = human.WalkSpeed,
		JumpPower = human.JumpPower
	}

	human.WalkSpeed = 0
	human.JumpPower = 0

	task.delay(FreezeDuration, function()
		unfreezeTarget(human)
	end)
end

local function damageTarget(human, root)
	local myRoot = Tool.Parent:FindFirstChild("HumanoidRootPart")
	if not myRoot or not checkTeams(human) then return end

	local delta = root.Position - myRoot.Position
	human.Sit = true
	tagHuman(human)
	human:TakeDamage(HitDamage)
	table.insert(HitVictims, human)

	if AbilityActive then
		AbilityActive = false
		if Handle:FindFirstChild("IceEffect") then Handle.IceEffect:Destroy() end
		
		-- Notify client to start cooldown
		Remote:FireClient(getPlayer(), "StartCooldown")
		
		freezeTarget(human)
		task.delay(CooldownTime, function() AbilityCooldown = false end)
	end

	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	velocity.Velocity = delta.Unit * 128
	velocity.Parent = root
	Debris:AddItem(velocity, 0.05)

	if Handle:FindFirstChild("Smack") then
		Handle.Smack.Pitch = math.random(90, 110) / 100
		Handle.Smack.TimePosition = 0.15
		Handle.Smack:Play()
	end
end

local function onTouched(part)
	if not HitAble then return end
	if part:IsDescendantOf(Tool.Parent) then return end
	local human = part.Parent:FindFirstChildOfClass("Humanoid")
	if not human or contains(HitVictims, human) then return end
	local root = part.Parent:FindFirstChild("HumanoidRootPart")
	if not root then return end
	damageTarget(human, root)
end

local function onEquip()
	local character = Tool.Parent
	local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
	if rightArm and Tool:FindFirstChild("ArmMesh") then
		ArmMesh = Tool.ArmMesh:Clone()
		ArmMesh.Parent = rightArm
	end
end

local function onUnequip()
	if ArmMesh then
		ArmMesh:Destroy()
		ArmMesh = nil
	end
end

local function onLeftDown()
	local player = getPlayer()
	local hum = player and player.Character and player.Character:FindFirstChild("Humanoid")

	-- Cannot swing if frozen
	if hum and ActiveFreezes[hum] then return end

	if not SwingAble then return end
	SwingAble = false
	task.delay(SwingRestTime, function() SwingAble = true end)

	HitVictims = {}
	task.delay(HitWindup, function()
		HitAble = true
		task.delay(HitWindow, function() HitAble = false end)
	end)

	if player then Remote:FireClient(player, "PlayAnimation", "Swing") end
	task.wait(0.25)

	if Handle:FindFirstChild("Boom") then
		Handle.Boom.Pitch = math.random(80, 100) / 100
		Handle.Boom:Play()
	end
end

local function createIceEffect()
	if Handle:FindFirstChild("IceEffect") then Handle.IceEffect:Destroy() end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "IceEffect"
	emitter.Texture = "rbxassetid://126361365802334"
	emitter.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255))
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	emitter.Speed = NumberRange.new(2, 5)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Rate = 50
	emitter.Parent = Handle
end

local function onAbility()
	if AbilityCooldown or AbilityActive then return end
	AbilityCooldown = true
	AbilityActive = true
	createIceEffect()
end

local function onRemote(player, action)
	if player ~= getPlayer() then return end
	if action == "LeftDown" then onLeftDown()
	elseif action == "Ability" then onAbility() end
end

Tool.Equipped:Connect(onEquip)
Tool.Unequipped:Connect(onUnequip)
Handle.Touched:Connect(onTouched)
Remote.OnServerEvent:Connect(onRemote)
Tool.Destroying:Connect(function() cleanupIce() end)

local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Handle = Tool:WaitForChild("Handle")

local FriendlyFire = false
local ArmMesh

local HitAble = false
local HitWindup = 0.5
local HitWindow = 0.75
local HitDamage = 15
local HitVictims = {}

local SwingAble = true
local SwingRestTime = 2

-- Teleport Settings
local TeleportCooldown = 5
local LastTeleportTime = {} 

-- Setup Particles size and configuration safely
local sparks = Handle:FindFirstChild("Sparks")
if sparks and sparks:IsA("ParticleEmitter") then
	-- Force particles to be small (0.1 to 0.25 studs wide)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	sparks.Enabled = false
end

function getPlayer()
	local char = Tool.Parent
	return game:GetService("Players"):GetPlayerFromCharacter(char)
end

function contains(t, v)
	for _, val in pairs(t) do if val == v then return true end end
	return false
end

function tagHuman(human)
	local tag = Instance.new("ObjectValue")
	tag.Value = getPlayer()
	tag.Name = "creator"
	tag.Parent = human
	game:GetService("Debris"):AddItem(tag, 2)
end

function sameTeam(otherHuman)
	local player = getPlayer()
	local otherPlayer = game:GetService("Players"):GetPlayerFromCharacter(otherHuman.Parent)
	if player and otherPlayer then
		if player == otherPlayer then return true end
		if otherPlayer.Neutral then return false end
		return player.TeamColor == otherPlayer.TeamColor
	end
	return false
end

function checkTeams(otherHuman)
	return not (sameTeam(otherHuman) and not FriendlyFire)
end

function onTouched(part)
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
				bv.maxForce = Vector3.new(1e9, 1e9, 1e9)
				bv.velocity = delta.unit * 128
				bv.Parent = root
				game:GetService("Debris"):AddItem(bv, 0.05)

				if Handle:FindFirstChild("Smack") then
					Handle.Smack.Pitch = math.random(90, 110)/100
					Handle.Smack.TimePosition = 0.15
					Handle.Smack:Play()
				end
			end
		end
	end
end

function onEquip()
	local char = Tool.Parent
	if Tool:FindFirstChild("ArmMesh") then
		local arm = Tool.ArmMesh:Clone()
		arm.Parent = char:FindFirstChild("Right Arm")
		ArmMesh = arm
	end
end

function onUnequip()
	if ArmMesh then
		ArmMesh:Destroy()
		ArmMesh = nil
	end
end

function onLeftDown()
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

	local player = getPlayer()
	if player then
		Remote:FireClient(player, "PlayAnimation", "Swing")
	end

	task.wait(0.25)
	if Handle:FindFirstChild("Boom") then
		Handle.Boom.Pitch = math.random(80, 100)/100
		Handle.Boom:Play()
	end
end

function handleTeleport(player, targetPosition)
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local now = os.clock()
	local lastTime = LastTeleportTime[player.UserId] or 0
	if now - lastTime < TeleportCooldown then return end

	if (targetPosition - root.Position).Magnitude > 120 then return end

	LastTeleportTime[player.UserId] = now

	-- FX: Departure Sparks
	if Handle:FindFirstChild("Sparks") then
		Handle.Sparks:Emit(25)
	end

	-- Instantly update positioning safely above the ground plane
	root.CFrame = CFrame.new(targetPosition + Vector3.new(0, 3.5, 0))

	-- FX: Arrival Sparks
	task.wait(0.02)
	if Handle:FindFirstChild("Sparks") then
		Handle.Sparks:Emit(25)
	end
end

function onRemote(player, func, ...)
	if player ~= getPlayer() then return end

	if func == "LeftDown" then
		onLeftDown(...)
	elseif func == "RequestTeleport" then
		handleTeleport(player, ...)
	end
end

Tool.Equipped:Connect(onEquip)
Tool.Unequipped:Connect(onUnequip)
Handle.Touched:Connect(onTouched)
Remote.OnServerEvent:Connect(onRemote)
local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Handle = Tool:WaitForChild("Handle")

local FriendlyFire = false

local ArmMesh

local HitAble = false
local HitWindup = 0.15
local HitWindow = 0.75
local HitDamage = 15
local HitVictims = {}

local SwingAble = true
local SwingRestTime = 2

-- MISSILE SETTINGS
local MissileCooldown = 6
local MissileDamage = 15
local MissileSpeed = 55 
local MissileLifetime = 5
local MissileBlastRadius = 12
local MissileKnockbackPower = 45 
local MissileOnCooldown = false
local AutoLockRadius = 250 -- Distance around your mouse click to search for the closest player

--returns the wielding player of this tool
function getPlayer()
	local char = Tool.Parent
	return game:GetService("Players"):GetPlayerFromCharacter(char)
end

--helpfully checks a table for a specific value
function contains(t, v)
	for _, val in pairs(t) do
		if val == v then
			return true
		end
	end
	return false
end

--tags a human for the ROBLOX KO system
function tagHuman(human)
	local tag = Instance.new("ObjectValue")
	tag.Value = getPlayer()
	tag.Name = "creator"
	tag.Parent = human
	game:GetService("Debris"):AddItem(tag, 2)
end

--used by checkTeams
function sameTeam(otherHuman)
	local player = getPlayer()
	local otherPlayer = game:GetService("Players"):GetPlayerFromCharacter(otherHuman.Parent)
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

--use this to determine if you want this human to be harmed or not, returns boolean
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
				bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
				bv.Velocity = delta.Unit * 128
				bv.Parent = root
				game:GetService("Debris"):AddItem(bv, 0.05)

				Handle.Smack.Pitch = math.random(90, 110)/100
				Handle.Smack.TimePosition = 0.15
				Handle.Smack:Play()
			end
		end
	end
end

function onEquip()
	local char = Tool.Parent
	local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
	if rightArm and Tool:FindFirstChild("ArmMesh") then
		local arm = Tool.ArmMesh:Clone()
		arm.Parent = rightArm
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
	delay(SwingRestTime, function()
		SwingAble = true
	end)

	delay(HitWindup, function()
		HitAble = true
		delay(HitWindow, function()
			HitAble = false
		end)
	end)

	HitVictims = {}

	Remote:FireClient(getPlayer(), "PlayAnimation", "Swing")

	task.wait(0.25)
	if Handle:FindFirstChild("Boom") then
		Handle.Boom.Pitch = math.random(80, 100)/100
		Handle.Boom:Play()
	end
end

-- MISSILE EXPLOSION WITH WEAKER KNOCKBACK
function explodeMissile(missile)
	if not missile or not missile.Parent then return end
	if missile:GetAttribute("Exploded") then return end
	missile:SetAttribute("Exploded", true)

	local pos = missile.Position

	local explosion = Instance.new("Explosion")
	explosion.Position = pos
	explosion.BlastRadius = 0 
	explosion.BlastPressure = 0
	explosion.Parent = workspace

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Health > 0 then
			local character = obj.Parent
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if root and not root.Anchored and (root.Position - pos).Magnitude <= MissileBlastRadius then
				if character ~= Tool.Parent and checkTeams(obj) then
					tagHuman(obj)
					obj:TakeDamage(MissileDamage)

					local knockbackDir = (root.Position - pos).Unit
					if knockbackDir.Magnitude == 0 then 
						knockbackDir = Vector3.new(0, 1, 0) 
					end

					knockbackDir = (knockbackDir + Vector3.new(0, 0.2, 0)).Unit 

					obj.Sit = true 
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
					bv.Velocity = knockbackDir * MissileKnockbackPower
					bv.Parent = root
					game:GetService("Debris"):AddItem(bv, 0.12)
				end
			end
		end
	end

	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 120, 0)
	flash.Anchored = true
	flash.CanCollide = false
	flash.Size = Vector3.new(1,1,1)
	flash.CFrame = CFrame.new(pos)
	flash.Parent = workspace

	local tweenService = game:GetService("TweenService")
	local tween = tweenService:Create(
		flash,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(MissileBlastRadius * 2, MissileBlastRadius * 2, MissileBlastRadius * 2),
			Transparency = 1
		}
	)
	tween:Play()
	game:GetService("Debris"):AddItem(flash, 0.25)

	missile:Destroy()
end

-- HELPER: Finds the closest player to the mouse click location
function getClosestPlayerToPoint(point)
	local closestTarget = nil
	local shortestDistance = AutoLockRadius

	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local character = player.Character
		if character and character ~= Tool.Parent then
			local humanoid = character:FindFirstChild("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")

			-- FIXED: Corrected typo 'humanid' to 'humanoid' to resolve stack crash
			if humanoid and humanoid.Health > 0 and root and checkTeams(humanid or humanoid) then
				local distance = (root.Position - point).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					closestTarget = root
				end
			end
		end
	end
	return closestTarget
end

-- SPINS UP A SINGLE MISSILE TOWARDS AN INITIAL DESTINATION POINT
function spawnSingleMissile(character, root, targetPosition)
	if not root then return end 

	local spawnPos = root.Position + (root.CFrame.LookVector * 3)
	-- Straight line path to target destination
	local travelDirection = (targetPosition - spawnPos).Unit

	local missile = Instance.new("Part")
	missile.Name = "GauntletMissile"
	missile.Shape = Enum.PartType.Ball
	missile.Material = Enum.Material.Neon
	missile.Color = Color3.fromRGB(255, 85, 0)
	missile.Size = Vector3.new(1.2, 1.2, 1.2)
	missile.CanCollide = false
	missile.CFrame = CFrame.lookAt(spawnPos, spawnPos + travelDirection)
	missile.Parent = workspace

	-- Visual elements
	local trailAttach0 = Instance.new("Attachment")
	trailAttach0.Position = Vector3.new(0, 0.2, 0)
	trailAttach0.Parent = missile

	local trailAttach1 = Instance.new("Attachment")
	trailAttach1.Position = Vector3.new(0, -0.2, 0)
	trailAttach1.Parent = missile

	local trail = Instance.new("Trail")
	trail.Attachment0 = trailAttach0
	trail.Attachment1 = trailAttach1
	trail.Lifetime = 0.2
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 85, 0))
	trail.Parent = missile

	-- Physics Velocity Setup
	local attachment = Instance.new("Attachment")
	attachment.Parent = missile

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.MaxForce = 3e5 
	linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linearVelocity.Attachment0 = attachment
	linearVelocity.VectorVelocity = travelDirection * MissileSpeed
	linearVelocity.Parent = missile

	if Handle:FindFirstChild("Boom") then
		Handle.Boom.Pitch = math.random(110, 130)/100
		Handle.Boom:Play()
	end

	missile.Touched:Connect(function(hit)
		if not missile or not missile.Parent then return end
		if hit:IsDescendantOf(character) or hit.Name == "GauntletMissile" then return end
		explodeMissile(missile)
	end)

	task.delay(MissileLifetime, function()
		if missile and missile.Parent then
			explodeMissile(missile)
		end
	end)
end

-- FIRES THREE MISSILES TOWARD TARGET OR CLOSEST PLAYER LOCATION
function fireMissiles(targetPosition)
	if MissileOnCooldown then return end

	local character = Tool.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	MissileOnCooldown = true
	task.delay(MissileCooldown, function()
		MissileOnCooldown = false
	end)

	if not targetPosition or typeof(targetPosition) ~= "Vector3" then
		targetPosition = root.Position + (root.CFrame.LookVector * 50)
	end

	-- Look for the closest target player to the mouse click
	local targetPlayerRoot = getClosestPlayerToPoint(targetPosition)

	-- INTERCEPTION MECHANISM: Lock the destination point to the player's position at launch time
	local finalDestination = targetPosition
	if targetPlayerRoot then
		finalDestination = targetPlayerRoot.Position
	end

	task.spawn(function()
		for i = 1, 3 do
			if not Tool.Parent or not root then break end
			-- Fires toward the static target spot instead of tracking every frame
			spawnSingleMissile(character, root, finalDestination)
			task.wait(0.15) 
		end
	end)
end

function onRemote(player, func, ...)
	if player ~= getPlayer() then return end

	if func == "LeftDown" then
		onLeftDown(...)
	elseif func == "Missile" then
		fireMissiles(...)
	end
end

Tool.Equipped:Connect(onEquip)
Tool.Unequipped:Connect(onUnequip)
Handle.Touched:Connect(onTouched)
Remote.OnServerEvent:Connect(onRemote)
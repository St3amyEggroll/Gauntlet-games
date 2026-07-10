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

-- Ability Configurations
local AbilityCooldown = 8
local LastAbilityTime = 0
local AbilityCharged = false

-- returns the wielding player of this tool
function getPlayer()
	local char = Tool.Parent
	return game:GetService("Players"):GetPlayerFromCharacter(char)
end

-- helpfully checks a table for a specific value
function contains(t, v)
	for _, val in pairs(t) do
		if val == v then
			return true
		end
	end
	return false
end

-- tags a human for the ROBLOX KO system
function tagHuman(human)
	local tag = Instance.new("ObjectValue")
	tag.Value = getPlayer()
	tag.Name = "creator"
	tag.Parent = human
	game:GetService("Debris"):AddItem(tag)
end

-- used by checkTeams
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

-- use this to determine if you want this human to be harmed or not, returns boolean
function checkTeams(otherHuman)
	return not (sameTeam(otherHuman) and not FriendlyFire)
end

-- Creates a ring of decorative rocks around the trapped victim
function createCrater(position)
	local rockCount = 8
	local radius = 3
	for i = 1, rockCount do
		local angle = (i / rockCount) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * radius, -0.5, math.sin(angle) * radius)

		local rock = Instance.new("Part")
		rock.Size = Vector3.new(math.random(15, 25)/10, math.random(15, 25)/10, math.random(15, 25)/10)
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(90, 90, 90)
		rock.CFrame = CFrame.new(position + offset) * CFrame.Angles(math.random(), math.random(), math.random())
		rock.Anchored = true
		rock.CanCollide = false
		rock.Parent = workspace

		game:GetService("Debris"):AddItem(rock, 3.5)
	end
end

-- Summons the giant boulder from the sky with a shockwave
function spawnSkyBoulder(targetRoot, targetHumanoid)
	local startPos = targetRoot.Position + Vector3.new(0, 40, 0)

	local boulder = Instance.new("Part")
	boulder.Name = "SkyBoulder"
	boulder.Shape = Enum.PartType.Ball
	boulder.Size = Vector3.new(6, 6, 6)
	boulder.Material = Enum.Material.Slate
	boulder.Color = Color3.fromRGB(100, 100, 100)
	boulder.CFrame = CFrame.new(startPos)
	boulder.CanCollide = false
	boulder.Parent = workspace

	local attachment = Instance.new("Attachment", boulder)
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.MaxForce = 1e6
	linearVelocity.VectorVelocity = Vector3.new(0, -60, 0)
	linearVelocity.Attachment0 = attachment
	linearVelocity.Parent = boulder

	local connection
	connection = boulder.Touched:Connect(function(hit)
		if hit:IsDescendantOf(targetRoot.Parent) or hit.Anchored then
			connection:Disconnect()

			-- 1. Deal Damage to primary target
			if targetHumanoid and targetHumanoid.Parent then
				tagHuman(targetHumanoid)
				targetHumanoid:TakeDamage(25)
			end

			-- 2. Shockwave logic: Affect nearby players
			local impactPos = boulder.Position
			local radius = 15
			local overlapParams = OverlapParams.new()
			overlapParams.FilterDescendantsInstances = {Tool.Parent} -- Exclude self
			overlapParams.FilterType = Enum.RaycastFilterType.Exclude

			local nearbyParts = workspace:GetPartBoundsInRadius(impactPos, radius, overlapParams)
			local affectedHumans = {}

			for _, part in pairs(nearbyParts) do
				local char = part.Parent
				local hum = char:FindFirstChild("Humanoid")
				local root = char:FindFirstChild("HumanoidRootPart")

				if hum and root and not affectedHumans[hum] then
					affectedHumans[hum] = true

					-- Push them back
					local pushDir = (root.Position - impactPos).Unit
					pushDir = Vector3.new(pushDir.X, 0.5, pushDir.Z).Unit -- Slight upward arc

					root:ApplyImpulse(pushDir * 2000)
				end
			end

			-- Hit effects
			Handle.Boom.Pitch = 0.6
			Handle.Boom:Play()

			boulder:Destroy()
		end
	end)

	game:GetService("Debris"):AddItem(boulder, 3)
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

				table.insert(HitVictims, human)

				-- CHECK IF ABILITY IS ACTIVE
				if AbilityCharged then
					AbilityCharged = false
					removeGauntletEffect()

					LastAbilityTime = tick()

					Remote:FireClient(getPlayer(), "StartCooldown")

					task.delay(AbilityCooldown, function()
						LastAbilityTime = 0
					end)

					-- Trap enemy in ground
					tagHuman(human)
					human:TakeDamage(HitDamage) -- Deals base punch damage first

					local originalCFrame = root.CFrame
					root.CFrame = originalCFrame * CFrame.new(0, -2.5, 0) -- Sink halfway into ground
					root.Anchored = true

					createCrater(root.Position)
					spawnSkyBoulder(root, human)

					-- Free them after 3 seconds, OR if the attacker dies
					local attackerHumanoid = Tool.Parent:FindFirstChild("Humanoid")
					local freed = false

					local function freeVictim()
						if freed then return end
						freed = true
						if root and root.Parent then
							root.Anchored = false
							root.CFrame = root.CFrame * CFrame.new(0, 2.5, 0) -- Pop back up safely
						end
					end

					local deathConn
					if attackerHumanoid then
						deathConn = attackerHumanoid.Died:Connect(function()
							freeVictim()
							if deathConn then deathConn:Disconnect() end
						end)
					end

					task.delay(3, function()
						freeVictim()
						if deathConn then deathConn:Disconnect() end
					end)
				else
					-- NORMAL PUNCH ATTACK
					local delta = root.Position - myRoot.Position
					human.Sit = true
					tagHuman(human)
					human:TakeDamage(HitDamage)

					local bv = Instance.new("BodyVelocity")
					bv.maxForce = Vector3.new(1e9, 1e9, 1e9)
					bv.velocity = delta.unit * 128
					bv.Parent = root
					game:GetService("Debris"):AddItem(bv, 0.05)
				end

				Handle.Smack.Pitch = math.random(90, 110)/100
				Handle.Smack.TimePosition = 0.15
				Handle.Smack:Play()
			end
		end
	end
end

function applyGauntletEffect()
	if Handle:FindFirstChild("GloveEffectFolder") then return end

	local folder = Instance.new("Folder")
	folder.Name = "GloveEffectFolder"
	folder.Parent = Handle

	Handle.Material = Enum.Material.Slate

	-- Rock particles
	local attachment = Instance.new("Attachment")
	attachment.Name = "RockAttachment"
	attachment.Parent = Handle

	local rocks = Instance.new("ParticleEmitter")
	rocks.Name = "RockParticles"
	rocks.Texture = "rbxasset://textures/particles/smoke_main.dds"
	rocks.Color = ColorSequence.new(Color3.fromRGB(90,90,90))
	rocks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0,0.4),
		NumberSequenceKeypoint.new(1,0)
	})
	rocks.Lifetime = NumberRange.new(0.5,1)
	rocks.Rate = 25
	rocks.Speed = NumberRange.new(1,3)
	rocks.Rotation = NumberRange.new(0,360)
	rocks.RotSpeed = NumberRange.new(-180,180)
	rocks.SpreadAngle = Vector2.new(360,360)
	rocks.Parent = attachment

	-- Dust particles
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "DustParticles"
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(120,110,100))
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,0.2),
		NumberSequenceKeypoint.new(1,1)
	})
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(1,2)
	})
	dust.Lifetime = NumberRange.new(0.8,1.5)
	dust.Rate = 15
	dust.Speed = NumberRange.new(0.5,2)
	dust.SpreadAngle = Vector2.new(360,360)
	dust.Parent = attachment
end

function removeGauntletEffect()
	local folder = Handle:FindFirstChild("GloveEffectFolder")
	if folder then
		folder:Destroy()
	end

	local attachment = Handle:FindFirstChild("RockAttachment")
	if attachment then
		attachment:Destroy()
	end

	Handle.Material = Enum.Material.Plastic
end

function onUnequip()
	if ArmMesh then
		ArmMesh:Destroy()
		ArmMesh = nil
	end
	AbilityCharged = false
	removeGauntletEffect()
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

	wait(0.25)
	Handle.Boom.Pitch = math.random(80, 100)/100
	Handle.Boom:Play()
end

function onRemote(player, func, ...)
	if player ~= getPlayer() then return end

	if func == "LeftDown" then
		onLeftDown(...)
	elseif func == "Ability" then
		activateAbility()
	end
end

function activateAbility()
	if AbilityCharged then
		return
	end

	if LastAbilityTime ~= 0 then
		return
	end

	AbilityCharged = true
	applyGauntletEffect()
end

Tool.Equipped:connect(onEquip)
Tool.Unequipped:connect(onUnequip)
Handle.Touched:connect(onTouched)
Remote.OnServerEvent:connect(onRemote)
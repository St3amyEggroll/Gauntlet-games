local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Handle = Tool:WaitForChild("Handle")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local FriendlyFire = false

local ArmMesh

local HitAble = false
local HitWindup = 0.15
local HitWindow = 0.75
local HitDamage = 15
local HitVictims = {}

local SwingAble = true
local SwingRestTime = 2
local AbilityCooldown = 5
local AbilityActive = true
local AbilityEmpowered = false 
local CurrentChargeEffect = nil

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
	Debris:AddItem(tag, 2)
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

				-- Check for Water Ability
				if AbilityEmpowered then
					AbilityEmpowered = false

					if CurrentChargeEffect then
						CurrentChargeEffect:Destroy()
						CurrentChargeEffect = nil
					end

					AbilityActive = false

					Remote:FireClient(getPlayer(), "StartCooldown")

					task.delay(AbilityCooldown, function()
						AbilityActive = true
					end)

					local drenchEvent = ReplicatedStorage:FindFirstChild("DrenchEvent")
					if drenchEvent then
						local victimPlayer = game:GetService("Players"):GetPlayerFromCharacter(part.Parent)
						if victimPlayer then
							-- Pass a "Muffle" flag alongside the event so client knows to muffle audio/blur
							drenchEvent:FireClient(victimPlayer, "Muffle")
						end

						-- Highlight Effect: Turns the hit player blue for everyone looking at them
						local character = part.Parent
						local blueHighlight = Instance.new("Highlight")
						blueHighlight.Name = "DrenchedHighlight"
						blueHighlight.FillColor = Color3.fromRGB(0, 120, 255)
						blueHighlight.FillTransparency = 0.4
						blueHighlight.OutlineColor = Color3.fromRGB(0, 230, 255)
						blueHighlight.OutlineTransparency = 0.1
						blueHighlight.Parent = character
						Debris:AddItem(blueHighlight, 4) -- Matches the 4-second slow duration

						-- Slow down the victim server-side
						local victimHuman = character:FindFirstChild("Humanoid")
						if victimHuman then
							local originalSpeed = victimHuman.WalkSpeed
							victimHuman.WalkSpeed = 8
							task.delay(4, function()
								if victimHuman and victimHuman.Parent then
									victimHuman.WalkSpeed = originalSpeed
								end
							end)
						end
					end
				end

				local bv = Instance.new("BodyVelocity")
				bv.maxForce = Vector3.new(1e9, 1e9, 1e9)
				bv.velocity = delta.unit * 128
				bv.Parent = root
				Debris:AddItem(bv, 0.05)

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
	local armMeshInst = Tool:FindFirstChild("ArmMesh")
	if armMeshInst then
		local arm = armMeshInst:Clone()
		arm.Parent = char:FindFirstChild("Right Arm")
		ArmMesh = arm
	end
end

function onUnequip()
	if ArmMesh then
		ArmMesh:Destroy()
		ArmMesh = nil
	end
	AbilityEmpowered = false
	if CurrentChargeEffect then
		CurrentChargeEffect:Destroy()
		CurrentChargeEffect = nil
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

	Remote:FireClient(getPlayer(), "PlayAnimation", "Swing")

	task.wait(0.25)
	if Handle:FindFirstChild("Boom") then
		Handle.Boom.Pitch = math.random(80, 100)/100
		Handle.Boom:Play()
	end
end

function onRemote(player, func, ...)
	if player ~= getPlayer() then return end

	if func == "LeftDown" then
		onLeftDown(...)
	elseif func == "Ability" then
		onAbility(...)
	end
end

function onAbility()
	if not AbilityActive or AbilityEmpowered then return end
	AbilityEmpowered = true



	if Handle then
		local burst = Instance.new("Sound")
		burst.SoundId = "rbxassetid://1562208940"
		burst.Volume = 0.8
		burst.Parent = Handle
		burst:Play()
		Debris:AddItem(burst, 2)

		local attachment = Instance.new("Attachment")
		attachment.Name = "WaterChargeEffect"
		attachment.Parent = Handle
		CurrentChargeEffect = attachment

		-- Water aura
		local aura = Instance.new("ParticleEmitter")
		aura.Texture = "rbxassetid://284205403" -- water droplet texture
		aura.Rate = 250
		aura.Speed = NumberRange.new(0, 1)
		aura.Lifetime = NumberRange.new(0.5, 1)
		aura.SpreadAngle = Vector2.new(360,360)
		aura.Color = ColorSequence.new(Color3.fromRGB(0,170,255))
		aura.LightEmission = 0.8
		aura.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0)
		})
		aura.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1)
		})
		aura.Parent = attachment

		-- Mist around fist
		local mist = Instance.new("ParticleEmitter")
		mist.Texture = "rbxassetid://6034176461"
		mist.Rate = 50
		mist.Speed = NumberRange.new(0, 2)
		mist.Lifetime = NumberRange.new(0.8, 1.5)
		mist.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(1, 4)
		})
		mist.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		mist.Color = ColorSequence.new(Color3.fromRGB(100,200,255))
		mist.Parent = attachment

		-- Blue point light
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(0,170,255)
		light.Brightness = 3
		light.Range = 10
		light.Parent = attachment

		task.delay(AbilityCooldown, function()
			if CurrentChargeEffect == attachment then
				attachment:Destroy()
				AbilityEmpowered = false
				CurrentChargeEffect = nil
			end
		end)
	end
end

Tool.Equipped:Connect(onEquip)
Tool.Unequipped:Connect(onUnequip)
Handle.Touched:Connect(onTouched)
Remote.OnServerEvent:Connect(onRemote)
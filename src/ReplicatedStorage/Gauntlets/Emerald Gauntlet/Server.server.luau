local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Handle = Tool:WaitForChild("Handle")
local HealEffect = script:WaitForChild("HealEffect") 

local FriendlyFire = false
local ArmMesh
local HitAble = false
local HitWindup = 0.15
local HitWindow = 0.75
local HitDamage = 15
local HealPercentage = 0.10
local HitVictims = {}
local SwingAble = true
local SwingRestTime = 2


function getPlayer()
	local char = Tool.Parent
	return game:GetService("Players"):GetPlayerFromCharacter(char)
end


function contains(t, v)
	for _, val in pairs(t) do
		if val == v then
			return true
		end
	end
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


function checkTeams(otherHuman)
	return not (sameTeam(otherHuman) and not FriendlyFire)
end


function healPlayer()
	local player = getPlayer()
	if player and player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

		if humanoid and rootPart then
			local maxHealth = humanoid.MaxHealth 
			local healAmount = maxHealth * HealPercentage
			humanoid.Health = math.min(humanoid.Health + healAmount, maxHealth)

			
			local effect = HealEffect:Clone()
			effect.Parent = rootPart
			effect.Enabled = true

			
			game:GetService("Debris"):AddItem(effect, 1)
		end
	end
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

				Handle.Smack.Pitch = math.random(90, 110)/100
				Handle.Smack.TimePosition = 0.15
				Handle.Smack:Play()

				
				healPlayer()
			end
		end
	end
end

function onEquip()
	local char = Tool.Parent
	local arm = Tool.ArmMesh:Clone()
	arm.Parent = char:FindFirstChild("Right Arm")
	ArmMesh = arm
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

	wait(0.25)
	Handle.Boom.Pitch = math.random(80, 100)/100
	Handle.Boom:Play()
end

function onRemote(player, func, ...)
	if player ~= getPlayer() then return end

	if func == "LeftDown" then
		onLeftDown(...)
	end
end

Tool.Equipped:Connect(onEquip)
Tool.Unequipped:Connect(onUnequip)
Handle.Touched:Connect(onTouched)
Remote.OnServerEvent:Connect(onRemote)

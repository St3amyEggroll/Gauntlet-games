local tool = script.Parent
local UserInputService = game:GetService("UserInputService")

local isOnCooldown = false
local equipped = false

local FLING_FORCE = Vector3.new(0, 100, 0) -- Gentle force to fling player upwards
local COOLDOWN_DURATION = 5 -- Cooldown duration in seconds

local function flingPlayer()
	if isOnCooldown then return end

	local character = tool.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	isOnCooldown = true

	-- Apply a gentle force upwards (barely lifting off the ground)
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000) -- Maximum force in all directions
	bodyVelocity.Velocity = FLING_FORCE
	bodyVelocity.Parent = character.PrimaryPart -- Apply to the character's PrimaryPart (e.g., HumanoidRootPart)

	-- Remove the force after a short time to avoid persistent flinging
	task.delay(0.1, function()
		bodyVelocity:Destroy()
	end)

	-- Start cooldown
	task.delay(COOLDOWN_DURATION, function()
		isOnCooldown = false
	end)
end

local function onInput(input, gameProcessed)
	if not equipped or gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		flingPlayer()
	end
end

tool.Equipped:Connect(function()
	equipped = true
	UserInputService.InputBegan:Connect(onInput)
end)

tool.Unequipped:Connect(function()
	equipped = false
end)

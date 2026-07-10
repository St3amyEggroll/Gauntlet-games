local tool = script.Parent
local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")

local superSpeed = 50
local normalSpeed = 16
local activeTime = 3
local cooldownTime = 5
local canUse = true

local inputConnection

local function activateSuperSpeed()
	if not canUse then return end
	canUse = false

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.WalkSpeed = superSpeed

	task.wait(activeTime)

	humanoid.WalkSpeed = normalSpeed

	task.wait(cooldownTime)
	canUse = true
end

tool.Equipped:Connect(function()
	if tool.Name ~= "Energy Gauntlet" then return end

	inputConnection = userInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.F then
			activateSuperSpeed()
		end
	end)
end)

tool.Unequipped:Connect(function()
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
end)

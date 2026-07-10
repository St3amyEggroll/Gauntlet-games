local cooldownTime = 5 -- Cooldown time in seconds
local screenGui = script.Parent -- Assuming the script is inside the ScreenGui
local button = screenGui:WaitForChild("Key") -- Replace with the name of your button or GUI element
local userInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local backpack = player.Backpack

local cooldown = false

-- Function to handle the cooldown
local function startCooldown()
	if not cooldown then
		cooldown = true
		button.Text = "Cooldown... " .. cooldownTime -- Update text to show cooldown
		wait(cooldownTime)
		button.Text = "Ready" -- Reset button text after cooldown
		cooldown = false
	end
end

-- Check if the player has the "Space Gauntlet" tool equipped
local function hasSpaceGauntlet()
	return backpack:FindFirstChild("Space Gauntlet") ~= nil
end

-- Function to toggle visibility of the text
local function toggleTextVisibility(isVisible)
	button.Visible = isVisible
end

-- Listen for the "F" key press and check for the "Space Gauntlet"
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- Ignore input if the game has already processed it

	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.F then
		-- Check if the player has the "Space Gauntlet" tool in the Backpack
		if hasSpaceGauntlet() then
			-- Make the button text visible when the player has the tool
			toggleTextVisibility(true)
			startCooldown()
		else
			-- Hide the text if the player doesn't have the tool
			toggleTextVisibility(false)
			print("You need the Space Gauntlet tool to activate the cooldown!") -- Debug message
		end
	end
end)

-- Make the text invisible initially (in case they don't have the tool)
toggleTextVisibility(false)

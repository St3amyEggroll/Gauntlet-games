local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local canDoubleJump = false
local hasDoubleJumped = false
local oldPower = 0
local lastJumpTime = 0

-- Configuration
local TIME_BETWEEN_JUMPS = 0.2 -- Increased slightly to prevent frame-perfect spam bugs
local DOUBLE_JUMP_POWER_MULTIPLIER = 1

local function onJumpRequest()
	if not character or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end

	-- Check if character has the Wind Gauntlet equipped
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or (tool.Name ~= "Wind Gauntlet" and tool.Name ~= "Wind Gauntlet ") then
		return
	end

	-- Enforce time delay and make sure they haven't already double jumped
	if canDoubleJump and not hasDoubleJumped and (os.clock() - lastJumpTime >= TIME_BETWEEN_JUMPS) then
		hasDoubleJumped = true
		canDoubleJump = false -- Immediately disable to prevent multi-triggering
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

local function onStateChanged(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed then
		canDoubleJump = false
		hasDoubleJumped = false
		humanoid.JumpPower = oldPower > 0 and oldPower or 50
	elseif newState == Enum.HumanoidStateType.Jumping then
		lastJumpTime = os.clock() -- Track exactly when the normal jump started
		canDoubleJump = false
	elseif newState == Enum.HumanoidStateType.Freefall then
		-- Only allow double jump if they didn't just jump a millisecond ago
		if os.clock() - lastJumpTime >= TIME_BETWEEN_JUMPS then
			canDoubleJump = true
		else
			-- Fallback: wait out the remaining time if they entered freefall instantly
			task.spawn(function()
				task.wait(TIME_BETWEEN_JUMPS - (os.clock() - lastJumpTime))
				if humanoid:GetState() == Enum.HumanoidStateType.Freefall and not hasDoubleJumped then
					canDoubleJump = true
				end
			end)
		end
	end
end

-- Initialize oldPower and UseJumpPower if holding the tool already
local currentTool = character:FindFirstChildOfClass("Tool")
if currentTool and (currentTool.Name == "Wind Gauntlet" or currentTool.Name == "Wind Gauntlet ") then
	humanoid.UseJumpPower = true
	oldPower = humanoid.JumpPower
end

character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") and (child.Name == "Wind Gauntlet" or child.Name == "Wind Gauntlet ") then
		humanoid.UseJumpPower = true
		oldPower = humanoid.JumpPower
	end
end)

humanoid.StateChanged:Connect(onStateChanged)
UserInputService.JumpRequest:Connect(onJumpRequest)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	canDoubleJump = false
	hasDoubleJumped = false
	humanoid.StateChanged:Connect(onStateChanged)
end)
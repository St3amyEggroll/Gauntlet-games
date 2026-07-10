local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local SwingAnimation = Tool:WaitForChild("SwingAnimation")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local mouse
local swingTrack

local function getHumanoid()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

local function loadSwingAnimation()
	local humanoid = getHumanoid()
	if not humanoid then return end

	-- reload every equip/respawn just to be safe
	pcall(function()
		swingTrack = humanoid:LoadAnimation(SwingAnimation)
	end)
end

Tool.Equipped:Connect(function(m)
	mouse = m
	loadSwingAnimation()

	if mouse then
		mouse.Button1Down:Connect(function()
			Remote:FireServer("LeftDown")
		end)
	end
end)

Tool.Unequipped:Connect(function()
	-- optional stop
	if swingTrack and swingTrack.IsPlaying then
		swingTrack:Stop()
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(0.25)
	if Tool.Parent == player.Character then
		loadSwingAnimation()
	end
end)

Remote.OnClientEvent:Connect(function(action)
	if action == "PlaySwing" then
		if not swingTrack then
			loadSwingAnimation()
		end

		if swingTrack then
			swingTrack:Play()
		end
	end
end)
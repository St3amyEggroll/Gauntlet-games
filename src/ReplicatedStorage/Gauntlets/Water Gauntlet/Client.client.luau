local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local Mouse = Player:GetMouse()
local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local Tracks = {}
local InputType = Enum.UserInputType

local BeganConnection, EndedConnection

-- Ensure the DrenchEvent exists in ReplicatedStorage
local drenchEvent = ReplicatedStorage:WaitForChild("DrenchEvent")

function playAnimation(animName, ...)
	if Tracks[animName] then
		Tracks[animName]:Play()
	else
		local anim = Tool:FindFirstChild(animName)
		if anim and Tool.Parent and Tool.Parent:FindFirstChild("Humanoid") then
			Tracks[animName] = Tool.Parent.Humanoid:LoadAnimation(anim)
			playAnimation(animName, ...)
		end
	end
end

function stopAnimation(animName)
	if Tracks[animName] then
		Tracks[animName]:Stop()
	end
end

function inputBegan(input, gpe)
	if gpe then return end
	if input.UserInputType == InputType.MouseButton1 then
		Remote:FireServer("LeftDown")
	elseif input.KeyCode == Enum.KeyCode.F then
		Remote:FireServer("Ability")
	end
end

function inputEnded(input)
	if input.UserInputType == InputType.MouseButton1 then
		Remote:FireServer("LeftUp")
	end
end

function onRemote(func, ...)
	if func == "PlayAnimation" then
		playAnimation(...)
	elseif func == "StopAnimation" then
		stopAnimation(...)
	end
end

function onEquip()
	BeganConnection = UIS.InputBegan:Connect(inputBegan)
	EndedConnection = UIS.InputEnded:Connect(inputEnded)
end

function onUnequip()
	if BeganConnection then
		BeganConnection:Disconnect()
		BeganConnection = nil
	end

	if EndedConnection then
		EndedConnection:Disconnect()
		EndedConnection = nil
	end
end

Tool.Equipped:Connect(onEquip)
Tool.Unequipped:Connect(onUnequip)
Remote.OnClientEvent:Connect(onRemote)

-- Handles being drenched (Muffles audio and blurs screen)
drenchEvent.OnClientEvent:Connect(function(mode)
	if mode == "Muffle" then
		-- 1. Create the screen blur
		local blur = Instance.new("BlurEffect")
		blur.Size = 24
		blur.Parent = Lighting

		-- 2. Create the underwater/muffled sound equalizer
		local equalizer = Instance.new("SoundEqualizerEffect")
		equalizer.HighGain = -25 -- Cuts out high pitch crispness
		equalizer.MidGain = -12  -- Damps vocals and footsteps
		equalizer.LowGain = 3    -- Keeps the bass heavy rumble
		equalizer.Parent = SoundService -- Applies to all game audio globally

		-- 3. Clean both up after 4 seconds (Matches server slow duration)
		task.delay(4, function()
			blur:Destroy()
			equalizer:Destroy()
		end)
	end
end)
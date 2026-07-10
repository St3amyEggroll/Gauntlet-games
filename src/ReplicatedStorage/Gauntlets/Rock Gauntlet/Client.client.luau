local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local Mouse = Player:GetMouse()
local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Tracks = {}
local InputType = Enum.UserInputType

local BeganConnection, EndedConnection

function playAnimation(animName, ...)
	if Tracks[animName] then
		Tracks[animName]:Play()
	else
		local anim = Tool:FindFirstChild(animName)
		if anim and Tool.Parent and Tool.Parent:FindFirstChild("Humanoid") then
			-- Humanoid:LoadAnimation is deprecated; using Animator if available
			local humanoid = Tool.Parent.Humanoid
			local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
			Tracks[animName] = animator:LoadAnimation(anim)
			playAnimation(animName, ...)
		end
	end
end

function stopAnimation(animName)
	if Tracks[animName] then
		Tracks[animName]:Stop()
	end
end

function inputBegan(input, processed)
	if processed then return end

	if input.UserInputType == InputType.MouseButton1 then
		Remote:FireServer("LeftDown")
	elseif input.KeyCode == Enum.KeyCode.F then -- Changed from E to F for the rock smash charge
		Remote:FireServer("Ability")
	end
end

function inputEnded(input, processed)
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
	BeganConnection = UIS.InputBegan:connect(inputBegan)
	EndedConnection = UIS.InputEnded:connect(inputEnded)
end

function onUnequip()
	if BeganConnection then
		BeganConnection:disconnect()
		BeganConnection = nil
	end

	if EndedConnection then
		EndedConnection:disconnect()
		EndedConnection = nil
	end

	-- Stop all playing animations when unequipped
	for _, track in pairs(Tracks) do
		track:Stop()
	end
end

Tool.Equipped:connect(onEquip)
Tool.Unequipped:connect(onUnequip)
Remote.OnClientEvent:connect(onRemote)
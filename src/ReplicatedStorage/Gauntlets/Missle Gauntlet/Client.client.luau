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

function inputBegan(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == InputType.MouseButton1 then
		Remote:FireServer("LeftDown")
	elseif input.KeyCode == Enum.KeyCode.F then
		-- PASSING MOUSE.HIT.POSITION: Sends the 3D coordinates of your click/pointer to the server
		Remote:FireServer("Missile", Mouse.Hit.Position)
	end
end

function inputEnded(input, gameProcessed)
	if gameProcessed then return end

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
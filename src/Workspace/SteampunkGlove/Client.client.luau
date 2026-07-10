local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local Mouse = Player:GetMouse()
local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Tracks = {}
local InputType = Enum.UserInputType

local BeganConnection, EndedConnection, MobileConnection

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

function inputBegan(input)
	if input.UserInputType == InputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonL2 then
		Remote:FireServer("LeftDown")
	end
end

function inputEnded(input)
	if input.UserInputType == InputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonL2 then
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
	if UIS.TouchEnabled then
		Player:WaitForChild("PlayerGui"):WaitForChild("Glove").Enabled = true
		local MobileConnection = Player:WaitForChild("PlayerGui"):WaitForChild("Glove"):WaitForChild("Button").MouseButton1Click:Connect(function()
			Remote:FireServer("LeftDown")
		end)
	end

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
	
	if MobileConnection then
		MobileConnection:disconnect()
		MobileConnection = nil
	end
	if UIS.TouchEnabled then
		Player:WaitForChild("PlayerGui"):WaitForChild("Glove").Enabled = false
		
	end
end

Tool.Equipped:connect(onEquip)
Tool.Unequipped:connect(onUnequip)
Remote.OnClientEvent:connect(onRemote)


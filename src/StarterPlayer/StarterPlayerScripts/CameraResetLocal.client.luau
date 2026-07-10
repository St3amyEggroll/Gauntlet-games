local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local function resetCamera()
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = player.Character:WaitForChild("Humanoid")
	end
end

player.CharacterAdded:Connect(resetCamera)

-- Initial reset in case the character is already loaded
if player.Character then
	resetCamera()
end

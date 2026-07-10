
local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ShopUI")
local imageLabel = gui:WaitForChild("ImageLabel")
local gauntletClickedUI = gui:WaitForChild("GauntletClickedUI")
local closeButton = gui.ImageLabel:WaitForChild("CloseButton")
local part = workspace:WaitForChild("Lobby\\", 5):WaitForChild("ShopOne"):WaitForChild("Front")  
local proximityPrompt = part:FindFirstChildOfClass("ProximityPrompt")


if proximityPrompt then
	proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player then
			print("ProximityPrompt activated - Showing GUI")
			imageLabel.Visible = true
		end
	end)
end


if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		print("Close button clicked - Hiding GUI")
		imageLabel.Visible = false
		gauntletClickedUI.Visible = false
	end)
end

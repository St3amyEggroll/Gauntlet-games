local resetEvent = game.ReplicatedStorage:WaitForChild("ResetEvent")

resetEvent.OnServerEvent:Connect(function()
	for _, player in pairs(game.Players:GetPlayers()) do
		local isOut = player:FindFirstChild("PlayerScripts"):FindFirstChild("IsOut")
		if isOut then
			isOut.Value = true
		end
	end
end)

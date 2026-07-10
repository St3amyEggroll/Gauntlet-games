local debounce = false

function onPartTouched(hit)
	if debounce then
		return
	end

	debounce = true

	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player and player.Character then
		local spawnLocation = workspace:FindFirstChild("SpawnLocation") -- Finds the first SpawnLocation
		if spawnLocation then
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				humanoidRootPart.CFrame = spawnLocation.CFrame
			else
				warn("HumanoidRootPart not found in player's character.")
			end
		else
			warn("SpawnLocation not found in workspace.")
		end
	end

	wait(.2) -- Debounce for 2 seconds to prevent rapid teleporting
	debounce = false
end

script.Parent.Touched:Connect(onPartTouched)

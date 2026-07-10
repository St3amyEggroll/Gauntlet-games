local part = script.Parent
local remote = game.ReplicatedStorage:WaitForChild("HazardEvent")
local playersInside = {}

-- Function to check if a character is still touching the part
local function isStillTouching(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Check if the character is overlapping the part
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local parts = workspace:GetPartsInPart(part, params)
	for _, p in pairs(parts) do
		if p:IsDescendantOf(character) then
			return true
		end
	end
	return false
end

part.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = game.Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChild("Humanoid")

	if player and humanoid and not playersInside[player] then
		playersInside[player] = true
		remote:FireClient(player, true, part)

		-- Loop that runs while the player is inside
		while playersInside[player] do
			if isStillTouching(character) then
				humanoid:TakeDamage(10)
			else
				-- Player left the part
				playersInside[player] = nil
				remote:FireClient(player, false, nil)
				break
			end
			task.wait(1)
		end
	end
end)
local part = script.Parent
local DAMAGE_PER_SECOND = 5

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local blurEvent = ReplicatedStorage:WaitForChild("HazardBlurEvent")

local touching = {}

local function isTouchingPart(character)
	for _, p in ipairs(part:GetTouchingParts()) do
		if p:IsDescendantOf(character) then
			return true
		end
	end
	return false
end

part.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player or touching[player] then return end

	touching[player] = true
	blurEvent:FireClient(player, true)

	task.spawn(function()
		while touching[player] and humanoid.Health > 0 do
			if not player.Character or not isTouchingPart(player.Character) then
				break
			end

			humanoid:TakeDamage(DAMAGE_PER_SECOND)
			task.wait(1)
		end

		touching[player] = nil
		blurEvent:FireClient(player, false)
	end)
end)
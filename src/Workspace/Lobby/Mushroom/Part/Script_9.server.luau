local bouncePad = script.Parent
local bounceForce = Vector3.new(0, 90, 0) -- Upward force

bouncePad.Touched:Connect(function(hit)
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoid and rootPart then
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = bounceForce
		bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0) -- Only allow vertical force
		bodyVelocity.P = 1250
		bodyVelocity.Parent = rootPart

		game.Debris:AddItem(bodyVelocity, 0.2) -- Remove after 0.2s
	end
end)

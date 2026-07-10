script.Parent.Touched:Connect(function(Object)
	local Humanoid = Object.Parent : FindFirstChild("Humanoid")
	if Humanoid then
		Humanoid.Health = 0
	end
end)
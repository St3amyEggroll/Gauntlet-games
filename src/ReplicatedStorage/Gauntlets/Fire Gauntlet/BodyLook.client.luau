player = game:GetService('Players').LocalPlayer
mouse = player:GetMouse()

equipped = false

script.Parent.Equipped:Connect(function()
	equipped = true
end)

script.Parent.Unequipped:Connect(function()
	equipped = false
end)

game:GetService('RunService').RenderStepped:Connect(function()
	if equipped then
		local humanoid = player.Character:FindFirstChildWhichIsA('Humanoid')
		if humanoid and humanoid.Health > 0 and mouse.Hit and humanoid.Sit == false then
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local lookAt = Vector3.new(mouse.Hit.p.X, rootPart.Position.Y, mouse.Hit.p.Z)
				local cf = CFrame.new(rootPart.CFrame.p, lookAt)
				rootPart.CFrame = cf
			end
		end
	end
end)
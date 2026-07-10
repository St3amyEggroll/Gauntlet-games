flareGun = script.Parent
handle = flareGun.Handle

player = game:GetService('Players').LocalPlayer
character = player.Character

mouse = player:GetMouse()

shots = 100
cooldown = 3

flare = {
	speed = 100,
	canDamage = true,
	damage = 50,
	damageRadius = 20,
	lifeTime = 10,
	rangeBasedDamage = true,
	knockback = true,
}

shoot = game:GetService('ReplicatedStorage'):WaitForChild("FlareGunShoot")

shotsLeft = shots
lastShot = 0
equipped = false

mouse.Button1Down:Connect(function()
	if equipped and (shotsLeft == shots or ((time() - lastShot) > cooldown and shotsLeft > 0)) then
		lastShot = time()
		shotsLeft -= 1
		shoot:FireServer(flareGun, mouse.Hit, flare, handle.Shoot)
	elseif equipped then
		handle.Empty:Play()
	end
end)

flareGun.Equipped:Connect(function()
	equipped = true
	handle.Equip:Play()
end)

flareGun.Unequipped:Connect(function()
	equipped = false
end)
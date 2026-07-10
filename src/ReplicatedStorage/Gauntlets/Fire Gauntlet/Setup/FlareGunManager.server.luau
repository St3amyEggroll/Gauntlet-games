shoot = game:GetService('ReplicatedStorage'):WaitForChild("FlareGunShoot")

shoot.OnServerEvent:Connect(function(player, flareGun, mouseHit, values, sound)
	sound:Play()
	
	local flare = game:GetService('ReplicatedStorage'):FindFirstChild("Flare"):Clone()
	flare.Parent = game.Workspace
	flare:SetNetworkOwner(player)
	flare.CFrame = flareGun.Handle.ShootPart.CFrame
	
	flare:FindFirstChildWhichIsA('ParticleEmitter').Enabled = true
	flare:FindFirstChildWhichIsA('PointLight').Enabled = true
	
	flare.Visual.Transparency = 0
	flare.Visual:FindFirstChildWhichIsA('Highlight').Enabled = true
	
	local vfx = script.BulletVFX:Clone()
	vfx.Parent = flareGun.Handle.ShootPart
	vfx.Img.Slideshow.Enabled = true
	
	flareGun.Handle.ShootPart:FindFirstChildWhichIsA('SpotLight').Enabled = true
	
	local bodyVelocity = Instance.new('BodyVelocity', flare)
	bodyVelocity.Velocity = (mouseHit.Position - flare.Position).Unit * values.speed
	
	local valuesFolder = flare.Values
	
	valuesFolder.Owner.Value = player
	valuesFolder.CanDamage.Value = values.canDamage
	valuesFolder.Damage.Value = values.damage
	valuesFolder.DamageRadius.Value = values.damageRadius
	valuesFolder.LifeTime.Value = values.lifeTime
	valuesFolder.RangeBasedDamage.Value = values.rangeBasedDamage
	valuesFolder.Knockback.Value = values.knockback
	
	flare.BulletScript.Enabled = true
	
	wait(0.15)
	
	flareGun.Handle.ShootPart:FindFirstChildWhichIsA('SpotLight').Enabled = false
end)
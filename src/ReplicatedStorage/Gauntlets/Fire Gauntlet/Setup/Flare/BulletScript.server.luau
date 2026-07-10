flare = script.Parent

values = flare.Values

owner = values.Owner.Value
canDamage = values.CanDamage.Value
damage = values.Damage.Value
damageRadius = values.DamageRadius.Value
lifeTime = values.LifeTime.Value
rangeBasedDamage = values.RangeBasedDamage.Value
knockback = values.Knockback.Value

ignoreParts = {"Flare", "Handle", "ShootPart", "Visual", "VisualFlareExplosion", "InnerVisualFlareExplosion"}

fading = false
exploding = false
lightInc = 0.2
timeCreated = time()

flare.Ambient:Play()

function fade()
	fading = true
	
	local inc = 0.1
	local timer = 20
	local currentTime = 0
	
	while currentTime < timer do
		wait(inc)
		flare:FindFirstChildWhichIsA('BodyVelocity').Velocity -= Vector3.new(0,(inc * 3),0)
		flare:FindFirstChildWhichIsA('PointLight').Brightness -= inc
		flare.Transparency -= inc
		timer += 1
	end
	
	flare:FindFirstChildWhichIsA('PointLight'):Remove()
	flare:FindFirstChildWhichIsA('ParticleEmitter'):Remove()
end

function explode()
	if not exploding then
		exploding = true

		flare.Ambient:Stop()
		flare.Explosion:Play()

		local sizeInc = 3
		local radius = (damageRadius * 2)
		local light = flare:FindFirstChildWhichIsA('PointLight')

		flare.Anchored = true
		flare.CanCollide = false
		flare.Visual.Transparency = 1
		flare.CanTouch = false
		flare.CanQuery = false
		flare:FindFirstChildWhichIsA('ParticleEmitter'):Remove()

		local visual = Instance.new('Part', game.Workspace)
		visual.Name = "VisualFlareExplosion"
		visual.CanCollide = false
		visual.CanTouch = false
		visual.CanQuery = false
		visual.CastShadow = false
		visual.Transparency = 0.3
		visual.Color = flare.Color
		visual.Material = Enum.Material.ForceField
		visual.Size = Vector3.new(0.1,0.1,0.1)
		visual.Shape = Enum.PartType.Ball
		visual.Anchored = true
		visual.Position = flare.Position

		local innerVisual = visual:Clone()
		innerVisual.Parent = game.Workspace
		innerVisual.Name = "InnerVisualFlareExplosion"
		innerVisual.Material = Enum.Material.Neon
		innerVisual.Color = Color3.new(1, 0, 0)

		flare:FindFirstChildWhichIsA('PointLight').Range = (radius / 2)
		flare:FindFirstChildWhichIsA('PointLight').Brightness = 10

		while visual.Size.X < radius and visual.Size.Y < radius and visual.Size.Z < radius and visual.Transparency < 1 do
			wait()
			flare:FindFirstChildWhichIsA('PointLight').Range -= (sizeInc / 10)
			flare:FindFirstChildWhichIsA('PointLight').Brightness -= (sizeInc / 10)
			visual.Transparency += (sizeInc / 100)
			if visual.Size.X < radius then
				visual.Size += Vector3.new(sizeInc,0,0)
			end
			if visual.Size.Y < radius then
				visual.Size += Vector3.new(0,sizeInc,0)
			end
			if visual.Size.Z < radius then
				visual.Size += Vector3.new(0,0,sizeInc)
			end
			innerVisual.Size = (visual.Size / 1.5)
			innerVisual.Transparency = (visual.Transparency * 1.5)
		end

		innerVisual:Destroy()
		visual:Destroy()
		flare:Destroy()
	end
end

flare.Touched:Connect(function(hit)
	if not table.find(ignoreParts, hit.Name) and not fading and not exploding then
		local rootPartsInRange = {}

		local function getRootPartsInRange(objects)
			for i = 1, #objects do
				if objects[i].Name == "HumanoidRootPart" and objects[i]:IsA('Part') then
					if (flare.Position - objects[i].Position).Magnitude < damageRadius then
						table.insert(rootPartsInRange, objects[i])
					end
				else
					getRootPartsInRange(objects[i]:GetChildren())
				end
			end
		end
		getRootPartsInRange(game.Workspace:GetChildren())
		
		if canDamage then
			for i,v in pairs(rootPartsInRange) do
				local humanoid = v.Parent:FindFirstChildWhichIsA('Humanoid')
				if humanoid then
					if rangeBasedDamage then
						local distance = (v.Position - flare.Position).Magnitude
						local dmg = damage * (1 - (distance / damageRadius)^2)
						humanoid:TakeDamage(dmg)
						--print("["..v.Parent.Name.."] Distance from explosion: "..tostring(distance).." | Damage taken: "..tostring(dmg))
					else
						humanoid:TakeDamage(damage)
					end
				end
				if knockback then
					local force = 35
					local bodyVelocity = Instance.new('BodyVelocity', v)
					bodyVelocity.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
					bodyVelocity.Velocity = (v.Position - flare.Position).Unit * force + Vector3.new(0,(force / 2),0)
					wait(0.1)
					bodyVelocity:Remove()
				end
			end
		end
		
		explode()
	end
end)

while wait() do
	if ((time() - timeCreated) > lifeTime) and not fading then
		fade()
	end
	if (time() - timeCreated) > 1 and not fading then
		flare:FindFirstChildWhichIsA('BodyVelocity').Velocity -= Vector3.new(0,0.3,0)
	end
	if not fading or exploding then
		local light = flare:FindFirstChildWhichIsA('PointLight')
		local min = 2
		local max = 10
		light.Brightness += lightInc
		if light.Brightness > max then
			lightInc = -0.2
		elseif light.Brightness < min then
			lightInc = 0.2
		end
		light.Range = light.Brightness * 2
	end
end
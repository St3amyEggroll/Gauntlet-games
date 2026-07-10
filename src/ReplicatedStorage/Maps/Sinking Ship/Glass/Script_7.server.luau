local broken = false
local regenTime = 30
local shards = 5
local strength = 27

local sound = Instance.new("Sound",script.Parent)
sound.SoundId = "rbxassetid://2731462191"
sound.Volume = 2

script.Parent.Touched:Connect(function(part)
	if broken == false and part.Velocity.Magnitude > strength then
		broken = true
		sound:Play()
		print("Glass broken")
		local t = script.Parent.Transparency
		for i = 1,shards do
			local shard = Instance.new("Part")
			shard.Size = Vector3.new(
				script.Parent.Size.X/math.random(2,5),
				script.Parent.Size.Y/math.random(2,5),
				script.Parent.Size.Z/math.random(2,5)
			)
			shard.Position = script.Parent.Position - Vector3.new(
				math.random(-script.Parent.Size.X/2,script.Parent.Size.X/2),
				math.random(-script.Parent.Size.Y/2,script.Parent.Size.Y/2),
				math.random(-script.Parent.Size.Z/2,script.Parent.Size.Z/2)
			)
			shard.Orientation = Vector3.new(
				math.random(-360,360),
				math.random(-360,360),
				math.random(-360,360)
			)
			shard.Parent = script.Parent
			shard.Material = script.Parent.Material
			shard.Color = script.Parent.Color
			shard.Transparency = script.Parent.Transparency
			game.Debris:AddItem(shard,regenTime)
		end
		script.Parent.Transparency = 1
		script.Parent.CanCollide = false
		wait(regenTime)
		script.Parent.Transparency = t
		script.Parent.CanCollide = true
		broken = false
	end
end)
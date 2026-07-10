local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local blurEvent = ReplicatedStorage:WaitForChild("HazardBlurEvent")

local blur = Lighting:FindFirstChild("HazardBlur")
if not blur then
	blur = Instance.new("BlurEffect")
	blur.Name = "HazardBlur"
	blur.Parent = Lighting
end
blur.Size = 0

local tint = Lighting:FindFirstChild("HazardTint")
if not tint then
	tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "HazardTint"
	tint.Parent = Lighting
end

-- Make sure it's OFF by default
tint.TintColor = Color3.new(1, 1, 1)
tint.Brightness = 0

local function disableEffects()
	blur.Size = 0
	tint.TintColor = Color3.new(1, 1, 1)
	tint.Brightness = 0
end

local function enableEffects()
	blur.Size = 20
	tint.TintColor = Color3.fromRGB(100, 170, 255)
	tint.Brightness = -0.1
end

blurEvent.OnClientEvent:Connect(function(enabled)
	if enabled then
		enableEffects()
	else
		disableEffects()
	end
end)

local function onCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	disableEffects()

	humanoid.Died:Connect(function()
		disableEffects()
	end)
end

if player.Character then
	onCharacter(player.Character)
end

player.CharacterAdded:Connect(onCharacter)
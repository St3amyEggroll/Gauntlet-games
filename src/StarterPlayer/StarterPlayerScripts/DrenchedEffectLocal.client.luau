local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local DrenchEvent = ReplicatedStorage:WaitForChild("DrenchEvent")

local currentEffects = {}

local function cleanupEffects()
	for _, effect in pairs(currentEffects) do
		if effect and effect.Parent then
			effect:Destroy()
		end
	end
	currentEffects = {}
end

local function applyDrenchedEffect()
	-- Cleanup any existing effect first
	cleanupEffects()
	
	-- Visual Effect: Blur
	local blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = Lighting
	table.insert(currentEffects, blur)
	
	-- Visual Effect: Blue Tint
	local tint = Instance.new("ColorCorrectionEffect")
	tint.TintColor = Color3.fromRGB(120, 180, 255) -- Slightly deeper blue
	tint.Saturation = -0.3
	tint.Parent = Lighting
	table.insert(currentEffects, tint)
	
	-- Audio Effect: Equalizer (More aggressive muffling)
	local filter = Instance.new("EqualizerSoundEffect")
	filter.LowGain = 5 -- Boost lows slightly for "heavy" feel
	filter.MidGain = -30
	filter.HighGain = -80 -- Kill all highs
	filter.Parent = SoundService
	table.insert(currentEffects, filter)
	
	-- Tween in (Highly intense blur)
	TweenService:Create(blur, TweenInfo.new(0.4), {Size = 72}):Play() -- Increased blur from 56 to 72	
	-- Duration logic
	local duration = 4
	
	-- Death cleanup connection
	local deathConn
	local function onDeath()
		cleanupEffects()
		if deathConn then deathConn:Disconnect() end
	end
	
	if Player.Character and Player.Character:FindFirstChild("Humanoid") then
		deathConn = Player.Character.Humanoid.Died:Connect(onDeath)
	end
    
    -- Safety cleanup if character changes
    local charConn = Player.CharacterAdded:Once(onDeath)

	task.wait(duration)
	
	if deathConn then deathConn:Disconnect() end
    if charConn then charConn:Disconnect() end
	
	-- Tween out
	local tweenBlur = TweenService:Create(blur, TweenInfo.new(1), {Size = 0})
	local tweenTint = TweenService:Create(tint, TweenInfo.new(1), {TintColor = Color3.new(1, 1, 1)})
	
	tweenBlur:Play()
	tweenTint:Play()
	
	task.wait(1)
	cleanupEffects()
end

DrenchEvent.OnClientEvent:Connect(applyDrenchedEffect)

-- Global reset on respawn
Player.CharacterAdded:Connect(cleanupEffects)

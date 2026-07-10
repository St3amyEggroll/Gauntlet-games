--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Create a unique DataStore specifically for this reward item
local RewardDataStore = DataStoreService:GetDataStore("Unique_Model_Reward_DS_v1")

local model = script.Parent
local prompt = model:WaitForChild("ProximityPrompt") :: ProximityPrompt

-- Configuration
local COIN_REWARD = 50
local DISPLAY_TIME = 2.5 

-- Generates a unique save key for this specific player
local function getSaveKey(player: Player)
	return "Player_" .. player.UserId .. "_Claimed"
end

-- =============================================================================
-- CLEAN BOTTOM NOTIFICATION SYSTEM
-- =============================================================================
local function createBottomNotification(player: Player, message: string, borderColor: Color3)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	-- 1. Main ScreenGui Container
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CleanRewardNotice"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- 2. Compact Notification Toast Frame
	local toastFrame = Instance.new("Frame")
	toastFrame.Name = "Toast"
	toastFrame.Size = UDim2.fromOffset(340, 42)
	-- Placed neatly at the bottom center of the screen
	toastFrame.Position = UDim2.new(0.5, 0, 0.88, 0) 
	toastFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	toastFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	toastFrame.BackgroundTransparency = 1 -- Start transparent for fade-in effect
	toastFrame.ClipsDescendants = true
	toastFrame.Parent = screenGui

	-- Rounded Corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = toastFrame

	-- Sleek Border Outline
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = borderColor
	stroke.Transparency = 1 -- Start transparent for fade-in
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = toastFrame

	-- 3. Notification Text Label
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -24, 1, 0)
	textLabel.Position = UDim2.fromOffset(12, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 13
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.TextTransparency = 1 -- Start transparent for fade-in
	textLabel.Parent = toastFrame

	-- Parent to PlayerGui to make it visible
	screenGui.Parent = playerGui

	-- 4. Fade-In Animation
	local fadeInInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(toastFrame, fadeInInfo, {BackgroundTransparency = 0.15}):Play()
	TweenService:Create(stroke, fadeInInfo, {Transparency = 0}):Play()
	TweenService:Create(textLabel, fadeInInfo, {TextTransparency = 0}):Play()

	-- 5. Wait, Fade-Out, and Clean up
	task.delay(DISPLAY_TIME, function()
		if not toastFrame or not screenGui then return end
		local fadeOutInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		local fadeTween = TweenService:Create(toastFrame, fadeOutInfo, {BackgroundTransparency = 1})
		TweenService:Create(stroke, fadeOutInfo, {Transparency = 1}):Play()
		TweenService:Create(textLabel, fadeOutInfo, {TextTransparency = 1}):Play()

		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end)
end

-- =============================================================================
-- PROXIMITY PROMPT TRIGGER
-- =============================================================================
prompt.Triggered:Connect(function(player)
	local coinsValue = player:GetAttribute("Coins") or 0

	local saveKey = getSaveKey(player)

	-- Check DataStore to see if they already completed this interaction previously
	local hasClaimed = false
	local success, err = pcall(function()
		hasClaimed = RewardDataStore:GetAsync(saveKey) or false
	end)

	if not success then
		warn("Failed to pull DataStore records: " .. tostring(err))
		createBottomNotification(player, "⚠️ Data error, try again later", Color3.fromRGB(240, 60, 80))
		return
	end

	-- Logic Execution
	if hasClaimed then
		-- Clean failure notification (Crimson Red Border)
		createBottomNotification(player, "❌ You already claimed these coins!", Color3.fromRGB(240, 60, 80))
	else
		-- Commit update validation internally to data table structures
		local saveSuccess, saveErr = pcall(function()
			RewardDataStore:SetAsync(saveKey, true)
		end)

		if saveSuccess then
			-- Award currency assets to player profiles explicitly (Teal/Mint Green Border)
			player:SetAttribute("Coins", coinsValue + COIN_REWARD)
			createBottomNotification(player, "✨ +" .. COIN_REWARD .. " Coins Claimed!", Color3.fromRGB(0, 255, 180))
		else
			warn("Failed to commit verification save state: " .. tostring(saveErr))
			createBottomNotification(player, "⚠️ Save error, data did not store", Color3.fromRGB(240, 60, 80))
		end
	end
end)
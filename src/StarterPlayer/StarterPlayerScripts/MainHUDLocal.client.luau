--!strict
-- MainHUDLocal — the persistent HUD: coin counter + reward timer, match status,
-- left-middle menu grid, reopen buttons, health/dash bars, mobile controls,
-- players-remaining pill. Replaces UIPolisherLocal's HUD modules.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")
local StatValue = ReplicatedStorage:WaitForChild("Stat") :: StringValue

local device = UIKit.deviceType()
local isTouch = device ~= "PC"

-- Remove legacy HUD guis if an old copy is still around
for _, name in ipairs({ "ModernCoinHUD", "ModernTimerHUD", "ModernVitalsHUD", "ModernPlayersRemainingHUD", "ModernSettingsUI", "PremiumGauntletShop" }) do
	local old = playerGui:FindFirstChild(name)
	if old then old:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "MainHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = playerGui
UIKit.autoScale(gui)

--========================================================
-- TOP LEFT: reward timer + coin counter + reopen buttons
--========================================================
local topLeft = Instance.new("Frame")
topLeft.Name = "TopLeft"
topLeft.BackgroundTransparency = 1
topLeft.Position = UDim2.new(0, 14, 0, 14)
topLeft.Size = UDim2.fromOffset(210, 300)
topLeft.Parent = gui

local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 8)
list.Parent = topLeft

-- Reward timer pill: counts down to the next free 10 coins
local rewardPill = UIKit.card("RewardPill", topLeft)
rewardPill.Size = UDim2.new(1, 0, 0, 42)
rewardPill.LayoutOrder = 1

local giftIcon = UIKit.label(rewardPill, "🎁", 20)
giftIcon.Size = UDim2.fromOffset(30, 30)
giftIcon.Position = UDim2.new(0, 8, 0.5, -15)

local rewardTime = UIKit.label(rewardPill, "05:00", 20)
rewardTime.Size = UDim2.new(0, 74, 1, 0)
rewardTime.Position = UDim2.new(0, 40, 0, 0)
rewardTime.TextXAlignment = Enum.TextXAlignment.Left
rewardTime.TextColor3 = Color3.fromRGB(158, 232, 112)
UIKit.textStroke(rewardTime, 2)

local rewardHint = UIKit.label(rewardPill, "+" .. GameConfig.PassiveReward .. " coins", 12, T.FONT_BOLD)
rewardHint.Size = UDim2.new(1, -120, 1, 0)
rewardHint.Position = UDim2.new(0, 118, 0, 0)
rewardHint.TextXAlignment = Enum.TextXAlignment.Left
rewardHint.TextColor3 = T.TEXT_DIM

-- Coin counter + plus button
local coinPill = UIKit.card("CoinPill", topLeft)
coinPill.Size = UDim2.new(1, 0, 0, 46)
coinPill.LayoutOrder = 2

local coinIcon = Instance.new("ImageLabel")
coinIcon.BackgroundTransparency = 1
coinIcon.Size = UDim2.fromOffset(28, 28)
coinIcon.Position = UDim2.new(0, 9, 0.5, -14)
coinIcon.Image = T.COIN_ICON
coinIcon.Parent = coinPill

local coinLabel = UIKit.label(coinPill, "0", 21)
coinLabel.Size = UDim2.new(1, -100, 1, 0)
coinLabel.Position = UDim2.new(0, 44, 0, 0)
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.TextColor3 = T.GOLD
UIKit.textStroke(coinLabel, 2)

local plusBtn = UIKit.button("+", "lime", coinPill)
plusBtn.Size = UDim2.fromOffset(34, 34)
plusBtn.AnchorPoint = Vector2.new(1, 0.5)
plusBtn.Position = UDim2.new(1, -6, 0.5, 0)
plusBtn.TextSize = 24
plusBtn.MouseButton1Click:Connect(function()
	(UIBus.OpenShop :: BindableEvent):Fire("Coins")
end)

local function updateCoins()
	coinLabel.Text = UIKit.formatNumber(player:GetAttribute("Coins") or 0)
end
player:GetAttributeChangedSignal("Coins"):Connect(function()
	updateCoins()
	TweenService:Create(coinIcon, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(34, 34) }):Play()
	task.delay(0.13, function()
		TweenService:Create(coinIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(28, 28) }):Play()
	end)
end)
updateCoins()

-- Reopen buttons (map vote + inventory), sitting under the timer/coins
local function smallReopen(text: string, icon: string, order: number, onClick: () -> ()): TextButton
	local b = UIKit.button(icon .. "  " .. text, "blue", topLeft)
	b.Size = UDim2.new(1, 0, 0, 34)
	b.TextSize = 14
	b.LayoutOrder = order
	b.MouseButton1Click:Connect(onClick)
	return b
end

local mapVoteBtn = smallReopen("MAP VOTE", "🗺️", 3, function()
	(UIBus.OpenMapVote :: BindableEvent):Fire()
end)
mapVoteBtn.Visible = false -- only shown while a vote is running (MapVoteLocal toggles it)
mapVoteBtn.Name = "MapVoteReopen"

local invBtn = smallReopen("INVENTORY", "🎒", 4, function()
	(UIBus.OpenInventory :: BindableEvent):Fire()
end)
invBtn.Name = "InventoryReopen"

--========================================================
-- TOP CENTER: match status pill + players remaining
--========================================================
local statusPill = UIKit.card("StatusPill", gui)
statusPill.AnchorPoint = Vector2.new(0.5, 0)
statusPill.Position = UDim2.new(0.5, 0, 0, 10)
statusPill.Size = UDim2.fromOffset(320, 40)

local statusLabel = UIKit.label(statusPill, "Loading...", 17)
statusLabel.Size = UDim2.new(1, -16, 1, 0)
statusLabel.Position = UDim2.new(0, 8, 0, 0)
UIKit.textStroke(statusLabel, 2)

StatValue.Changed:Connect(function(v)
	statusLabel.Text = v
end)
statusLabel.Text = StatValue.Value

local remainPill = UIKit.card("RemainPill", gui)
remainPill.AnchorPoint = Vector2.new(0.5, 0)
remainPill.Position = UDim2.new(0.5, 0, 0, 56)
remainPill.Size = UDim2.fromOffset(170, 32)
remainPill.Visible = false

local remainLabel = UIKit.label(remainPill, "👥 0 remaining", 14, T.FONT_BOLD)
remainLabel.Size = UDim2.new(1, -10, 1, 0)
remainLabel.Position = UDim2.new(0, 5, 0, 0)
UIKit.textStroke(remainLabel, 1.5)

task.spawn(function()
	while true do
		local active = Workspace:GetAttribute("MatchActive") == true
		local ingame = Workspace:FindFirstChild("Ingame")
		if active and ingame then
			local count = 0
			for _, child in ipairs(ingame:GetChildren()) do
				local hum = child:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then count += 1 end
			end
			remainLabel.Text = "👥 " .. count .. " remaining"
			remainPill.Visible = true
		else
			remainPill.Visible = false
		end
		task.wait(1)
	end
end)

--========================================================
-- LEFT MIDDLE: expandable menu grid
--========================================================
local MENU_BUTTONS = {
	{ Key = "Shop", Icon = "🛒", Label = "Shop", Style = { T.ORANGE_A, T.ORANGE_B }, Event = "OpenShop" },
	{ Key = "Quests", Icon = "📜", Label = "Quests", Style = { T.BLUE_A, T.BLUE_B }, Event = "OpenQuests" },
	{ Key = "Spin", Icon = "🎡", Label = "Spin", Style = { T.PURPLE_A, T.PURPLE_B }, Event = "OpenSpin" },
	{ Key = "Settings", Icon = "⚙️", Label = "Config", Style = { T.GREY_A, T.GREY_B }, Event = "OpenSettings" },
	{ Key = "Daily", Icon = "📅", Label = "Daily", Style = { T.GOLD_A, T.GOLD_B }, Event = "OpenDaily" },
	{ Key = "Troll", Icon = "🃏", Label = "Troll", Style = { T.RED_A, T.RED_B }, Event = "OpenTroll" },
}

local grid = Instance.new("Frame")
grid.Name = "MenuGrid"
grid.BackgroundTransparency = 1
grid.AnchorPoint = Vector2.new(0, 0.5)
grid.Position = UDim2.new(0, 14, 0.5, 0)
grid.Size = UDim2.fromOffset(158, 246)
grid.Parent = gui

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(74, 74)
gridLayout.CellPadding = UDim2.fromOffset(10, 10)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = grid

local dailyCountdown: TextLabel? = nil

for i, def in ipairs(MENU_BUTTONS) do
	local btn = Instance.new("TextButton")
	btn.Name = def.Key .. "Button"
	btn.LayoutOrder = i
	btn.BackgroundColor3 = def.Style[2]
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = grid
	UIKit.corner(btn, 15)
	UIKit.stroke(btn, T.OUTLINE)
	UIKit.vgradient(btn, def.Style[1], def.Style[2])
	UIKit.gloss(btn)

	local icon = UIKit.label(btn, def.Icon, 26)
	icon.Size = UDim2.new(1, 0, 0, 30)
	icon.Position = UDim2.new(0, 0, 0, 6)

	local lbl = UIKit.label(btn, def.Label, 13)
	lbl.Size = UDim2.new(1, 0, 0, 16)
	lbl.Position = UDim2.new(0, 0, 0, 38)
	UIKit.textStroke(lbl, 2)

	if def.Key == "Daily" then
		icon.Position = UDim2.new(0, 0, 0, 2)
		lbl.Position = UDim2.new(0, 0, 0, 32)
		local cd = UIKit.label(btn, "", 11, T.FONT_BOLD)
		cd.Size = UDim2.new(1, 0, 0, 14)
		cd.Position = UDim2.new(0, 0, 0, 50)
		cd.TextColor3 = Color3.fromRGB(70, 42, 0)
		dailyCountdown = cd
	end

	UIKit.bindButtonFX(btn)
	btn.MouseButton1Click:Connect(function()
		local ev = UIBus:FindFirstChild(def.Event)
		if ev and ev:IsA("BindableEvent") then
			ev:Fire()
		end
	end)
end

--========================================================
-- COUNTDOWN LOOPS (passive reward + daily button)
--========================================================
task.spawn(function()
	while true do
		-- Passive reward: server sets NextPassiveAt (os.time epoch)
		local nextAt = player:GetAttribute("NextPassiveAt")
		if typeof(nextAt) == "number" then
			local left = nextAt - os.time()
			rewardTime.Text = UIKit.formatTime(left)
			if left <= 0 then rewardTime.Text = "00:00" end
		end

		-- Daily button countdown: DailyRewardLocal maintains DailyReadyAt
		if dailyCountdown then
			local readyAt = player:GetAttribute("DailyReadyAt")
			if typeof(readyAt) == "number" then
				local left = readyAt - os.time()
				if left <= 0 then
					dailyCountdown.Text = "READY!"
					dailyCountdown.TextColor3 = Color3.fromRGB(20, 90, 0)
				else
					dailyCountdown.Text = UIKit.formatTime(left)
					dailyCountdown.TextColor3 = Color3.fromRGB(70, 42, 0)
				end
			else
				dailyCountdown.Text = "..."
			end
		end
		task.wait(1)
	end
end)

-- Toast + coin pop when the passive reward lands
player:GetAttributeChangedSignal("PassiveRewardPing"):Connect(function()
	UIKit.notify("You received " .. GameConfig.PassiveReward .. " coins for playing!", T.GOLD, "🎁")
end)

--========================================================
-- BOTTOM CENTER: health + dash bars (beneath the ability button)
--========================================================
local vitals = Instance.new("Frame")
vitals.Name = "Vitals"
vitals.BackgroundTransparency = 1
vitals.AnchorPoint = Vector2.new(0.5, 1)
vitals.Position = UDim2.new(0.5, 0, 1, -12)
vitals.Size = UDim2.fromOffset(260, 46)
vitals.Parent = gui

local function makeBar(name: string, icon: string, colorA: Color3, colorB: Color3, y: number, height: number)
	local track = Instance.new("Frame")
	track.Name = name .. "Track"
	track.BackgroundColor3 = Color3.fromRGB(12, 14, 34)
	track.BorderSizePixel = 0
	track.Size = UDim2.new(1, -30, 0, height)
	track.Position = UDim2.new(0, 30, 0, y)
	track.Parent = vitals
	UIKit.corner(track, height // 2)
	UIKit.stroke(track, 2.5)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = colorB
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Parent = track
	UIKit.corner(fill, height // 2)
	UIKit.vgradient(fill, colorA, colorB)

	local ic = UIKit.label(vitals, icon, height + 4)
	ic.Size = UDim2.fromOffset(26, height + 6)
	ic.Position = UDim2.new(0, 0, 0, y - 3)

	return fill
end

local healthFill = makeBar("Health", "❤️", Color3.fromRGB(158, 232, 112), Color3.fromRGB(63, 164, 30), 0, 16)
local dashFill = makeBar("Dash", "💨", T.BLUE_A, T.BLUE_B, 24, 11)

local function bindCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then return end
	local lastHealth = hum.Health
	local function update()
		local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		TweenService:Create(healthFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
		if hum.Health < lastHealth then
			-- damage flash
			healthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TweenService:Create(healthFill, TweenInfo.new(0.35), { BackgroundColor3 = Color3.fromRGB(63, 164, 30) }):Play()
		end
		lastHealth = hum.Health
	end
	hum.HealthChanged:Connect(update)
	update()
end
player.CharacterAdded:Connect(bindCharacter)
if player.Character then bindCharacter(player.Character) end

-- Dash bar driven by attributes maintained by the Dash script
RunService.Heartbeat:Connect(function()
	local readyAt = player:GetAttribute("DashReadyAt")
	local cd = player:GetAttribute("DashCooldown")
	if typeof(readyAt) ~= "number" or typeof(cd) ~= "number" or cd <= 0 then
		dashFill.Size = UDim2.new(1, 0, 1, 0)
		return
	end
	local left = readyAt - os.clock()
	local ratio = math.clamp(1 - (left / cd), 0, 1)
	dashFill.Size = UDim2.new(ratio, 0, 1, 0)
end)

--========================================================
-- MOBILE CONTROLS: dash + gauntlet ability buttons
--========================================================
if isTouch then
	local touchHolder = Instance.new("Frame")
	touchHolder.Name = "TouchControls"
	touchHolder.BackgroundTransparency = 1
	touchHolder.AnchorPoint = Vector2.new(1, 1)
	touchHolder.Position = UDim2.new(1, -18, 1, -95)
	touchHolder.Size = UDim2.fromOffset(170, 80)
	touchHolder.Parent = gui

	local function roundButton(text: string, colorA: Color3, colorB: Color3, x: number): TextButton
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(74, 74)
		b.Position = UDim2.fromOffset(x, 0)
		b.BackgroundColor3 = colorB
		b.Text = ""
		b.AutoButtonColor = false
		b.Parent = touchHolder
		UIKit.corner(b, 37)
		UIKit.stroke(b, T.OUTLINE)
		UIKit.vgradient(b, colorA, colorB)
		UIKit.gloss(b)
		local l = UIKit.label(b, text, 15)
		l.Size = UDim2.new(1, 0, 1, 0)
		l.TextWrapped = true
		UIKit.textStroke(l, 2)
		UIKit.bindButtonFX(b, true)
		return b
	end

	local dashBtn = roundButton("💨\nDASH", Color3.fromRGB(158, 232, 112), Color3.fromRGB(63, 164, 30), 0)
	dashBtn.MouseButton1Click:Connect(function()
		(UIBus.MobileDash :: BindableEvent):Fire()
	end)

	local abilityBtn = roundButton("🧤\nPOWER", T.PURPLE_A, T.PURPLE_B, 92)
	abilityBtn.Name = "MobileAbility"
	abilityBtn.MouseButton1Click:Connect(function()
		(UIBus.MobileAbility :: BindableEvent):Fire()
	end)

	-- grey the ability button out when no gauntlet ability is available
	task.spawn(function()
		while true do
			local usable = player:GetAttribute("AbilityUsable") == true
			abilityBtn.BackgroundTransparency = usable and 0 or 0.35
			local lbl = abilityBtn:FindFirstChildOfClass("TextLabel")
			if lbl then lbl.TextTransparency = usable and 0 or 0.4 end
			task.wait(0.25)
		end
	end)
end

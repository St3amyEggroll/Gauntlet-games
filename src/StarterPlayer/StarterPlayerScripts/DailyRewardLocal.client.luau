--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClaimRewardEvent = ReplicatedStorage:WaitForChild("ClaimDailyReward")
local GetRewardStatus = ReplicatedStorage:WaitForChild("GetDailyRewardStatus")
local UITheme = require(ReplicatedStorage:WaitForChild("UITheme"))
local THEME = UITheme.THEME
THEME.BG = THEME.BG
THEME.SURFACE = THEME.SURFACE
THEME.BORDER = THEME.CYAN
THEME.ACCENT = THEME.YELLOW
THEME.COIN = THEME.GOLD
THEME.DARK_TEXT = THEME.TEXT_DIM

local function formatTime(seconds: number)
	local hours = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d:%02d", hours, mins, secs)
end

local function buildDailyRewardUI()
	local status = GetRewardStatus:InvokeServer()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DailyRewardUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 1000
	screenGui.Parent = playerGui

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Parent = screenGui

	-- UI expanded to 400x320 for better fit
	local main = UITheme.createPanel("DailyRewardPanel", UDim2.fromOffset(400, 320), THEME.MAGENTA)
	main.Position = UDim2.fromScale(0.5, 0.5)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.ClipsDescendants = true
	main.Parent = screenGui
	UITheme.createTabHeader(main, "REWARDS", 140)

	local closeBtn = UITheme.createCloseButton(main, nil)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Font = THEME.FONT
	title.Text = "DAILY REWARDS"
	title.TextColor3 = THEME.WHITE
	title.TextSize = 22
	title.Position = UDim2.fromOffset(0, 15)
	title.Parent = main
	UITheme.outline(title, 3)
	UITheme.textGradient(title, THEME.YELLOW_TITLE)

	-- Horizontal Grid Container for Days 1-5
	local daysContainer = Instance.new("Frame")
	daysContainer.Size = UDim2.new(1, -30, 0, 100)
	daysContainer.Position = UDim2.new(0.5, 0, 0, 70)
	daysContainer.AnchorPoint = Vector2.new(0.5, 0)
	daysContainer.BackgroundTransparency = 1
	daysContainer.Parent = main

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = daysContainer

	-- Generating the 5 individual cards
	for day = 1, 5 do
		local dayFrame = Instance.new("Frame")
		dayFrame.Size = UDim2.fromOffset(64, 90)
		dayFrame.Parent = daysContainer

		UITheme.styleCard(dayFrame, THEME.CYAN, THEME.SURFACE)
		local dayStroke = dayFrame:FindFirstChild("MainStroke")

		local dayTitle = Instance.new("TextLabel")
		dayTitle.Size = UDim2.new(1, 0, 0, 20)
		dayTitle.BackgroundTransparency = 1
		dayTitle.Font = THEME.FONT
		dayTitle.Text = "DAY " .. day
		dayTitle.TextSize = 12
		dayTitle.Parent = dayFrame

		local miniCoin = Instance.new("ImageLabel")
		miniCoin.Size = UDim2.fromOffset(28, 28)
		miniCoin.Position = UDim2.new(0.5, 0, 0, 30)
		miniCoin.AnchorPoint = Vector2.new(0.5, 0)
		miniCoin.BackgroundTransparency = 1
		miniCoin.Image = "rbxassetid://84697600263846"
		miniCoin.ImageColor3 = THEME.COIN
		miniCoin.Parent = dayFrame

		local dayAmount = Instance.new("TextLabel")
		dayAmount.Size = UDim2.new(1, 0, 0, 20)
		dayAmount.Position = UDim2.new(0, 0, 1, -20)
		dayAmount.BackgroundTransparency = 1
		dayAmount.Font = THEME.FONT
		dayAmount.Text = "+" .. (day * 5)
		dayAmount.TextSize = 14
		dayAmount.Parent = dayFrame

		-- Dynamic Visual States Based on Progress
		if day < status.CurrentDay then
			-- Completed Past Days
			dayFrame.BackgroundColor3 = THEME.SURFACE
			dayStroke.Color = THEME.DARK_TEXT
			dayTitle.TextColor3 = THEME.DARK_TEXT
			dayAmount.TextColor3 = THEME.DARK_TEXT
			miniCoin.ImageColor3 = THEME.DARK_TEXT

			local checkmark = Instance.new("TextLabel")
			checkmark.Size = UDim2.fromScale(1, 1)
			checkmark.BackgroundTransparency = 1
			checkmark.Font = THEME.FONT
			checkmark.Text = "✓"
			checkmark.TextColor3 = THEME.BORDER
			checkmark.TextSize = 28
			checkmark.Parent = dayFrame
		elseif day == status.CurrentDay then
			-- Active/Target Day
			if status.CanClaim then
				dayFrame.BackgroundColor3 = THEME.BORDER
				dayStroke.Color = THEME.WHITE
				dayTitle.TextColor3 = THEME.BG
				dayAmount.TextColor3 = THEME.BG
				miniCoin.ImageColor3 = THEME.BG
			else
				dayFrame.BackgroundColor3 = THEME.SURFACE
				dayStroke.Color = THEME.ACCENT
				dayTitle.TextColor3 = THEME.WHITE
				dayAmount.TextColor3 = THEME.ACCENT
			end
		else
			-- Future Locked Days
			dayFrame.BackgroundColor3 = THEME.SURFACE
			dayStroke.Color = THEME.SURFACE
			dayTitle.TextColor3 = THEME.WHITE
			dayAmount.TextColor3 = THEME.WHITE
			dayFrame.BackgroundTransparency = 0.4
		end
	end

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(1, 0, 0, 25)
	timerLabel.Position = UDim2.fromOffset(0, 190)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Font = THEME.FONT_BOLD
	timerLabel.Text = status.CanClaim and "YOUR REWARD IS READY!" or "NEXT REWARD IN: " .. formatTime(status.TimeLeft)
	timerLabel.TextColor3 = status.CanClaim and THEME.BORDER or THEME.WHITE
	timerLabel.TextSize = 12
	timerLabel.Parent = main

	local claimBtn = UITheme.createActionButton(status.CanClaim and "CLAIM NOW" or "IN PROGRESS", 200, 44, status.CanClaim and THEME.LIME or THEME.SURFACE)
	claimBtn.Position = UDim2.new(0.5, 0, 1, -25)
	claimBtn.AnchorPoint = Vector2.new(0.5, 1)
	claimBtn.AutoButtonColor = false
	claimBtn.Parent = main

	main.Size = UDim2.fromOffset(0, 0)
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.6}):Play()
	TweenService:Create(main, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(400, 320)}):Play()

	local function close()
		local t = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0)})
		TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		t:Play()
		t.Completed:Connect(function() screenGui:Destroy() end)
	end

	closeBtn.MouseButton1Click:Connect(close)

	if status.CanClaim then
		claimBtn.MouseButton1Click:Connect(function()
			ClaimRewardEvent:FireServer()
			claimBtn.Active = false
			claimBtn.Text = "CLAIMED!"
			claimBtn.BackgroundColor3 = THEME.SURFACE
			claimBtn.TextColor3 = THEME.WHITE
			task.wait(1)
			close()
		end)

		task.spawn(function()
			while claimBtn.Parent do
				TweenService:Create(claimBtn, TweenInfo.new(0.5), {Size = UDim2.fromOffset(250, 54)}):Play()
				task.wait(0.5)
				TweenService:Create(claimBtn, TweenInfo.new(0.5), {Size = UDim2.fromOffset(240, 50)}):Play()
				task.wait(0.5)
			end
		end)
	end

	if not status.CanClaim then
		task.spawn(function()
			local remaining = status.TimeLeft
			while remaining > 0 and timerLabel.Parent do
				task.wait(1)
				remaining = remaining - 1
				timerLabel.Text = "NEXT REWARD IN: " .. formatTime(remaining)
			end
			if timerLabel.Parent then
				timerLabel.Text = "YOUR REWARD IS READY!"
				timerLabel.TextColor3 = THEME.BORDER
				claimBtn.BackgroundColor3 = THEME.BORDER
				claimBtn.TextColor3 = THEME.BG
				claimBtn.Text = "CLAIM NOW"
			end
		end)
	end
end

local function checkDailyReward()
	local status = GetRewardStatus:InvokeServer()
	if status.CanClaim then
		buildDailyRewardUI()
	end
end

_G.ShowDailyRewardUI = buildDailyRewardUI

task.wait(5)
checkDailyReward()
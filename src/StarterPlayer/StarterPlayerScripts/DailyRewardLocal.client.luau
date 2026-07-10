--!strict
-- DailyRewardLocal — 5-day streak calendar in the shared style. The HUD's
-- Daily button reads the "DailyReadyAt" attribute this script maintains.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")
local ClaimRewardEvent = ReplicatedStorage:WaitForChild("ClaimDailyReward") :: RemoteEvent
local GetRewardStatus = ReplicatedStorage:WaitForChild("GetDailyRewardStatus") :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "DailyRewardUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 105
gui.Parent = playerGui
UIKit.autoScale(gui)

local panel = UIKit.panel("DailyPanel", UDim2.fromOffset(560, 340))
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Visible = false
panel.Parent = gui

local _, closeBtn = UIKit.header(panel, "DAILY REWARDS")

local subtitle = UIKit.label(panel, "Come back every day to keep your streak — miss a day and it resets!", 14, T.FONT_BOLD)
subtitle.Size = UDim2.new(1, -30, 0, 20)
subtitle.Position = UDim2.new(0, 15, 0, 58)
subtitle.TextColor3 = T.TEXT_DIM

local daysRow = Instance.new("Frame")
daysRow.BackgroundTransparency = 1
daysRow.Size = UDim2.new(1, -28, 0, 130)
daysRow.Position = UDim2.new(0, 14, 0, 88)
daysRow.Parent = panel

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.Padding = UDim.new(0, 10)
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent = daysRow

type DayCard = { card: Frame, glow: UIStroke, checkLbl: TextLabel }
local dayCards: { DayCard } = {}

for day, coins in ipairs(GameConfig.DailyRewards) do
	local card = UIKit.card("Day" .. day, daysRow)
	card.Size = UDim2.fromOffset(94, 126)
	card.LayoutOrder = day

	local dayLbl = UIKit.label(card, "DAY " .. day, 14)
	dayLbl.Size = UDim2.new(1, 0, 0, 20)
	dayLbl.Position = UDim2.new(0, 0, 0, 8)
	UIKit.textStroke(dayLbl, 2)

	local icon = UIKit.label(card, "🪙", 30)
	icon.Size = UDim2.new(1, 0, 0, 40)
	icon.Position = UDim2.new(0, 0, 0, 30)

	local amount = UIKit.label(card, "+" .. coins, 18)
	amount.Size = UDim2.new(1, 0, 0, 24)
	amount.Position = UDim2.new(0, 0, 0, 70)
	amount.TextColor3 = T.GOLD
	UIKit.textStroke(amount, 2)

	local checkLbl = UIKit.label(card, "", 13, T.FONT_BOLD)
	checkLbl.Size = UDim2.new(1, 0, 0, 18)
	checkLbl.Position = UDim2.new(0, 0, 1, -24)
	checkLbl.TextColor3 = T.TEXT_DIM

	local glow = card:FindFirstChild("KitStroke") :: UIStroke
	table.insert(dayCards, { card = card, glow = glow, checkLbl = checkLbl })
end

local claimBtn = UIKit.button("CLAIM", "lime", panel)
claimBtn.Size = UDim2.fromOffset(240, 46)
claimBtn.AnchorPoint = Vector2.new(0.5, 1)
claimBtn.Position = UDim2.new(0.5, 0, 1, -14)

local currentStatus: any = nil

local function paintStatus(status: any)
	currentStatus = status
	player:SetAttribute("DailyReadyAt", os.time() + (status.CanClaim and 0 or status.TimeLeft))

	for day, entry in ipairs(dayCards) do
		local isCurrent = (day == status.CurrentDay)
		entry.glow.Color = isCurrent and T.GOLD or T.STROKE
		entry.glow.Thickness = isCurrent and 4 or T.OUTLINE
		if day < status.CurrentDay then
			entry.checkLbl.Text = "✓ DONE"
			entry.checkLbl.TextColor3 = T.GREEN
		elseif isCurrent then
			entry.checkLbl.Text = status.CanClaim and "READY!" or "NEXT"
			entry.checkLbl.TextColor3 = status.CanClaim and T.GREEN or T.GOLD
		else
			entry.checkLbl.Text = "LOCKED"
			entry.checkLbl.TextColor3 = T.TEXT_DIM
		end
	end

	local grad = claimBtn:FindFirstChildOfClass("UIGradient")
	if status.CanClaim then
		claimBtn.Text = ("CLAIM +%d COINS!"):format(status.RewardAmount)
		claimBtn.TextColor3 = Color3.fromRGB(20, 62, 0)
		if grad then
			grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, T.LIME_A), ColorSequenceKeypoint.new(1, T.LIME_B) })
		end
	else
		claimBtn.TextColor3 = T.WHITE
		if grad then
			grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, T.GREY_A), ColorSequenceKeypoint.new(1, T.GREY_B) })
		end
	end
end

local function refreshStatus()
	local ok, status = pcall(function()
		return GetRewardStatus:InvokeServer()
	end)
	if ok and typeof(status) == "table" then
		paintStatus(status)
	end
end

-- live countdown text on the claim button
task.spawn(function()
	while true do
		if currentStatus and not currentStatus.CanClaim then
			local readyAt = player:GetAttribute("DailyReadyAt")
			local left = typeof(readyAt) == "number" and readyAt - os.time() or 0
			if left <= 0 then
				refreshStatus()
			else
				claimBtn.Text = "NEXT REWARD IN " .. UIKit.formatTime(left)
			end
		end
		task.wait(1)
	end
end)

claimBtn.MouseButton1Click:Connect(function()
	if not currentStatus or not currentStatus.CanClaim then
		UIKit.play("Error")
		return
	end
	ClaimRewardEvent:FireServer()
	UIKit.play("Reward")
	UIKit.notify(("Day %d reward claimed: +%d coins!"):format(currentStatus.CurrentDay, currentStatus.RewardAmount), T.GOLD, "📅")

	-- celebrate the claimed card
	local entry = dayCards[currentStatus.CurrentDay]
	if entry then
		local s = Instance.new("UIScale")
		s.Parent = entry.card
		TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.12 }):Play()
		task.delay(0.35, function()
			TweenService:Create(s, TweenInfo.new(0.2), { Scale = 1 }):Play()
		end)
	end
	task.delay(0.5, refreshStatus)
end)

--========================================================
-- OPEN / CLOSE
--========================================================
local isOpen = false
local function close()
	if not isOpen then return end
	isOpen = false
	UIKit.popClose(panel)
end
local function open()
	UIKit.closeOthers("Daily")
	isOpen = true
	UIKit.popOpen(panel)
	task.spawn(refreshStatus)
end
UIKit.registerExclusive("Daily", close)
closeBtn.MouseButton1Click:Connect(close)

;(UIBus:WaitForChild("OpenDaily") :: BindableEvent).Event:Connect(function()
	if isOpen then close() else open() end
end)

-- initial fetch so the HUD countdown works before the menu is ever opened
task.spawn(refreshStatus)

--!strict
-- QuestsLocal — daily quest board with progress bars and claim buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")
local QuestSync = ReplicatedStorage:WaitForChild("QuestSync") :: RemoteFunction
local QuestClaim = ReplicatedStorage:WaitForChild("QuestClaim") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "QuestsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 105
gui.Parent = playerGui
UIKit.autoScale(gui)

local panel = UIKit.panel("QuestsPanel", UDim2.fromOffset(520, 460))
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Visible = false
panel.Parent = gui

local _, closeBtn = UIKit.header(panel, "DAILY QUESTS")

local subtitle = UIKit.label(panel, "Quests reset every day. Finish them for bonus coins!", 14, T.FONT_BOLD)
subtitle.Size = UDim2.new(1, -30, 0, 20)
subtitle.Position = UDim2.new(0, 15, 0, 58)
subtitle.TextColor3 = T.TEXT_DIM

local scroll = Instance.new("ScrollingFrame")
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Size = UDim2.new(1, -28, 1, -96)
scroll.Position = UDim2.new(0, 14, 0, 84)
scroll.ScrollBarThickness = 5
scroll.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 10)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 12)
end)

type Row = {
	fill: Frame,
	progressLabel: TextLabel,
	claimBtn: TextButton,
	check: TextLabel,
}
local rows: { [string]: Row } = {}
local refresh: () -> ()

for i, quest in ipairs(GameConfig.Quests) do
	local card = UIKit.card(quest.Key, scroll)
	card.Size = UDim2.new(1, -8, 0, 76)
	card.LayoutOrder = i

	local icon = UIKit.label(card, quest.Icon, 26)
	icon.Size = UDim2.fromOffset(40, 40)
	icon.Position = UDim2.new(0, 10, 0, 8)

	local name = UIKit.label(card, quest.Name, 16)
	name.Size = UDim2.new(0.5, -60, 0, 20)
	name.Position = UDim2.new(0, 56, 0, 8)
	name.TextXAlignment = Enum.TextXAlignment.Left
	UIKit.textStroke(name, 2)

	local desc = UIKit.label(card, quest.Desc, 12, T.FONT_MED)
	desc.Size = UDim2.new(0.5, -60, 0, 16)
	desc.Position = UDim2.new(0, 56, 0, 28)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextColor3 = T.TEXT_DIM

	-- progress bar
	local track = Instance.new("Frame")
	track.BackgroundColor3 = Color3.fromRGB(12, 14, 34)
	track.BorderSizePixel = 0
	track.Size = UDim2.new(0.52, 0, 0, 12)
	track.Position = UDim2.new(0, 56, 1, -22)
	track.Parent = card
	UIKit.corner(track, 6)
	UIKit.stroke(track, 2)

	local fill = Instance.new("Frame")
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = T.BLUE_B
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.Parent = track
	UIKit.corner(fill, 6)
	UIKit.vgradient(fill, T.BLUE_A, T.BLUE_B)

	local progressLabel = UIKit.label(card, "0/" .. quest.Goal, 12, T.FONT_BOLD)
	progressLabel.Size = UDim2.fromOffset(70, 14)
	progressLabel.Position = UDim2.new(0.52, 64, 1, -23)
	progressLabel.TextXAlignment = Enum.TextXAlignment.Left
	progressLabel.TextColor3 = T.TEXT_DIM

	local claimBtn = UIKit.button("🪙 " .. quest.Reward, "gold", card)
	claimBtn.Size = UDim2.fromOffset(104, 36)
	claimBtn.AnchorPoint = Vector2.new(1, 0)
	claimBtn.Position = UDim2.new(1, -10, 0, 10)
	claimBtn.TextSize = 15

	local check = UIKit.label(card, "CLAIMED ✓", 14)
	check.AnchorPoint = Vector2.new(1, 0)
	check.Position = UDim2.new(1, -14, 0, 18)
	check.Size = UDim2.fromOffset(110, 20)
	check.TextColor3 = T.GREEN
	check.Visible = false
	UIKit.textStroke(check, 2)

	claimBtn.MouseButton1Click:Connect(function()
		if claimBtn.Text ~= "CLAIM!" then
			UIKit.play("Error")
			return
		end
		QuestClaim:FireServer(quest.Key)
		UIKit.play("Reward")
		UIKit.notify(("Quest complete! +%d coins for %s"):format(quest.Reward, quest.Name), T.GOLD, quest.Icon)
		task.delay(0.4, function()
			refresh()
		end)
	end)

	rows[quest.Key] = { fill = fill, progressLabel = progressLabel, claimBtn = claimBtn, check = check }
end

refresh = function()
	local ok, snapshot = pcall(function()
		return QuestSync:InvokeServer()
	end)
	if not ok or typeof(snapshot) ~= "table" or not snapshot.ready then return end

	for _, q in ipairs(snapshot.quests) do
		local row = rows[q.Key]
		local questDef = nil
		for _, def in ipairs(GameConfig.Quests) do
			if def.Key == q.Key then questDef = def break end
		end
		if row and questDef then
			local ratio = math.clamp(q.Progress / questDef.Goal, 0, 1)
			TweenService:Create(row.fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
			row.progressLabel.Text = q.Progress .. "/" .. questDef.Goal
			if q.Claimed then
				row.claimBtn.Visible = false
				row.check.Visible = true
			elseif q.Done then
				row.claimBtn.Visible = true
				row.claimBtn.Text = "CLAIM!"
				row.check.Visible = false
			else
				row.claimBtn.Visible = true
				row.claimBtn.Text = "🪙 " .. questDef.Reward
				row.check.Visible = false
			end
		end
	end
end

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
	UIKit.closeOthers("Quests")
	isOpen = true
	UIKit.popOpen(panel)
	task.spawn(refresh)
end
UIKit.registerExclusive("Quests", close)
closeBtn.MouseButton1Click:Connect(close)

;(UIBus:WaitForChild("OpenQuests") :: BindableEvent).Event:Connect(function()
	if isOpen then close() else open() end
end)

-- keep progress fresh while open
task.spawn(function()
	while true do
		task.wait(5)
		if isOpen then
			refresh()
		end
	end
end)

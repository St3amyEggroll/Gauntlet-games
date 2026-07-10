--!strict
-- MapVoteLocal — map voting panel (replaces the old "Water" script's UI).
-- Same remotes: StartMapVote(mapNames, duration), SubmitMapVote(index),
-- UpdateMapVotes(votes). Can be reopened from the HUD while a vote runs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")

local StartMapVote = ReplicatedStorage:WaitForChild("StartMapVote") :: RemoteEvent
local SubmitMapVote = ReplicatedStorage:WaitForChild("SubmitMapVote") :: RemoteEvent
local UpdateMapVotes = ReplicatedStorage:WaitForChild("UpdateMapVotes") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "MapVoteUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 90
gui.Parent = playerGui
UIKit.autoScale(gui)

local panel = UIKit.panel("MapVotePanel", UDim2.fromOffset(560, 300))
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 84)
panel.Visible = false
panel.Parent = gui

local _, closeBtn = UIKit.header(panel, "VOTE FOR A MAP")

local timerLbl = UIKit.label(panel, "", 22)
timerLbl.AnchorPoint = Vector2.new(1, 0.5)
timerLbl.Position = UDim2.new(1, -60, 0, 26)
timerLbl.Size = UDim2.fromOffset(70, 30)
timerLbl.TextColor3 = T.GOLD
timerLbl.TextXAlignment = Enum.TextXAlignment.Right
timerLbl.ZIndex = 6
UIKit.textStroke(timerLbl, 2.5)

local cardsRow = Instance.new("Frame")
cardsRow.BackgroundTransparency = 1
cardsRow.Size = UDim2.new(1, -28, 1, -80)
cardsRow.Position = UDim2.new(0, 14, 0, 66)
cardsRow.Parent = panel

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.Padding = UDim.new(0, 12)
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent = cardsRow

local MAP_EMOJI: { [string]: string } = {}
local mapCards: { { frame: Frame, votesLbl: TextLabel, stroke: UIStroke } } = {}
local voteActive = false
local votedIndex: number? = nil

local reopenBtn: TextButton? = nil
task.spawn(function()
	local hud = playerGui:WaitForChild("MainHUD", 15)
	if hud then
		reopenBtn = hud:FindFirstChild("MapVoteReopen", true) :: TextButton?
	end
end)

local function clearCards()
	for _, entry in ipairs(mapCards) do
		entry.frame:Destroy()
	end
	mapCards = {}
end

local function buildCards(mapNames: { string })
	clearCards()
	for i, name in ipairs(mapNames) do
		local card = UIKit.card("Map" .. i, cardsRow)
		card.Size = UDim2.fromOffset(160, 176)
		card.LayoutOrder = i

		local icon = UIKit.label(card, MAP_EMOJI[name] or "🗺️", 40)
		icon.Size = UDim2.new(1, 0, 0, 54)
		icon.Position = UDim2.new(0, 0, 0, 10)

		local nameLbl = UIKit.label(card, name, 15)
		nameLbl.Size = UDim2.new(1, -10, 0, 22)
		nameLbl.Position = UDim2.new(0, 5, 0, 66)
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		UIKit.textStroke(nameLbl, 2)

		local votesLbl = UIKit.label(card, "0 votes", 13, T.FONT_BOLD)
		votesLbl.Size = UDim2.new(1, 0, 0, 18)
		votesLbl.Position = UDim2.new(0, 0, 0, 90)
		votesLbl.TextColor3 = T.TEXT_DIM

		local voteBtn = UIKit.button("VOTE", "blue", card)
		voteBtn.Size = UDim2.new(1, -20, 0, 34)
		voteBtn.Position = UDim2.new(0, 10, 1, -44)
		voteBtn.TextSize = 15

		local stroke = card:FindFirstChild("KitStroke") :: UIStroke

		voteBtn.MouseButton1Click:Connect(function()
			votedIndex = i
			SubmitMapVote:FireServer(i)
			for j, entry in ipairs(mapCards) do
				entry.stroke.Color = (j == i) and T.GOLD or T.STROKE
				entry.stroke.Thickness = (j == i) and 4 or T.OUTLINE
			end
		end)

		table.insert(mapCards, { frame = card, votesLbl = votesLbl, stroke = stroke })
	end
end

local function setReopenVisible(visible: boolean)
	if reopenBtn then
		reopenBtn.Visible = visible
	end
end

StartMapVote.OnClientEvent:Connect(function(mapNames: { string }, duration: number)
	buildCards(mapNames)
	votedIndex = nil
	voteActive = true
	setReopenVisible(true)
	UIKit.popOpen(panel)

	task.spawn(function()
		local remaining = duration or 10
		while remaining > 0 and voteActive do
			timerLbl.Text = remaining .. "s"
			timerLbl.TextColor3 = remaining <= 3 and T.RED or T.GOLD
			task.wait(1)
			remaining -= 1
		end
		voteActive = false
		setReopenVisible(false)
		if panel.Visible then
			UIKit.popClose(panel)
		end
	end)
end)

UpdateMapVotes.OnClientEvent:Connect(function(votes: { [any]: number })
	local counts: { [number]: number } = {}
	for _, idx in pairs(votes) do
		counts[idx] = (counts[idx] or 0) + 1
	end
	for i, entry in ipairs(mapCards) do
		local n = counts[i] or 0
		entry.votesLbl.Text = n .. (n == 1 and " vote" or " votes")
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	UIKit.popClose(panel)
end)

-- HUD reopen button (only useful while a vote is still running)
;(UIBus:WaitForChild("OpenMapVote") :: BindableEvent).Event:Connect(function()
	if voteActive and not panel.Visible then
		UIKit.popOpen(panel)
	elseif panel.Visible then
		UIKit.popClose(panel)
	else
		UIKit.notify("There's no map vote right now — it opens before each round!", T.HEADER_B, "🗺️", 3)
	end
end)

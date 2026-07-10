--!strict
-- InventorySystemLocal — round-start gauntlet selection + reopenable
-- inventory, rebuilt on UIKit. Same remotes as before:
-- OpenGauntletSelection(seconds), SelectGauntlet(name), GetOwnedTools, Regen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")

local selectGauntletEvent = ReplicatedStorage:WaitForChild("SelectGauntlet") :: RemoteEvent
local openSelectionEvent = ReplicatedStorage:WaitForChild("OpenGauntletSelection") :: RemoteEvent
local getOwnedTools = ReplicatedStorage:WaitForChild("GetOwnedTools") :: RemoteFunction

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 120
gui.Parent = playerGui
UIKit.autoScale(gui)

local panel = UIKit.panel("InventoryPanel", UDim2.fromOffset(620, 420))
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Visible = false
panel.Parent = gui

local _, closeBtn = UIKit.header(panel, "YOUR GAUNTLETS")

local countdownLbl = UIKit.label(panel, "", 26)
countdownLbl.AnchorPoint = Vector2.new(1, 0.5)
countdownLbl.Position = UDim2.new(1, -60, 0, 26)
countdownLbl.Size = UDim2.fromOffset(90, 34)
countdownLbl.TextColor3 = T.GOLD
countdownLbl.TextXAlignment = Enum.TextXAlignment.Right
countdownLbl.ZIndex = 6
UIKit.textStroke(countdownLbl, 2.5)

local scroll = Instance.new("ScrollingFrame")
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Size = UDim2.new(1, -28, 1, -130)
scroll.Position = UDim2.new(0, 14, 0, 64)
scroll.ScrollBarThickness = 5
scroll.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(108, 118)
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingLeft = UDim.new(0, 4)
pad.Parent = scroll

grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 12)
end)

local footer = UIKit.label(panel, "Pick the gauntlet you want to fight with!", 15, T.FONT_BOLD)
footer.Size = UDim2.new(0.6, 0, 0, 40)
footer.Position = UDim2.new(0, 16, 1, -54)
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.TextColor3 = T.TEXT_DIM

local confirmBtn = UIKit.button("SELECT", "lime", panel)
confirmBtn.Size = UDim2.fromOffset(180, 44)
confirmBtn.AnchorPoint = Vector2.new(1, 1)
confirmBtn.Position = UDim2.new(1, -16, 1, -12)
confirmBtn.Visible = false

local owned: { string } = {}
local selectedName: string? = nil
local strokes: { [string]: UIStroke } = {}

local function updateOwned()
	local ok, result = pcall(function()
		return getOwnedTools:InvokeServer()
	end)
	owned = (ok and typeof(result) == "table") and result or {}
	if not table.find(owned, "Starter Gauntlet") then
		table.insert(owned, 1, "Starter Gauntlet")
	end
end

local function rebuildGrid()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	strokes = {}

	for i, name in ipairs(owned) do
		local info = GameConfig.Gauntlets[name]
		local card = UIKit.card(name, scroll)
		card.LayoutOrder = info and (UIKit.RarityOrder[info.Rarity] or 1) or 0

		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.fromOffset(54, 54)
		icon.Position = UDim2.new(0.5, -27, 0, 8)
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Image = info and info.Icon or GameConfig.FallbackIcon
		icon.Parent = card

		local lbl = UIKit.label(card, (name:gsub(" Gauntlet", "")), 13)
		lbl.Size = UDim2.new(1, -6, 0, 18)
		lbl.Position = UDim2.new(0, 3, 0, 66)
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		UIKit.textStroke(lbl, 2)

		local rarity = UIKit.label(card, info and string.upper(info.Rarity) or "STARTER", 10, T.FONT_BOLD)
		rarity.Size = UDim2.new(1, 0, 0, 14)
		rarity.Position = UDim2.new(0, 0, 0, 86)
		rarity.TextColor3 = info and (UIKit.Rarity[info.Rarity] or T.TEXT_DIM) or T.TEXT_DIM

		strokes[name] = card:FindFirstChild("KitStroke") :: UIStroke

		local hit = Instance.new("TextButton")
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.Size = UDim2.fromScale(1, 1)
		hit.Parent = card
		UIKit.bindButtonFX(hit, true)
		hit.MouseButton1Click:Connect(function()
			UIKit.play("Click")
			selectedName = name
			for n, s in pairs(strokes) do
				s.Color = (n == name) and T.GOLD or T.STROKE
				s.Thickness = (n == name) and 4 or T.OUTLINE
			end
			confirmBtn.Visible = true
			confirmBtn.Text = "SELECT " .. string.upper(name:gsub(" Gauntlet", ""))
		end)
	end
end

local isOpen = false
local selectionMode = false

local function close()
	if not isOpen then return end
	isOpen = false
	UIKit.popClose(panel)
end

local function open(selection: boolean)
	UIKit.closeOthers("Inventory")
	isOpen = true
	selectionMode = selection
	countdownLbl.Text = ""
	footer.Text = selection and "Pick the gauntlet you want to fight with!" or "Everything you own. Buy more in the shop!"
	task.spawn(function()
		updateOwned()
		rebuildGrid()
	end)
	UIKit.popOpen(panel)
end

UIKit.registerExclusive("Inventory", close)
closeBtn.MouseButton1Click:Connect(close)

confirmBtn.MouseButton1Click:Connect(function()
	if not selectedName then return end
	selectGauntletEvent:FireServer(selectedName)
	UIKit.notify("Selected " .. (selectedName :: string) .. "!", T.HEADER_A, "🧤")
	close()
end)

-- Round-start selection window (server-driven, with countdown)
openSelectionEvent.OnClientEvent:Connect(function(seconds: number)
	open(true)
	task.spawn(function()
		local remaining = seconds or 10
		while remaining > 0 and isOpen do
			countdownLbl.Text = remaining .. "s"
			countdownLbl.TextColor3 = remaining <= 3 and T.RED or T.GOLD
			task.wait(1)
			remaining -= 1
		end
		if isOpen and selectionMode then
			close()
		end
	end)
end)

-- HUD reopen button
;(UIBus:WaitForChild("OpenInventory") :: BindableEvent).Event:Connect(function()
	if isOpen then close() else open(false) end
end)

-- Regen effect from the old script: respawn shield flash (kept minimal)
local regen = ReplicatedStorage:WaitForChild("Regen") :: RemoteEvent
regen.OnClientEvent:Connect(function()
	UIKit.notify("You've been regenerated!", T.GREEN, "✨", 2)
end)

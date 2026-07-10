--!strict

--====================================================
-- SERVICES
--====================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PurchaseEvent = ReplicatedStorage:WaitForChild("PurchaseToolEvent")
local GetOwnedTools = ReplicatedStorage:WaitForChild("GetOwnedTools")
local GauntletsFolder = ReplicatedStorage:WaitForChild("Gauntlets")

--====================================================
-- THEME & DESIGN CONFIGURATION
--====================================================
local Theme = {
	Background = Color3.fromRGB(20, 15, 25),
	Surface = Color3.fromRGB(35, 28, 45),
	SurfaceLight = Color3.fromRGB(55, 45, 65),

	Orange = Color3.fromRGB(180, 80, 255), -- Purple
	Purple = Color3.fromRGB(180, 80, 255),
	Accent = Color3.fromRGB(255, 60, 180),
	Gold = Color3.fromRGB(255, 255, 255),

	Green = Color3.fromRGB(60, 255, 40),
	Red = Color3.fromRGB(230, 50, 50),

	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(160, 165, 180),

	Common = Color3.fromRGB(140, 145, 155),
	Rare = Color3.fromRGB(0, 160, 255),
	Epic = Color3.fromRGB(165, 50, 255),
	Legendary = Color3.fromRGB(255, 135, 0),
	Mythic = Color3.fromRGB(255, 30, 70),
}

local RarityColors = {
	Common = Theme.Common, Rare = Theme.Rare, Epic = Theme.Epic, Legendary = Theme.Legendary, Mythic = Theme.Mythic
}

local RarityOrder = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }
local FALLBACK_IMAGE = "rbxassetid://10614013444"

--====================================================
-- CENTRAL GAUNTLET CONFIGURATION
--====================================================
local GauntletConfig = {
	["Rock Gauntlet"]    = { Price = 800, Rarity = "Legendary", Icon = "rbxassetid://129278461826205", Desc = "Smash your opponents into the ground and strike a boulder to their dome (5s CD)." },
	["Water Gauntlet"]   = { Price = 300, Rarity = "Rare", Icon = "rbxassetid://97379845339532", Desc = "Slows down player and blurs screen for 3s. (5s CD)." },
	["Energy Gauntlet"]  = { Price = 100, Rarity = "Common", Icon = "rbxassetid://94440351994069", Desc = "Increases speed for 3s (5s CD)." },
	["Ice Gauntlet"]     = { Price = 300, Rarity = "Rare", Icon = "rbxassetid://77632532567521", Desc = "Freezes player for 3s (10s CD)." },
	["Space Gauntlet"]   = { Price = 100, Rarity = "Common", Icon = "rbxassetid://131107012060344", Desc = "Launches you high up into the air. (5s CD)." },
	["Emerald Gauntlet"] = { Price = 100, Rarity = "Common", Icon = "rbxassetid://132640003436639", Desc = "Heals you with every hit to an opponent." },
	["Fire Gauntlet"]    = { Price = 300, Rarity = "Rare", Icon = "rbxassetid://108789212527369", Desc = "Burn enemies over time." },
	["Nature Gauntlet"]  = { Price = 500, Rarity = "Epic", Icon = "rbxassetid://133298397460165", Desc = "Shoots out vine that pulls targets in range towards you. (8s CD)." },
	["Wind Gauntlet"]    = { Price = 1000, Rarity = "Legendary", Icon = "rbxassetid://120175668944028", Desc = " Allows you to fly for 3s. (8s CD)." },
	["Void Gauntlet"]    = { Price = 1499, Rarity = "Mythic", Icon = "rbxassetid://82173630536383", Desc = "Allows you to teleport anywhere on the map. (5s CD)." },
	["X-Ray Gauntlet"]   = { Price = 600, Rarity = "Epic", Icon = "rbxassetid://71772677262812", Desc = "Highlights all players on map and makes you go invisible for 5s (5s CD)." }, -- FIXED: Match Server Handler Naming
	["Missle Gauntlet"]  = { Price = 800, Rarity = "Legendary", Icon = "rbxassetid://101627968386615", Desc = "Shoots 3 missles at the nearest player, slightly following player. (6s CD)." },
	["Grappling Gauntlet"]={ Price = 800, Rarity = "Legendary", Icon = "rbxassetid://101627968386615", Desc = "Shoots a grappling hook to target location, pulls player to hook. (6s CD)." },
	["Full Gold Gauntlet"]={ Price = 999, Rarity = "Mythic", Icon = "rbxassetid://101627968386615", Desc = "Deals 50% damage on hit." },
	["God Gauntlet"]     = { Price = 2499, Rarity = "Mythic", Icon = "rbxassetid://124282535943612", Desc = "Ultimate reality-breaking power causing 100% damage per hit." },
}

local CoinBundles = {
	{
		Name = "100 Coins",
		Amount = 100,
		Robux = 25,
		ProductId = 3273984433,
		Image = "rbxassetid://18209599195"
	},
	{
		Name = "300 Coins",
		Amount = 300,
		Robux = 80,
		ProductId = 3605946307,
		Image = "rbxassetid://18209599044"
	},
	{
		Name = "500 Coins",
		Amount = 500,
		Robux = 100,
		ProductId = 3605946335,
		Image = "rbxassetid://18209598819"
	},
	{
		Name = "1000 Coins",
		Amount = 1000,
		Robux = 200,
		ProductId = 3605946465,
		Image = "rbxassetid://18209598650"
	},
	{
		Name = "5000 Coins",
		Amount = 5000,
		Robux = 800,
		ProductId = 3605946501,
		Image = "rbxassetid://18209598496"
	},
}

local Gamepasses = {
	["Void Gauntlet"] = 1899025219,
	["Full Gold Gauntlet"] = 1899547200,
	["God Gauntlet"] = 1899601270,
}
--====================================================
-- UI CREATION HELPERS
--====================================================
local function Corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = obj
end

local function Stroke(obj, color, thickness, mode)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(0, 0, 0)
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function Gradient(obj, colors, rotation)
	local g = Instance.new("UIGradient")
	g.Color = colors
	g.Rotation = rotation or 90
	g.Parent = obj
	return g
end

local HUD_GRADIENTS = {
	COIN = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 160, 0))
	}),
	MATCH = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))
	})
}

local Blur = Lighting:FindFirstChild("ShopBlur") or Instance.new("BlurEffect")
Blur.Name = "ShopBlur"
Blur.Size = 0
Blur.Parent = Lighting

--====================================================
-- ENGINE INITIALIZATION
--====================================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "PremiumGauntletShop"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
Gui.Parent = PlayerGui

local OpenButton = Instance.new("ImageButton")
OpenButton.Size = UDim2.fromOffset(65, 65)
OpenButton.Position = UDim2.new(0, 10, .5, -110)
OpenButton.Image = "rbxassetid://123838677183783"
OpenButton.BackgroundColor3 = Theme.Orange
OpenButton.Parent = Gui
Corner(OpenButton, 12)
local OpenStroke = Stroke(OpenButton, Theme.Gold, 2)

OpenButton.MouseEnter:Connect(function()
	TweenService:Create(OpenButton, TweenInfo.new(0.2), {Size = UDim2.fromOffset(72, 72), BackgroundColor3 = Theme.Accent}):Play()
	TweenService:Create(OpenStroke, TweenInfo.new(0.2), {Color = Theme.Text}):Play()
end)

OpenButton.MouseLeave:Connect(function()
	TweenService:Create(OpenButton, TweenInfo.new(0.2), {Size = UDim2.fromOffset(65, 65), BackgroundColor3 = Theme.Orange}):Play()
	TweenService:Create(OpenStroke, TweenInfo.new(0.2), {Color = Theme.Gold}):Play()
end)

local Main = Instance.new("Frame")
Main.Visible = false
Main.Size = UDim2.fromScale(.65, .75)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Theme.Background
Main.Parent = Gui
Corner(Main, 16)
Stroke(Main, Theme.SurfaceLight, 2)
Stroke(Main, Color3.new(0,0,0), 3)

--====================================================
-- HEADER & NAVIGATION
--====================================================
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = Theme.Surface
Header.Parent = Main
Corner(Header, 16)
Stroke(Header, Color3.new(0,0,0), 3)

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(15, 0)
Title.Size = UDim2.new(0, 180, 1, 0)
Title.Text = "SHOP"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Theme.Text
Title.Parent = Header
Stroke(Title, Color3.new(0,0,0), 2, Enum.ApplyStrokeMode.Contextual)
Gradient(Title, HUD_GRADIENTS.MATCH)

local TabGauntlets = Instance.new("TextButton")
TabGauntlets.Size = UDim2.fromOffset(100, 32)
TabGauntlets.Position = UDim2.new(0, 180, .5, -16)
TabGauntlets.BackgroundColor3 = Theme.Orange
TabGauntlets.Text = "GAUNTLETS"
TabGauntlets.TextColor3 = Theme.Text
TabGauntlets.Font = Enum.Font.GothamBold
TabGauntlets.TextSize = 13
TabGauntlets.Parent = Header
Corner(TabGauntlets, 10)
Stroke(TabGauntlets, Color3.new(0,0,0), 2)

local TabCoins = Instance.new("TextButton")
TabCoins.Size = UDim2.fromOffset(100, 32)
TabCoins.Position = UDim2.new(0, 290, .5, -16)
TabCoins.BackgroundColor3 = Theme.SurfaceLight
TabCoins.Text = "COINS"
TabCoins.TextColor3 = Theme.TextDim
TabCoins.Font = Enum.Font.GothamBold
TabCoins.TextSize = 13
TabCoins.Parent = Header
Corner(TabCoins, 10)
Stroke(TabCoins, Color3.new(0,0,0), 2)

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.fromOffset(160, 32)
SearchBox.Position = UDim2.new(1, -340, .5, -16)
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search..."
SearchBox.PlaceholderColor3 = Theme.TextDim
SearchBox.BackgroundColor3 = Theme.Background
SearchBox.TextColor3 = Theme.Text
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = Header
Corner(SearchBox, 10)
Stroke(SearchBox, Color3.new(0,0,0), 2)

--====================================================
-- VIEW REPOSITORIES
--====================================================
local Content = Instance.new("Frame")
Content.BackgroundTransparency = 1
Content.Position = UDim2.fromOffset(0, 60)
Content.Size = UDim2.new(1, 0, 1, -60)
Content.Parent = Main

local GauntletView = Instance.new("Frame")
GauntletView.Size = UDim2.fromScale(1, 1)
GauntletView.BackgroundTransparency = 1
GauntletView.Parent = Content

local CoinView = Instance.new("Frame")
CoinView.Size = UDim2.fromScale(1, 1)
CoinView.BackgroundTransparency = 1
CoinView.Visible = false
CoinView.Parent = Content

--====================================================
-- CONTAINERS (FIXED CUTOFF WITH INTERNAL PADDING)
--====================================================
local GridContainer = Instance.new("ScrollingFrame")
GridContainer.Size = UDim2.new(1, -20, 1, -60)
GridContainer.Position = UDim2.new(0, 10, 0, 50)
GridContainer.BackgroundTransparency = 1
GridContainer.BorderSizePixel = 0
GridContainer.ScrollBarThickness = 4
GridContainer.ScrollBarImageColor3 = Theme.SurfaceLight
GridContainer.Parent = GauntletView

-- UIPadding ensures strokes never clip against the top boundary of scrolling window
local GridPadding = Instance.new("UIPadding")
GridPadding.PaddingTop = UDim.new(0, 10)
GridPadding.PaddingBottom = UDim.new(0, 10)
GridPadding.PaddingLeft = UDim.new(0, 5)
GridPadding.PaddingRight = UDim.new(0, 5)
GridPadding.Parent = GridContainer

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.fromOffset(160, 220)
Grid.CellPadding = UDim2.fromOffset(10, 10)
Grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
Grid.SortOrder = Enum.SortOrder.LayoutOrder
Grid.Parent = GridContainer

local CoinGridContainer = Instance.new("ScrollingFrame")
CoinGridContainer.Size = UDim2.new(1, -20, 1, -20)
CoinGridContainer.Position = UDim2.new(0, 10, 0, 10)
CoinGridContainer.BackgroundTransparency = 1
CoinGridContainer.BorderSizePixel = 0
CoinGridContainer.ScrollBarThickness = 4
CoinGridContainer.Parent = CoinView

local CoinPadding = Instance.new("UIPadding")
CoinPadding.PaddingTop = UDim.new(0, 10)
CoinPadding.PaddingBottom = UDim.new(0, 10)
CoinPadding.Parent = CoinGridContainer

local CoinGrid = Instance.new("UIGridLayout")
CoinGrid.CellSize = UDim2.fromOffset(160, 200)
CoinGrid.CellPadding = UDim2.fromOffset(10, 10)
CoinGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
CoinGrid.Parent = CoinGridContainer

--====================================================
-- AUTOMATIC CANVAS SIZE RECALCULATOR
--====================================================
local function AdjustCanvasSize()
	GridContainer.CanvasSize = UDim2.new(0, 0, 0, Grid.AbsoluteContentSize.Y + 30)
end
Grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(AdjustCanvasSize)

local function AdjustCoinCanvasSize()
	CoinGridContainer.CanvasSize = UDim2.new(0, 0, 0, CoinGrid.AbsoluteContentSize.Y + 30)
end
CoinGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(AdjustCoinCanvasSize)

--====================================================
-- INSPECT PANEL (OFFSCREEN INITIALIZATION)
--====================================================
local InspectPanel = Instance.new("Frame")
InspectPanel.Size = UDim2.new(0, 310, 1, -30)
InspectPanel.Position = UDim2.new(1, 50, 0, 15)
InspectPanel.BackgroundColor3 = Theme.Surface
InspectPanel.Visible = false
InspectPanel.Parent = GauntletView
Corner(InspectPanel, 20)
local InspectOutline = Stroke(InspectPanel, Theme.SurfaceLight, 1)

local InspectIcon = Instance.new("ImageLabel")
InspectIcon.Size = UDim2.fromOffset(140, 140)
InspectIcon.Position = UDim2.new(.5, -70, 0, 25)
InspectIcon.BackgroundTransparency = 1
InspectIcon.ScaleType = Enum.ScaleType.Fit
InspectIcon.Parent = InspectPanel

local InspectName = Instance.new("TextLabel")
InspectName.Size = UDim2.new(1, -30, 0, 35)
InspectName.Position = UDim2.fromOffset(15, 180)
InspectName.BackgroundTransparency = 1
InspectName.TextColor3 = Theme.Text
InspectName.Font = Enum.Font.GothamBlack
InspectName.TextSize = 18
InspectName.TextTruncate = Enum.TextTruncate.AtEnd
InspectName.Parent = InspectPanel

local InspectRarity = Instance.new("TextLabel")
InspectRarity.Size = UDim2.new(1, -30, 0, 20)
InspectRarity.Position = UDim2.fromOffset(15, 215)
InspectRarity.BackgroundTransparency = 1
InspectRarity.Font = Enum.Font.GothamBlack
InspectRarity.TextSize = 13
InspectRarity.Parent = InspectPanel

local InspectPrice = Instance.new("TextLabel")
InspectPrice.Size = UDim2.new(1, -30, 0, 20)
InspectPrice.Position = UDim2.fromOffset(15, 235)
InspectPrice.BackgroundTransparency = 1
InspectPrice.TextColor3 = Theme.TextDim
InspectPrice.Font = Enum.Font.GothamBold
InspectPrice.TextSize = 13
InspectPrice.Parent = InspectPanel

local InspectDescription = Instance.new("TextLabel")
InspectDescription.Size = UDim2.new(1, -30, 1, -330)
InspectDescription.Position = UDim2.fromOffset(15, 265)
InspectDescription.BackgroundTransparency = 1
InspectDescription.TextWrapped = true
InspectDescription.TextYAlignment = Enum.TextYAlignment.Top
InspectDescription.Font = Enum.Font.GothamMedium
InspectDescription.TextColor3 = Theme.TextDim
InspectDescription.TextSize = 13
InspectDescription.Parent = InspectPanel

local InspectButton = Instance.new("TextButton")
InspectButton.Size = UDim2.new(1, -30, 0, 48)
InspectButton.Position = UDim2.new(0, 15, 1, -60)
InspectButton.BackgroundColor3 = Theme.Orange
InspectButton.TextColor3 = Theme.Text
InspectButton.Font = Enum.Font.GothamBold
InspectButton.TextSize = 15
InspectButton.Parent = InspectPanel
Corner(InspectButton, 14)

--====================================================
-- NOT ENOUGH COINS NOTIFICATION
--====================================================
local Notification = Instance.new("Frame")
Notification.Size = UDim2.fromOffset(300, 60)
Notification.Position = UDim2.new(0.5, -150, 0, -80)
Notification.BackgroundColor3 = Theme.Red
Notification.Visible = false
Notification.Parent = Gui
Corner(Notification, 12)
Stroke(Notification, Color3.fromRGB(0, 0, 0), 1)

local NotificationText = Instance.new("TextLabel")
NotificationText.Size = UDim2.fromScale(1,1)
NotificationText.BackgroundTransparency = 1
NotificationText.TextColor3 = Theme.Text
NotificationText.Font = Enum.Font.GothamBold
NotificationText.TextSize = 16
NotificationText.Text = "Not enough coins!"
NotificationText.Parent = Notification

local NotificationBusy = false

local function ShowNotification(text)
	if NotificationBusy then return end
	NotificationBusy = true

	NotificationText.Text = text
	Notification.Visible = true
	Notification.Position = UDim2.new(0.5, -150, 0, -80)

	TweenService:Create(
		Notification,
		TweenInfo.new(0.25, Enum.EasingStyle.Back),
		{Position = UDim2.new(0.5, -150, 0, 20)}
	):Play()

	task.wait(2)

	local tween = TweenService:Create(
		Notification,
		TweenInfo.new(0.25),
		{Position = UDim2.new(0.5, -150, 0, -80)}
	)
	tween:Play()
	tween.Completed:Wait()

	Notification.Visible = false
	NotificationBusy = false
end

--====================================================
-- TAB & SORT TOGGLES
--====================================================
local SortPrice = Instance.new("TextButton")
SortPrice.Size = UDim2.fromOffset(90, 34)
SortPrice.Position = UDim2.fromOffset(15, 15)
SortPrice.BackgroundColor3 = Theme.Orange
SortPrice.Text = "PRICE"
SortPrice.TextColor3 = Theme.Text
SortPrice.Font = Enum.Font.GothamBold
SortPrice.TextSize = 12
SortPrice.Parent = GauntletView
Corner(SortPrice, 10)

local SortRarity = Instance.new("TextButton")
SortRarity.Size = UDim2.fromOffset(90, 34)
SortRarity.Position = UDim2.fromOffset(115, 15)
SortRarity.BackgroundColor3 = Theme.SurfaceLight
SortRarity.Text = "RARITY"
SortRarity.TextColor3 = Theme.TextDim
SortRarity.Font = Enum.Font.GothamBold
SortRarity.TextSize = 12
SortRarity.Parent = GauntletView
Corner(SortRarity, 10)

--====================================================
-- INVENTORY REGISTRATION SYSTEM
--====================================================
local Owned = {}
local CardRegistry = {}
local SelectedGauntlet = nil

local function RefreshOwned()
	local success, result = pcall(function() return GetOwnedTools:InvokeServer() end)
	if success and result then Owned = result end
	if not table.find(Owned, "Starter Gauntlet") then table.insert(Owned, "Starter Gauntlet") end
	
	-- Pre-check GamePass ownership to avoid "SELECT" showing for unowned gamepass items
	for name, id in pairs(Gamepasses) do
		if not table.find(Owned, name) then
			local owns = false
			local s, res = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, id) end)
			if s and res then
				table.insert(Owned, name)
			end
		end
	end
end
RefreshOwned()

--====================================================
-- ENGINE: PANEL TWEENING MANAGEMENT
--====================================================
local function UpdateInspect(name)
	local data = GauntletConfig[name]
	if not data then return end

	SelectedGauntlet = name

	if not InspectPanel.Visible then
		InspectPanel.Visible = true
		TweenService:Create(GridContainer, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, -340, 1, -85)
		}):Play()
		TweenService:Create(InspectPanel, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -325, 0, 15)
		}):Play()
	end

	InspectName.Text = string.upper(name)
	InspectIcon.Image = (data.Icon and data.Icon ~= "") and data.Icon or FALLBACK_IMAGE
	InspectRarity.Text = string.upper(data.Rarity) .. " GRADE"
	InspectRarity.TextColor3 = RarityColors[data.Rarity]
	InspectDescription.Text = data.Desc or "No database specs found."
	if Gamepasses[name] then
		InspectPrice.Text = "COST: R$ " .. data.Price
	else
		InspectPrice.Text = "COST: " .. data.Price .. " COINS"
	end
	InspectOutline.Color = RarityColors[data.Rarity]

	if table.find(Owned, name) then
		InspectButton.Text = "OWNED"
		InspectButton.BackgroundColor3 = Theme.Green
	elseif Gamepasses[name] then
		InspectButton.Text = "BUY GAMEPASS"
		InspectButton.BackgroundColor3 = Theme.Gold
	else
		InspectButton.Text = "CONFIRM PURCHASE"
		InspectButton.BackgroundColor3 = Theme.Orange
	end
end

InspectButton.MouseButton1Click:Connect(function()
	if not SelectedGauntlet then
		return
	end

	if table.find(Owned, SelectedGauntlet) then
		InspectButton.Text = "OWNED"
		InspectButton.BackgroundColor3 = Theme.Green
		return
	end

	-- Gamepass purchase
	local gamepassId = Gamepasses[SelectedGauntlet]
	if gamepassId then
		MarketplaceService:PromptGamePassPurchase(Player, gamepassId)
		return
	end
	
	-- Coin purchase
	local coinsValue = Player:GetAttribute("Coins") or 0
	local price = GauntletConfig[SelectedGauntlet].Price

	if coinsValue < price then
		if PriceLabel then -- Fixed: Checking if label exists before update
			PriceLabel.Text = (price - coinsValue) .. " MORE COINS NEEDED"
		end
		ShowNotification("You need "..(price - coinsValue).." more coins!")
		return
	end

	PurchaseEvent:FireServer(SelectedGauntlet)

	task.wait(0.4)

	RefreshOwned()

	for _, refresh in pairs(CardRegistry) do
		refresh()
	end

	UpdateInspect(SelectedGauntlet)
end)

--====================================================
-- MODULAR CARD GENERATORS
--====================================================
local CardObjectMapping = {}

local function CreateCard(name, data)
	local card = Instance.new("TextButton")
	card.AutoButtonColor = false
	card.Text = ""
	card.BackgroundColor3 = Theme.Surface
	card.Parent = GridContainer
	Corner(card, 16)

	local outline = Stroke(card, RarityColors[data.Rarity], 1.5)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Surface),
		ColorSequenceKeypoint.new(1, RarityColors[data.Rarity]:Lerp(Theme.Background, 0.85))
	})
	grad.Rotation = 45
	grad.Parent = card

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(90, 90)
	icon.Position = UDim2.new(.5, -45, 0, 15)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Image = (data.Icon and data.Icon ~= "") and data.Icon or FALLBACK_IMAGE
	icon.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 22)
	title.Position = UDim2.fromOffset(10, 120)
	title.BackgroundTransparency = 1
	title.Text = name
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextColor3 = Theme.Text
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = card
	Stroke(title, Color3.new(0,0,0), 2, Enum.ApplyStrokeMode.Contextual)

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -20, 0, 18)
	rarityLabel.Position = UDim2.fromOffset(10, 142)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = string.upper(data.Rarity)
	rarityLabel.Font = Enum.Font.GothamBlack
	rarityLabel.TextSize = 10
	rarityLabel.TextColor3 = RarityColors[data.Rarity]
	rarityLabel.Parent = card
	Stroke(rarityLabel, Color3.new(0,0,0), 2, Enum.ApplyStrokeMode.Contextual)

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -20, 0, 18)
	priceLabel.Position = UDim2.fromOffset(10, 162)
	priceLabel.BackgroundTransparency = 1
	if Gamepasses[name] then
		priceLabel.Text = "R$ " .. data.Price
	else
		priceLabel.Text = data.Price .. " Coins"
	end
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 11
	priceLabel.TextColor3 = Theme.TextDim
	priceLabel.Parent = card
	Stroke(priceLabel, Color3.new(0,0,0), 2, Enum.ApplyStrokeMode.Contextual)

	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(1, -20, 0, 34)
	buyButton.Position = UDim2.new(0, 10, 1, -44)
	buyButton.BackgroundColor3 = Theme.Orange
	buyButton.Text = ""
	buyButton.Parent = card
	Corner(buyButton, 10)
	Stroke(buyButton, Color3.new(0,0,0), 2)

	local buyText = Instance.new("TextLabel")
	buyText.Size = UDim2.fromScale(1, 1)
	buyText.BackgroundTransparency = 1
	buyText.TextColor3 = Theme.Text
	buyText.Font = Enum.Font.GothamBold
	buyText.TextSize = 12
	buyText.Parent = buyButton
	Stroke(buyText, Color3.new(0,0,0), 2, Enum.ApplyStrokeMode.Contextual)

	local function Refresh()
		if table.find(Owned, name) then
			buyText.Text = "OWNED"
			buyButton.BackgroundColor3 = Theme.Green
		else
			buyText.Text = "SELECT"
			buyButton.BackgroundColor3 = Theme.Orange
		end
	end

	Refresh()
	CardRegistry[name] = Refresh
	CardObjectMapping[card] = name

	card.MouseButton1Click:Connect(function() UpdateInspect(name) end)
	buyButton.MouseButton1Click:Connect(function() UpdateInspect(name) end)

	card.MouseEnter:Connect(function() TweenService:Create(card, TweenInfo.new(.15), {BackgroundColor3 = Theme.SurfaceLight}):Play() end)
	card.MouseLeave:Connect(function() TweenService:Create(card, TweenInfo.new(.15), {BackgroundColor3 = Theme.Surface}):Play() end)

	-- Rare Cosmetics Anim Loops
	if data.Rarity == "Mythic" then
		task.spawn(function()
			while card.Parent do
				TweenService:Create(outline, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Thickness = 3, Color = Theme.Gold}):Play()
				task.wait(0.8)
				TweenService:Create(outline, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Thickness = 1.5, Color = Theme.Mythic}):Play()
				task.wait(0.8)
			end
		end)
	elseif data.Rarity == "Legendary" then
		task.spawn(function()
			while card.Parent do
				TweenService:Create(rarityLabel, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = Theme.Gold}):Play()
				task.wait(1.2)
				TweenService:Create(rarityLabel, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextColor3 = Theme.Legendary}):Play()
				task.wait(1.2)
			end
		end)
	end
end

local function CreateCoinCard(bundle)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = Theme.Surface
	card.Parent = CoinGridContainer
	Corner(card, 16)
	Stroke(card, Theme.Gold, 1)

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(80, 80)
	icon.Position = UDim2.new(.5, -40, 0, 15)
	icon.BackgroundTransparency = 1
	icon.Image = bundle.Image
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 25)
	title.Position = UDim2.fromOffset(10, 105)
	title.BackgroundTransparency = 1
	title.Text = bundle.Name
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 15
	title.TextColor3 = Theme.Text
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -20, 0, 20)
	desc.Position = UDim2.fromOffset(10, 130)
	desc.BackgroundTransparency = 1
	desc.Text = "+" .. bundle.Amount .. " Credits"
	desc.Font = Enum.Font.GothamBold
	desc.TextSize = 12
	desc.TextColor3 = Theme.Green
	desc.Parent = card

	local robuxButton = Instance.new("TextButton")
	robuxButton.Size = UDim2.new(1, -20, 0, 36)
	robuxButton.Position = UDim2.new(0, 10, 1, -46)
	robuxButton.BackgroundColor3 = Theme.Orange
	robuxButton.Text = "R$ " .. bundle.Robux
	robuxButton.Font = Enum.Font.GothamBold
	robuxButton.TextColor3 = Theme.Text
	robuxButton.TextSize = 13
	robuxButton.Parent = card
	Corner(robuxButton, 10)

	robuxButton.MouseButton1Click:Connect(function() MarketplaceService:PromptProductPurchase(Player, bundle.ProductId) end)
end

--====================================================
-- BUILD CARDS
--====================================================
for name, data in pairs(GauntletConfig) do
	CreateCard(name, data)
end

for _, bundle in ipairs(CoinBundles) do
	CreateCoinCard(bundle)
end

--====================================================
-- NAVIGATION BINDERS
--====================================================
TabGauntlets.MouseButton1Click:Connect(function()
	TabGauntlets.BackgroundColor3 = Theme.Orange; TabGauntlets.TextColor3 = Theme.Text
	TabCoins.BackgroundColor3 = Theme.SurfaceLight; TabCoins.TextColor3 = Theme.TextDim
	GauntletView.Visible = true; CoinView.Visible = false; SearchBox.Visible = true
end)

TabCoins.MouseButton1Click:Connect(function()
	TabCoins.BackgroundColor3 = Theme.Orange; TabCoins.TextColor3 = Theme.Text
	TabGauntlets.BackgroundColor3 = Theme.SurfaceLight; TabGauntlets.TextColor3 = Theme.TextDim
	CoinView.Visible = true; GauntletView.Visible = false; SearchBox.Visible = false
end)

--====================================================
-- SORTING PROCESSORS
--====================================================
local function SortByPrice()
	for _, card in ipairs(GridContainer:GetChildren()) do
		if not card:IsA("TextButton") then continue end
		local name = CardObjectMapping[card]
		card.LayoutOrder = GauntletConfig[name] and GauntletConfig[name].Price or 0
	end
end

local function SortByRarity()
	for _, card in ipairs(GridContainer:GetChildren()) do
		if not card:IsA("TextButton") then continue end
		local name = CardObjectMapping[card]
		local rarity = GauntletConfig[name] and GauntletConfig[name].Rarity or "Common"
		card.LayoutOrder = RarityOrder[rarity] or 1
	end
end

SortPrice.MouseButton1Click:Connect(function()
	SortPrice.BackgroundColor3 = Theme.Orange; SortPrice.TextColor3 = Theme.Text
	SortRarity.BackgroundColor3 = Theme.SurfaceLight; SortRarity.TextColor3 = Theme.TextDim
	SortByPrice()
end)

SortRarity.MouseButton1Click:Connect(function()
	SortRarity.BackgroundColor3 = Theme.Orange; SortRarity.TextColor3 = Theme.Text
	SortPrice.BackgroundColor3 = Theme.SurfaceLight; SortPrice.TextColor3 = Theme.TextDim
	SortByRarity()
end)

-- Setup Defaults
SortByPrice()
AdjustCanvasSize()
AdjustCoinCanvasSize()

--====================================================
-- HEADER COMMERCE TRACKER & AUTO-SEARCH LISTENER
--====================================================
local CoinFrame = Instance.new("Frame")
CoinFrame.Size = UDim2.fromOffset(130, 38)
CoinFrame.Position = UDim2.new(1, -155, .5, -19)
CoinFrame.BackgroundColor3 = Theme.Background
CoinFrame.Parent = Header
Corner(CoinFrame, 10)
Stroke(CoinFrame, Theme.Gold, 1)

local CoinLabel = Instance.new("TextLabel")
CoinLabel.Size = UDim2.fromScale(1, 1)
CoinLabel.BackgroundTransparency = 1
CoinLabel.Font = Enum.Font.GothamBold
CoinLabel.TextColor3 = Theme.Gold
CoinLabel.TextSize = 13
CoinLabel.Parent = CoinFrame

local CoinIcon = Instance.new("ImageLabel")
CoinIcon.Name = "CoinIcon"
CoinIcon.Size = UDim2.fromOffset(22, 22)
CoinIcon.Position = UDim2.new(0, 8, 0.5, -11)
CoinIcon.BackgroundTransparency = 1
CoinIcon.Image = "rbxassetid://18209599552"
CoinIcon.ScaleType = Enum.ScaleType.Fit
CoinIcon.Parent = CoinFrame

CoinLabel.Position = UDim2.new(0, 36, 0, 0)
CoinLabel.Size = UDim2.new(1, -36, 1, 0)
CoinLabel.TextXAlignment = Enum.TextXAlignment.Left

local function FormatNumber(n)
	local s = tostring(n)
	while true do
		local k
		s, k = string.gsub(s, "^(%-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return s
end

task.spawn(function()
	local function Update()
		CoinLabel.Text = FormatNumber(Player:GetAttribute("Coins") or 0)
	end
	Update()
	Player:GetAttributeChangedSignal("Coins"):Connect(Update)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = string.lower(SearchBox.Text)
	for _, obj in ipairs(GridContainer:GetChildren()) do
		if not obj:IsA("TextButton") then continue end
		local mappedName = CardObjectMapping[obj]
		if mappedName then
			obj.Visible = (query == "") or string.find(string.lower(mappedName), query, 1, true) ~= nil
		end
	end
end)

--====================================================
-- CONTROL OVERLAYS WINDOW TRANSITIONS
--====================================================
local ShopOpen = false

local function OpenShop()
	if ShopOpen then return end
	ShopOpen = true
	Main.Visible = true
	Main.Size = UDim2.fromScale(.55, .52)
	Blur.Size = 0
	TweenService:Create(Blur, TweenInfo.new(.22), {Size = 16}):Play()
	TweenService:Create(Main, TweenInfo.new(.22, Enum.EasingStyle.Back), {Size = UDim2.fromScale(.72, .80)}):Play() -- Clean Narrowed Aspect Scale
end

local function CloseShop()
	if not ShopOpen then return end
	ShopOpen = false

	InspectPanel.Visible = false
	InspectPanel.Position = UDim2.new(1, 50, 0, 15)
	GridContainer.Size = UDim2.new(1, -30, 1, -85)

	TweenService:Create(Blur, TweenInfo.new(.2), {Size = 0}):Play()
	local tween = TweenService:Create(Main, TweenInfo.new(.18), {Size = UDim2.fromScale(.55, .52)})
	tween:Play()
	tween.Completed:Wait()
	Main.Visible = false
end

OpenButton.MouseButton1Click:Connect(function() if ShopOpen then CloseShop() else OpenShop() end end)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.B then if ShopOpen then CloseShop() else OpenShop() end end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if player ~= Player then
		return
	end

	if not wasPurchased then
		return
	end

	-- Give the server a moment to save ownership
	task.wait(0.5)

	RefreshOwned()

	for _, refresh in pairs(CardRegistry) do
		refresh()
	end

	if SelectedGauntlet then
		UpdateInspect(SelectedGauntlet)
	end
end)
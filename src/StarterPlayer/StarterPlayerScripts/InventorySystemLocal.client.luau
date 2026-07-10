local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gauntletsFolder = ReplicatedStorage:WaitForChild("Gauntlets")
local selectGauntletEvent = ReplicatedStorage:WaitForChild("SelectGauntlet")
local openSelectionEvent = ReplicatedStorage:WaitForChild("OpenGauntletSelection")

local getOwnedTools = ReplicatedStorage:WaitForChild("GetOwnedTools")
local UITheme = require(ReplicatedStorage:WaitForChild("UITheme"))

-- UI state
local currentSelectedButton = nil
local isFading = false
local ownedGauntlets = {}

local function updateOwned()
	ownedGauntlets = getOwnedTools:InvokeServer() or {}
	table.insert(ownedGauntlets, "Starter Gauntlet")
end

local THEME = UITheme.THEME
THEME.PRIMARY = THEME.CYAN
THEME.SECONDARY = THEME.MAGENTA
THEME.ACCENT = THEME.YELLOW
THEME.BLACK = THEME.BG
THEME.LOCKED = THEME.TEXT_DIM
THEME.VIBRANT_GRADIENT = THEME.YELLOW_TITLE

local function applyHighEnd3D(label, colorSequence)
	UITheme.outline(label, 4)
	UITheme.textGradient(label, colorSequence or THEME.MATCH_GRADIENT)
end

-- ==========================================
-- ITEM IMAGE CONFIGURATION (PASTE ASSET IDS HERE)
-- ==========================================
local ICONS = {
	["Emerald Gauntlet"]    = "rbxassetid://132640003436639",
	["Water Gauntlet"]     = "rbxassetid://97379845339532",
	["Fire Gauntlet"]      = "rbxassetid://108789212527369",
	["Ice Gauntlet"]       = "rbxassetid://77632532567521",
	["Rock Gauntlet"]      = "rbxassetid://129278461826205",
	["Nature Gauntlet"]     = "rbxassetid://133298397460165",
	["Energy Gauntlet"]    = "rbxassetid://94440351994069",
	["Space Gauntlet"]     = "rbxassetid://131107012060344",
	["Full Gold Gauntlet"] = "rbxassetid://101627968386615",
	["God Gauntlet"] = "rbxassetid://124282535943612",
	["Wind Gauntlet"] = "rbxassetid://120175668944028",
	["Void Gauntlet"] = "rbxassetid://82173630536383",
	["X-Ray Gauntlet"] = "rbxassetid://71772677262812",
	["Missle Gauntlet"] = "rbxassetid://101627968386615",
	["Grappling Gauntlet"] = "rbxassetid://101627968386615",
}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GauntletSelectionUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true 
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Blur Overlay
local overlay = Instance.new("Frame")
overlay.Name = "BlurOverlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.AnchorPoint = Vector2.new(0.5, 0.5) 
overlay.Position = UDim2.fromScale(0.5, 0.5)  
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 1
overlay.Parent = screenGui

-- Create Main Frame
local mainFrame = UITheme.createPanel("MainFrame", UDim2.new(0, 600, 0, 400), THEME.CYAN)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Parent = screenGui
UITheme.createTabHeader(mainFrame, "GAUNTLETS", 150)

-- Title
local listTitle = Instance.new("TextLabel")
listTitle.Size = UDim2.new(1, -60, 0, 60)
listTitle.Position = UDim2.new(0, 30, 0, 10)
listTitle.BackgroundTransparency = 1
listTitle.Text = "GAUNTLETS"
listTitle.TextColor3 = THEME.WHITE
listTitle.Font = THEME.FONT
listTitle.TextSize = 28
listTitle.TextXAlignment = Enum.TextXAlignment.Left
listTitle.Parent = mainFrame
applyHighEnd3D(listTitle, THEME.VIBRANT_GRADIENT)

-- Countdown
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.Size = UDim2.new(0, 100, 0, 60)
countdownLabel.Position = UDim2.new(1, -30, 0, 10) 
countdownLabel.AnchorPoint = Vector2.new(1, 0)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = "10S"
countdownLabel.TextColor3 = THEME.WHITE
countdownLabel.Font = THEME.FONT
countdownLabel.TextSize = 32
countdownLabel.TextXAlignment = Enum.TextXAlignment.Right
countdownLabel.TextYAlignment = Enum.TextYAlignment.Center
countdownLabel.Parent = mainFrame

applyHighEnd3D(countdownLabel)

-- CONTENT SECTION
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -40, 1, -100)
contentFrame.Position = UDim2.new(0, 20, 0, 80)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local gridContainer = Instance.new("Frame")
gridContainer.Size = UDim2.new(0.5, -10, 1, 0)
gridContainer.BackgroundTransparency = 1
gridContainer.Parent = contentFrame

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "GauntletGrid"
scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 4
scrollingFrame.ScrollBarImageColor3 = THEME.SECONDARY
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollingFrame.Parent = gridContainer

local uiGrid = Instance.new("UIGridLayout")
uiGrid.CellSize = UDim2.new(0, 80, 0, 80)
uiGrid.CellPadding = UDim2.new(0, 10, 0, 10)
uiGrid.SortOrder = Enum.SortOrder.Name
uiGrid.Parent = scrollingFrame

-- Details Panel
local detailsFrame = Instance.new("Frame")
detailsFrame.Size = UDim2.new(0.5, -10, 1, 0)
detailsFrame.Position = UDim2.fromScale(0.5, 0)
detailsFrame.BackgroundColor3 = THEME.SURFACE
detailsFrame.BackgroundTransparency = 0.2
detailsFrame.Parent = contentFrame

local detailsCorner = Instance.new("UICorner")
detailsCorner.CornerRadius = UDim.new(0, 12)
detailsCorner.Parent = detailsFrame

local gNameLabel = Instance.new("TextLabel")
gNameLabel.Size = UDim2.new(1, -20, 0, 40)
gNameLabel.Position = UDim2.fromOffset(10, 10)
gNameLabel.BackgroundTransparency = 1
gNameLabel.Text = "SELECT A GAUNTLET"
gNameLabel.TextColor3 = THEME.WHITE
gNameLabel.Font = THEME.FONT
gNameLabel.TextSize = 20
gNameLabel.TextWrapped = true
gNameLabel.Parent = detailsFrame

local gAbilityLabel = Instance.new("TextLabel")
gAbilityLabel.Size = UDim2.new(1, -20, 1, -110)
gAbilityLabel.Position = UDim2.new(0, 10, 0, 50)
gAbilityLabel.BackgroundTransparency = 1
gAbilityLabel.Text = ""
gAbilityLabel.TextColor3 = THEME.TEXT_DIM
gAbilityLabel.Font = THEME.FONT_MED
gAbilityLabel.TextSize = 14
gAbilityLabel.TextWrapped = true
gAbilityLabel.TextYAlignment = Enum.TextYAlignment.Top
gAbilityLabel.Parent = detailsFrame

local selectButton = UITheme.createActionButton("SELECT", nil, 44, THEME.LIME)
selectButton.Size = UDim2.new(1, -20, 0, 44)
selectButton.Position = UDim2.new(0, 10, 1, -10)
selectButton.AnchorPoint = Vector2.new(0, 1)
selectButton.Visible = false
selectButton.Parent = detailsFrame

local gauntletData = {
	["Fire Gauntlet"] = {stats = "Damage: High\nSpeed: Medium", ability = "Passive: Deals burn damage over 3s on hit."},
	["Rock Gauntlet"] = {stats = "Damage: High\nSpeed: Medium", ability = "Ability: Smash your opponents into the ground and strike a boulder to their dome. (5s CD)."},
	["Emerald Gauntlet"] = {stats = "Damage: Medium\nSpeed: Medium", ability = "Passive: Heals on hit."},
	["Energy Gauntlet"] = {stats = "Damage: Low\nSpeed: Very High", ability = "Passive: Increases speed for 3s (5s CD)."},
	["Full Gold Gauntlet"] = {stats = "Damage: High\nSpeed: Medium", ability = "Passive: Deals 50% damage on hit."},
	["God Gauntlet"] = {stats = "Damage: Very Very High\nSpeed: Medium", ability = "Passive: Ultimate reality-breaking power causing 100% damage per hit."},
	["Grappling Gauntlet"] = {stats = "Damage: Medium\nSpeed: Medium", ability = "Ability: Shoots a grappling hook to target location, pulls player to hook. (6s CD)."},
	["Ice Gauntlet"] = {stats = "Damage: Medium\nSpeed: Medium", ability = "Ability: Freezes player for 3s (10s CD)."},
	["Missle Gauntlet"] = {stats = "Damage: High\nSpeed: Medium", ability = "Ability: Shoots 3 missils at target location, slightly following player. (6s CD)."},
	["Nature Gauntlet"] = {stats = "Damage: Medium\nSpeed: Medium", ability = "Ability: Shoots out vine that pulls targets in range towards you. (8s CD)."},
	["Space Gauntlet"] = {stats = "Damage: Medium\nSpeed: Medium", ability = "Ability: Shoots you high up into the air. (5s CD)."},
	["Void Gauntlet"] = {stats = "Damage: Medium\nSpeed: Very very high", ability = "Ability: Allows you to teleport anywhere on the map. (5s CD)."},
	["Water Gauntlet"] = {stats = "Damage: Medium\nSpeed: Medium", ability = "Ability: Slows down player and blurs screen for 3s. (5s CD)."},
	["Wind Gauntlet"] = {stats = "Damage: Medium\nSpeed: High", ability = "Ability: Allows you to fly for 3s. (8s CD)."},
	["X-ray Gauntlet"] = {stats = "Damage: Medium\nSpeed: Medium", ability = "Highlights all players on map and makes you go invisible for 5s (5s CD)."},
}

local function updateDetails(name)
	gNameLabel.Text = name:upper()
	local data = gauntletData[name]
	if data then
		gAbilityLabel.Text = data.stats .. "\n\n" .. data.ability
	else
		gAbilityLabel.Text = "No stats available.\n\nDescription: A standard combat tool."
	end
	selectButton.Visible = true
	selectButton.Text = "SELECT"
	selectButton.BackgroundColor3 = THEME.PRIMARY
end

selectButton.MouseButton1Click:Connect(function()
	if currentSelectedButton then
		selectGauntletEvent:FireServer(currentSelectedButton.Name)
		selectButton.Text = "SELECTED!"
		selectButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)

		TweenService:Create(selectButton, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, -10, 0, 48)}):Play()
		task.wait(0.1)
		TweenService:Create(selectButton, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 44)}):Play()
	end
end)

local function createGauntletButton(gauntletName)
	local isOwned = table.find(ownedGauntlets, gauntletName)

	local button = Instance.new("TextButton")
	button.Name = gauntletName
	button.BackgroundColor3 = isOwned and THEME.SURFACE or THEME.BG
	button.BackgroundTransparency = isOwned and 0.2 or 0.6
	button.Text = ""
	button.Parent = scrollingFrame
	UITheme.styleCard(button, isOwned and THEME.CYAN or THEME.TEXT_DIM, isOwned and THEME.SURFACE or THEME.BG)

	local stroke = button:FindFirstChild("NeonGlow")

	if isOwned then
		local icon = Instance.new("ImageLabel")
		icon.Name = "ItemIcon"
		icon.Size = UDim2.fromScale(0.8, 0.8) 
		icon.Position = UDim2.fromScale(0.1, 0.1) 
		icon.BackgroundTransparency = 1
		icon.Image = ICONS[gauntletName] or "rbxassetid://0"
		icon.Parent = button

		-- Integrated Black Border Setup around Image
		local iconStroke = Instance.new("UIStroke")
		iconStroke.Name = "IconBorder"
		iconStroke.Color = Color3.fromRGB(0, 0, 0)
		iconStroke.Thickness = 2
		iconStroke.Transparency = 0
		iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		iconStroke.Parent = icon
	else
		local label = Instance.new("ImageLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Image = "rbxassetid://113981661296218"
		label.ImageColor3 = THEME.LOCKED
		label.ScaleType = Enum.ScaleType.Fit
		label.Parent = button
	end

	if not isOwned then
		button.AutoButtonColor = false
		return
	end

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = THEME.SURFACE_LIGHT}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0, Thickness = 3}):Play()
	end)

	button.MouseLeave:Connect(function()
		if currentSelectedButton ~= button then
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = THEME.SURFACE}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.6, Thickness = 2}):Play()
		end
	end)

	button.MouseButton1Click:Connect(function()
		if currentSelectedButton then
			for _, child in ipairs(currentSelectedButton:GetChildren()) do
				if child:IsA("UIStroke") and child.Name ~= "IconBorder" then
					child.Color = THEME.SECONDARY
					child.Transparency = 0.6
				end
			end
		end

		currentSelectedButton = button
		stroke.Color = THEME.PRIMARY
		stroke.Transparency = 0

		updateDetails(gauntletName)
	end)
end

-- Refresh and Load Gauntlets
local function refreshGauntletList()
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	updateOwned()

	for _, gauntlet in ipairs(gauntletsFolder:GetChildren()) do
		if gauntlet:IsA("Tool") then
			createGauntletButton(gauntlet.Name)
		end
	end
end

local function toggleUI(show, duration)
	if show then
		refreshGauntletList()
		screenGui.Enabled = true
		overlay.BackgroundTransparency = 1
		mainFrame.Position = UDim2.fromScale(0.5, 1.5)

		TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.6}):Play()
		TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
	else
		TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, -0.6)}):Play()
		task.wait(0.5)
		screenGui.Enabled = false
	end
end

-- Selection Event
openSelectionEvent.OnClientEvent:Connect(function(seconds)
	toggleUI(true)

	currentSelectedButton = nil
	selectButton.Visible = false
	gNameLabel.Text = "SELECT A GAUNTLET"
	gAbilityLabel.Text = ""

	local timeRemaining = seconds
	while timeRemaining >= 0 and screenGui.Enabled do
		countdownLabel.Text = timeRemaining .. "S"

		local strokeElement = countdownLabel:FindFirstChildOfClass("UIStroke")
		if timeRemaining <= 3 then
			countdownLabel.TextColor3 = THEME.RED
			if strokeElement then strokeElement.Color = Color3.new(0.2, 0, 0) end
			TweenService:Create(countdownLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 52}):Play()
		else
			countdownLabel.TextColor3 = THEME.WHITE
			if strokeElement then strokeElement.Color = Color3.new(0, 0, 0) end
		end
		task.wait(1)
		timeRemaining -= 1
	end

	if screenGui.Enabled then
		toggleUI(false)
	end
end)

ReplicatedStorage:WaitForChild("Regen").OnClientEvent:Connect(function()
	if screenGui.Enabled then
		toggleUI(false)
	end
end)
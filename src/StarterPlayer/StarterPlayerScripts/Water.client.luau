local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local StartMapVote = ReplicatedStorage:WaitForChild("StartMapVote")
local SubmitMapVote = ReplicatedStorage:WaitForChild("SubmitMapVote")
local UpdateMapVotes = ReplicatedStorage:WaitForChild("UpdateMapVotes")
local UITheme = require(ReplicatedStorage:WaitForChild("UITheme"))
local THEME = UITheme.THEME
THEME.PRIMARY = THEME.CYAN
THEME.SECONDARY = THEME.MAGENTA
THEME.ACCENT = THEME.YELLOW
THEME.BLACK = THEME.BG
THEME.WHITE = THEME.WHITE
THEME.RED = THEME.RED
THEME.VIBRANT_GRADIENT = THEME.YELLOW_TITLE

local function applyHighEnd3D(label, colorSequence)
	UITheme.outline(label, 4)
	UITheme.textGradient(label, colorSequence or THEME.MATCH_GRADIENT)
end

-- PLACEHOLDER IMAGE IDs
local MAP_IMAGES = {
	["Nuclear Plant"] = "rbxassetid://71656623551384",
	["Sinking Ship"] = "rbxassetid://127729837346115",
	["Boxing Ring"] = "rbxassetid://93656222992912",
	["City"] = "rbxassetid://94939451376435",
	["Crane"] = "rbxassetid://115583368253098",
	["Dinner Table"] = "rbxassetid://134221917180602",
	["Island"] = "rbxassetid://100659162836159",
	["Pirate Ships"] = "rbxassetid://100578949197248",
	["Pyramid"] = "rbxassetid://99536648684339",
	["Skyscraper"] = "rbxassetid://138077486310881",
	["Mountain Side"] = "rbxassetid://130915632724387",
	["Train"] = "rbxassetid://90436693321573",
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModernMapVote"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true 
screenGui.Enabled = false
screenGui.Parent = playerGui

local blur = Instance.new("Frame")
blur.Name = "BlurOverlay"
blur.Size = UDim2.fromScale(1, 1)
blur.AnchorPoint = Vector2.new(0.5, 0.5) 
blur.Position = UDim2.fromScale(0.5, 0.5) 
blur.BackgroundColor3 = Color3.new(0,0,0)
blur.BackgroundTransparency = 1 
blur.Parent = screenGui

local mainFrame = UITheme.createPanel("MainFrame", UDim2.fromOffset(850, 520), THEME.CYAN)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Parent = screenGui
UITheme.createTabHeader(mainFrame, "MAP VOTE", 180)

local closeButton = UITheme.createCloseButton(mainFrame, nil)

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(255, 90, 90),
		Size = UDim2.fromOffset(48, 48)
	}):Play()
end)

closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.15), {
		BackgroundColor3 = THEME.RED,
		Size = UDim2.fromOffset(44, 44)
	}):Play()
end)

closeButton.MouseButton1Click:Connect(function()
	TweenService:Create(blur, TweenInfo.new(0.3), {
		BackgroundTransparency = 1
	}):Play()

	TweenService:Create(mainFrame, TweenInfo.new(
		0.4,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.In
		), {
			Position = UDim2.fromScale(0.5, -0.6)
		}):Play()

	task.wait(0.4)
	screenGui.Enabled = false
end)

-- Glossy Inner Gradient
local glassGrad = Instance.new("UIGradient")
glassGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 35))
})
glassGrad.Rotation = 45
glassGrad.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 100)
title.Position = UDim2.fromOffset(0, 10)
title.BackgroundTransparency = 1
title.Font = THEME.FONT
title.Text = "VOTE FOR NEXT MAP"
title.TextColor3 = THEME.WHITE
title.TextSize = 48
title.Parent = mainFrame
applyHighEnd3D(title, THEME.VIBRANT_GRADIENT)

-- Countdown Timer TextLabel (Styled white text with clear black stroke)
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0, 150, 0, 80)
timerLabel.Position = UDim2.new(1, -80, 0, 20) -- Aligned with the title box layout height
timerLabel.AnchorPoint = Vector2.new(1, 0)
timerLabel.BackgroundTransparency = 1 -- Removed solid background container
timerLabel.Font = Enum.Font.FredokaOne
timerLabel.TextColor3 = THEME.WHITE
timerLabel.TextSize = 44 -- Bumped size up slightly since background box is gone
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.TextYAlignment = Enum.TextYAlignment.Center
timerLabel.Text = "10S"
timerLabel.Parent = mainFrame

-- High-end outline and text-drop shadow applied directly to text
applyHighEnd3D(timerLabel)

local container = Instance.new("Frame")
container.Size = UDim2.new(0.95, 0, 0, 340)
container.Position = UDim2.fromScale(0.5, 0.65)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 30)
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Parent = container

local cards = {}

local function createMapCard(index, name)
	local card = Instance.new("TextButton")
	card.Name = "MapCard" .. index
	card.Size = UDim2.new(0, 240, 0, 320)
	card.AutoButtonColor = false
	card.Text = ""
	card.Parent = container
	UITheme.styleCard(card, THEME.CYAN, THEME.SURFACE)

	local cardStroke = card:FindFirstChild("NeonGlow")

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Size = UDim2.new(1, -20, 0.6, -10)
	imageLabel.Position = UDim2.fromOffset(10, 10)
	imageLabel.BackgroundColor3 = Color3.new(0,0,0)
	imageLabel.Image = MAP_IMAGES[name] or MAP_IMAGES["Default"]
	imageLabel.ScaleType = Enum.ScaleType.Crop
	imageLabel.Parent = card

	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = UDim.new(0, 15)
	imgCorner.Parent = imageLabel

	local mapTitle = Instance.new("TextLabel")
	mapTitle.Size = UDim2.new(1, 0, 0, 60)
	mapTitle.Position = UDim2.new(0, 0, 0.65, 0)
	mapTitle.BackgroundTransparency = 1
	mapTitle.Font = THEME.FONT
	mapTitle.Text = name:upper()
	mapTitle.TextColor3 = THEME.WHITE
	mapTitle.TextSize = 22
	mapTitle.Parent = card
	UITheme.outline(mapTitle, 4)
	UITheme.textGradient(mapTitle, THEME.YELLOW_TITLE)

	local voteCountLabel = Instance.new("TextLabel")
	voteCountLabel.Size = UDim2.new(1, 0, 0, 30)
	voteCountLabel.Position = UDim2.new(0, 0, 0.85, 0)
	voteCountLabel.BackgroundTransparency = 1
	voteCountLabel.Font = Enum.Font.FredokaOne
	voteCountLabel.Text = "0 VOTES"
	voteCountLabel.TextColor3 = THEME.ACCENT
	voteCountLabel.TextSize = 18
	voteCountLabel.Parent = card

	local voterContainer = Instance.new("Frame")
	voterContainer.Name = "Voters"
	voterContainer.Size = UDim2.new(1, -20, 0, 40)
	voterContainer.Position = UDim2.new(0.5, 0, 0, -10)
	voterContainer.AnchorPoint = Vector2.new(0.5, 1)
	voterContainer.BackgroundTransparency = 1
	voterContainer.Parent = card

	local voterLayout = Instance.new("UIListLayout")
	voterLayout.FillDirection = Enum.FillDirection.Horizontal
	voterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	voterLayout.Padding = UDim.new(0, -10)
	voterLayout.Parent = voterContainer

	cards[index] = {
		card = card,
		voterContainer = voterContainer,
		voteCountLabel = voteCountLabel,
		stroke = cardStroke,
		name = name
	}

	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(50,50,60), Size = UDim2.new(0, 250, 0, 330)}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.3), {Transparency = 0, Color = THEME.PRIMARY}):Play()
	end)

	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(35,35,40), Size = UDim2.new(0, 240, 0, 320)}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.3), {Transparency = 0.5, Color = THEME.SECONDARY}):Play()
	end)

	card.MouseButton1Click:Connect(function()
		SubmitMapVote:FireServer(index)
	end)
end

local function updateVotes(votes)
	local voteCounts = {}
	for _, cardData in pairs(cards) do
		for _, child in ipairs(cardData.voterContainer:GetChildren()) do
			if child:IsA("ImageLabel") then child:Destroy() end
		end
		voteCounts[cardData.card.Name] = 0
	end

	for userId, mapIndex in pairs(votes) do
		local cardData = cards[mapIndex]
		if cardData then
			voteCounts[cardData.card.Name] = (voteCounts[cardData.card.Name] or 0) + 1

			local playerIcon = Instance.new("ImageLabel")
			playerIcon.Size = UDim2.fromOffset(36, 36)
			playerIcon.BackgroundColor3 = Color3.new(1,1,1)
			playerIcon.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", userId)
			playerIcon.Parent = cardData.voterContainer
			playerIcon.ZIndex = 5

			local pCorner = Instance.new("UICorner")
			pCorner.CornerRadius = UDim.new(1, 0)
			pCorner.Parent = playerIcon

			local pStroke = Instance.new("UIStroke")
			pStroke.Thickness = 2
			pStroke.Color = THEME.WHITE
			pStroke.Parent = playerIcon
		end
	end

	for index, cardData in pairs(cards) do
		local count = voteCounts[cardData.card.Name] or 0
		cardData.voteCountLabel.Text = count .. (count == 1 and " VOTE" or " VOTES")

		if votes[player.UserId] == index then
			cardData.stroke.Color = Color3.fromRGB(0, 255, 100)
			cardData.stroke.Transparency = 0
		end
	end
end

UpdateMapVotes.OnClientEvent:Connect(updateVotes)

StartMapVote.OnClientEvent:Connect(function(mapNames, duration)
	cards = {}
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for i, name in ipairs(mapNames) do
		createMapCard(i, name)
	end

	screenGui.Enabled = true
	blur.BackgroundTransparency = 1
	mainFrame.Position = UDim2.fromScale(0.5, 1.5)

	TweenService:Create(blur, TweenInfo.new(0.5), {BackgroundTransparency = 0.6}):Play()
	TweenService:Create(mainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back), {Position = UDim2.fromScale(0.5, 0.5)}):Play()

	task.spawn(function()
		for i = duration, 0, -1 do
			timerLabel.Text = i .. "S"

			-- Handle color sequence flashes directly on text elements when time is low
			local strokeElement = timerLabel:FindFirstChildOfClass("UIStroke")
			if i <= 3 then
				timerLabel.TextColor3 = THEME.RED
				if strokeElement then strokeElement.Color = Color3.new(0.2, 0, 0) end
				TweenService:Create(timerLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 52}):Play()
			else
				timerLabel.TextColor3 = THEME.WHITE
				if strokeElement then strokeElement.Color = Color3.new(0, 0, 0) end
			end
			task.wait(1)
		end
		TweenService:Create(blur, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, -0.6)}):Play()
		task.wait(0.5)
		screenGui.Enabled = false
	end)
end)
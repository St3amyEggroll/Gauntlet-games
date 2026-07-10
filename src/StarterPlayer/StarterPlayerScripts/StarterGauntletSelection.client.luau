--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SelectGauntlet = ReplicatedStorage:WaitForChild("SelectGauntlet")

local THEME = {
	BG = Color3.fromRGB(15, 17, 26),
	BORDER = Color3.fromRGB(0, 255, 180),
	ACCENT = Color3.fromRGB(255, 220, 0),
	WHITE = Color3.fromRGB(255, 255, 255),
	CARD_BG = Color3.fromRGB(24, 28, 41)
}

local GAUNTLET_DATA = {
	["Space Gauntlet"] = {
		Icon = "rbxassetid://131107012060344",
		Desc = "Unlock extra very high jump.",
		Ability = "Super Jump"
	},
	["Energy Gauntlet"] = {
		Icon = "rbxassetid://94440351994069",
		Desc = "Increase your speed for 3 seconds.",
		Ability = "Speed Boost"
	},
	["Emerald Gauntlet"] = {
		Icon = "rbxassetid://132640003436639",
		Desc = "Heals you with every hit to an opponent.",
		Ability = "Lifesteal"
	}
}

local function buildSelectionUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StarterGauntletSelectionUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 1000010
	screenGui.Parent = playerGui

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Parent = screenGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.fromScale(0.8, 0.7)
	mainFrame.Position = UDim2.fromScale(0.5, 0.5)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = THEME.BG
	mainFrame.Parent = screenGui
	mainFrame.Visible = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = THEME.BORDER
	stroke.Parent = mainFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 80)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.Text = "CHOOSE YOUR STARTER GAUNTLET"
	title.TextColor3 = THEME.BORDER
	title.TextSize = 36
	title.Parent = mainFrame

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 30)
	subtitle.Position = UDim2.fromOffset(0, 70)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Text = "SELECT ONE FOR FREE TO START YOUR JOURNEY"
	subtitle.TextColor3 = THEME.WHITE
	subtitle.TextSize = 16
	subtitle.Parent = mainFrame

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -100, 1, -200)
	container.Position = UDim2.fromOffset(50, 150)
	container.BackgroundTransparency = 1
	container.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 30)
	layout.Parent = container

	for name, data in pairs(GAUNTLET_DATA) do
		local card = Instance.new("TextButton")
		card.Name = name
		card.Size = UDim2.new(0.3, -20, 1, 0)
		card.BackgroundColor3 = THEME.CARD_BG
		card.Text = ""
		card.AutoButtonColor = false
		card.Parent = container

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 15)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Thickness = 2
		cardStroke.Color = THEME.WHITE
		cardStroke.Transparency = 0.5
		cardStroke.Parent = card

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.fromScale(0.6, 0.45)
		icon.Position = UDim2.fromScale(0.5, 0.3)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = data.Icon
		icon.Parent = card

		local gName = Instance.new("TextLabel")
		gName.Size = UDim2.new(1, 0, 0, 40)
		gName.Position = UDim2.fromScale(0, 0.55)
		gName.BackgroundTransparency = 1
		gName.Font = Enum.Font.FredokaOne
		gName.Text = name:upper()
		gName.TextColor3 = THEME.ACCENT
		gName.TextSize = 20
		gName.Parent = card

		local abilityLabel = Instance.new("TextLabel")
		abilityLabel.Size = UDim2.new(1, -20, 0, 20)
		abilityLabel.Position = UDim2.fromScale(0, 0.65)
		abilityLabel.BackgroundTransparency = 1
		abilityLabel.Font = Enum.Font.GothamBold
		abilityLabel.Text = "Ability: " .. data.Ability
		abilityLabel.TextColor3 = THEME.BORDER
		abilityLabel.TextSize = 14
		abilityLabel.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -30, 0, 60)
		desc.Position = UDim2.fromScale(0.5, 0.8)
		desc.AnchorPoint = Vector2.new(0.5, 0.5)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium
		desc.Text = data.Desc
		desc.TextColor3 = THEME.WHITE
		desc.TextSize = 13
		desc.TextWrapped = true
		desc.Parent = card

		local selectLabel = Instance.new("TextLabel")
		selectLabel.Size = UDim2.new(1, 0, 0, 40)
		selectLabel.Position = UDim2.new(0, 0, 1, -45)
		selectLabel.BackgroundTransparency = 1
		selectLabel.Font = Enum.Font.FredokaOne
		selectLabel.Text = "CLICK TO SELECT"
		selectLabel.TextColor3 = THEME.BORDER
		selectLabel.TextSize = 16
		selectLabel.Visible = false
		selectLabel.Parent = card

		card.MouseEnter:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = THEME.BG, Size = UDim2.new(0.3, -10, 1, 10)}):Play()
			TweenService:Create(cardStroke, TweenInfo.new(0.2), {Color = THEME.BORDER, Transparency = 0}):Play()
			selectLabel.Visible = true
		end)

		card.MouseLeave:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = THEME.CARD_BG, Size = UDim2.new(0.3, -20, 1, 0)}):Play()
			TweenService:Create(cardStroke, TweenInfo.new(0.2), {Color = THEME.WHITE, Transparency = 0.5}):Play()
			selectLabel.Visible = false
		end)

		card.MouseButton1Click:Connect(function()
			SelectGauntlet:FireServer(name)
			
			-- Fix selection persistence bug
			local fade = Instance.new("Frame")
			fade.Size = UDim2.fromScale(1, 1)
			fade.BackgroundColor3 = THEME.ACCENT
			fade.ZIndex = 10
			fade.BackgroundTransparency = 1
			fade.Parent = card
			
			local corner2 = Instance.new("UICorner")
			corner2.CornerRadius = UDim.new(0, 15)
			corner2.Parent = fade
			
			TweenService:Create(fade, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
			
			local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromScale(0, 0)})
			TweenService:Create(overlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
			closeTween:Play()
			closeTween.Completed:Connect(function()
				screenGui:Destroy()
			end)
		end)
	end

	return screenGui, mainFrame, overlay
end

local function showSelection()
	local screenGui, mainFrame, overlay = buildSelectionUI()
	mainFrame.Visible = true
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()
	TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Size = UDim2.fromScale(0.8, 0.7)}):Play()
end

-- Export for FirstJoinTutorial to call
_G.ShowStarterGauntletSelection = showSelection

-- Auto-show if triggered early or already exists
if _G.TriggerStarterGauntletImmediate then
	showSelection()
end

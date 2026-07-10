--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =============================================================================
-- CONFIGURATION & CONFIG THEME
-- =============================================================================
local UI_TITLE = "HOW TO PLAY & TIPS"
local TUTORIAL_TIPS = {
	"🥊 Choose your Gauntlet wisely during the selection phase before the match begins!",
	"💥 Every gauntlet has unique stats and hidden abilities. Read their info card in the shop.",
	"🪙 Defeating enemies awards you +5 Coins. Winning a full round rewards you +10 Coins!",
	"🏆 Use your hard-earned Coins in the main shop to unlock legendary tier Gauntlets.",
	"⚠️ Watch out for map hazards like Rising Acid or Sinking Water as the match goes on!"
}

local THEME = {
	BG = Color3.fromRGB(15, 17, 26),
	BORDER = Color3.fromRGB(0, 255, 180), 
	ACCENT = Color3.fromRGB(255, 220, 0),
	WHITE = Color3.fromRGB(255, 255, 255),
	ROW_BG = Color3.fromRGB(24, 28, 41)
}

local mainShopGui: ScreenGui? = nil
local shopOpenBtn: ImageButton? = nil
local tutorialGui: ScreenGui
local hintLabel: TextLabel
local pointerArrow: ImageLabel
local currentStep = 1

-- =============================================================================
-- INTERACTIVE STEP CONTROLLER
-- =============================================================================
local function updateTutorialStep()
	if currentStep == 2 then
		hintLabel.Text = "💨 PRESS 'Q' TO DASH AND ESCAPE HAZARDS!"
		pointerArrow.Visible = false

		local connection: RBXScriptConnection
		connection = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.Q then
				connection:Disconnect()
				currentStep = 6
				updateTutorialStep()
			end
		end)

	elseif currentStep == 6 then
		if pointerArrow then pointerArrow:Destroy() end
		hintLabel.Text = "🎉 YOU'RE ALL SET! HAVE FUN AND GOOD LUCK!"
		hintLabel.TextColor3 = THEME.ACCENT

		task.wait(3.5)
		local mainBanner = hintLabel.Parent :: Frame
		local outTween = TweenService:Create(mainBanner, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -100)})
		outTween:Play()
		outTween.Completed:Connect(function()
			if tutorialGui then tutorialGui:Destroy() end
		end)
	end
end

-- =============================================================================
-- DYNAMIC TUTORIAL STEP FRAMEWORK
-- =============================================================================
local function startInteractiveOnboarding()
	tutorialGui = Instance.new("ScreenGui")
	tutorialGui.Name = "InteractiveTutorialOverlay"
	tutorialGui.IgnoreGuiInset = true
	tutorialGui.ResetOnSpawn = false
	tutorialGui.DisplayOrder = 1000005
	tutorialGui.Parent = playerGui

	local bannerFrame = Instance.new("Frame")
	bannerFrame.Name = "InstructionBanner"
	bannerFrame.Size = UDim2.fromOffset(450, 55)
	bannerFrame.Position = UDim2.new(0.5, 0, 0, -100) 
	bannerFrame.AnchorPoint = Vector2.new(0.5, 0)
	bannerFrame.BackgroundColor3 = THEME.BG
	bannerFrame.Parent = tutorialGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = bannerFrame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = THEME.BORDER
	stroke.Parent = bannerFrame

	hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(1, -20, 1, 0)
	hintLabel.Position = UDim2.fromOffset(10, 0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Font = Enum.Font.FredokaOne
	hintLabel.TextColor3 = THEME.WHITE
	hintLabel.TextSize = 15
	hintLabel.TextWrapped = true
	hintLabel.Parent = bannerFrame

	pointerArrow = Instance.new("ImageLabel")
	pointerArrow.Name = "TutorialPointer"
	pointerArrow.Size = UDim2.fromOffset(45, 30)
	pointerArrow.BackgroundTransparency = 1
	pointerArrow.Image = "rbxassetid://13470068307" 
	pointerArrow.ImageColor3 = THEME.BORDER
	pointerArrow.Visible = false
	pointerArrow.Parent = tutorialGui

	TweenService:Create(bannerFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 0, 25)}):Play()

	currentStep = 2
	updateTutorialStep()
end

-- =============================================================================
-- MAIN INTRO DIALOGUE
-- =============================================================================
local function buildTutorialUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DynamicTutorialUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 1000000 

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Parent = screenGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0, 0) 
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = THEME.BG
	frame.ClipsDescendants = true
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = THEME.BORDER
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Position = UDim2.fromOffset(0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.Text = UI_TITLE
	title.TextColor3 = THEME.BORDER
	title.TextSize = 28
	title.Parent = frame

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -60, 1, -180)
	container.Position = UDim2.fromOffset(30, 90)
	container.BackgroundTransparency = 1
	container.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	for index, tipString in ipairs(TUTORIAL_TIPS) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 48)
		row.BackgroundColor3 = THEME.ROW_BG
		row.LayoutOrder = index
		row.Parent = container

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, -20, 1, 0)
		text.Position = UDim2.fromOffset(10, 0)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBold
		text.Text = tipString
		text.TextColor3 = THEME.WHITE
		text.TextSize = 13
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.TextWrapped = true
		text.Parent = row
	end

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(200, 44)
	closeBtn.Position = UDim2.new(0.5, 0, 1, -25)
	closeBtn.AnchorPoint = Vector2.new(0.5, 1)
	closeBtn.BackgroundColor3 = THEME.BORDER
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.Text = "READY TO FIGHT"
	closeBtn.TextColor3 = Color3.fromRGB(15, 17, 26)
	closeBtn.TextSize = 16
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = frame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = closeBtn

	screenGui.Parent = playerGui

	TweenService:Create(overlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.5}):Play()
	TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(560, 460)}):Play()

	closeBtn.MouseButton1Click:Connect(function()
		closeBtn.Active = false
		local closeTween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 0)})
		TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()

		closeTween:Play()
		closeTween.Completed:Connect(function()
			screenGui:Destroy()
			if _G.ShowStarterGauntletSelection then
				_G.ShowStarterGauntletSelection()
			end
			startInteractiveOnboarding()
		end)
	end)

	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.WHITE}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.BORDER}):Play()
	end)
end

local function evaluateFirstJoin()
	mainShopGui = playerGui:WaitForChild("GauntletShopUI", 1) :: ScreenGui?
	if mainShopGui then
		shopOpenBtn = mainShopGui:WaitForChild("OpenShop", 1) :: ImageButton?
	end

	local leaderstats = player:WaitForChild("leaderstats", 15)
	if not leaderstats then return end

	local coinsValue = leaderstats:WaitForChild("Coins", 15) :: NumberValue?
	local winsValue = leaderstats:WaitForChild("Wins", 15) :: NumberValue?

	if coinsValue and winsValue and winsValue.Value == 0 and coinsValue.Value == 0 then
		-- Removed the guard clause so execution continues
		_G.TriggerStarterGauntletImmediate = true 
		buildTutorialUI()
	end
end

task.spawn(evaluateFirstJoin)
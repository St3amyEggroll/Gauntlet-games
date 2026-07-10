local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- FALLBACK & INSTANT LOAD ASSURANCE
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
local playerGui = player:FindFirstChildOfClass("PlayerGui")

-- Force wait loop if PlayerGui is completely missing during early execution
while not playerGui do
	task.wait(0.1)
	playerGui = player:FindFirstChildOfClass("PlayerGui")
end

local SpectateSync = ReplicatedStorage:WaitForChild("SpectateSync", 2)

-- ==========================================
-- CORE DESIGN & THEME CONFIGURATION
-- ==========================================
local THEME = {
	PRIMARY = Color3.fromRGB(180, 80, 255), -- Electric Purple
	SECONDARY = Color3.fromRGB(240, 240, 255), -- White/Light Blue
	ACCENT = Color3.fromRGB(255, 60, 180), -- Magenta
	SPECTATE_BLUE = Color3.fromRGB(0, 160, 255),
	GOLD = Color3.fromRGB(255, 200, 50),
	WHITE = Color3.fromRGB(255, 255, 255),
	BLACK = Color3.fromRGB(15, 12, 20),
	SURFACE = Color3.fromRGB(35, 28, 45),
	SURFACE_LIGHT = Color3.fromRGB(55, 45, 65),
	RED = Color3.fromRGB(230, 50, 50),
	HEALTH = Color3.fromRGB(100, 255, 150),
	DASH = Color3.fromRGB(255, 220, 40),
	
	-- COLOR GRADIENTS (INTERNAL FADES)
	COIN_GRADIENT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0))
	}),
	HEALTH_GRADIENT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 180, 80))
	}),
	DASH_GRADIENT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0))
	}),
	MATCH_GRADIENT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 180, 220))
	})
}

-- Global States
local GlobalVolumeScale = 1.0
local RainbowModeActive = false
local RainbowElements = {}
local MainGameHUDs = {}

-- Caching tables
local OriginalMaterials = {}
local OriginalTextures = {}
local OriginalParticleStates = {}

-- FORCE PERSISTENT VOLUME REGULATION
local function ManageSoundInstance(sound)
	if not sound:IsA("Sound") then return end

	if not sound:GetAttribute("OriginalVolume") then
		sound:SetAttribute("OriginalVolume", sound.Volume)
		sound:GetPropertyChangedSignal("Volume"):Connect(function()
			if sound:GetAttribute("VolumeLockdown") then return end
			sound:SetAttribute("OriginalVolume", sound.Volume)
			sound:SetAttribute("VolumeLockdown", true)
			sound.Volume = sound.Volume * GlobalVolumeScale
			sound:SetAttribute("VolumeLockdown", nil)
		end)
	end

	sound:SetAttribute("VolumeLockdown", true)
	sound.Volume = sound:GetAttribute("OriginalVolume") * GlobalVolumeScale
	sound:SetAttribute("VolumeLockdown", nil)
end

local function ApplyGlobalVolumeMatrix()
	for _, desc in ipairs(game:GetDescendants()) do
		pcall(ManageSoundInstance, desc)
	end
end

game.DescendantAdded:Connect(function(desc)
	pcall(function()
		if desc:IsA("Sound") then
			task.wait()
			ManageSoundInstance(desc)
		end
	end)
end)

-- ==========================================
-- INTERFACE RENDERING UTILITIES
-- ==========================================
local function applyBlackOutline(element, thickness)
	local s = element:FindFirstChild("MainStroke") or Instance.new("UIStroke")
	s.Name = "MainStroke"
	s.Thickness = thickness or 3
	s.Color = Color3.new(0, 0, 0)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Default for frames/bars
	if element:IsA("TextLabel") or element:IsA("TextButton") then
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	end
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = element
	return s
end

local function applyInternalGradient(element, colorSequence)
	local grad = element:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	grad.Color = colorSequence
	grad.Rotation = 90
	grad.Parent = element
end

local function createGlassFrame(name, size, pos, parent, noBackground)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = THEME.BLACK
	f.BackgroundTransparency = noBackground and 1 or 0.1
	f.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = f

	if not noBackground then
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = THEME.WHITE
		stroke.Transparency = 0.8
		stroke.Parent = f
		table.insert(RainbowElements, stroke)

		local innerGradient = Instance.new("UIGradient")
		innerGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 55)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 25))
		})
		innerGradient.Rotation = 45
		innerGradient.Parent = f
	end

	return f
end

local function createProgressBar(barName, barColorSequence, iconText, order, frameParent)
	local icon = Instance.new("TextLabel")
	icon.Name = barName .. "Icon"
	icon.Size = UDim2.fromOffset(20, 14)
	icon.Position = UDim2.new(0, 10, 0, 10 + ((order - 1) * 22))
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBlack
	icon.Text = iconText
	icon.TextSize = 14
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.TextYAlignment = Enum.TextYAlignment.Center
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.Parent = frameParent
	applyBlackOutline(icon, 2)
	applyInternalGradient(icon, barColorSequence)

	local fillContainer = Instance.new("Frame")
	fillContainer.Name = barName .. "BG"
	fillContainer.Size = UDim2.new(1, -45, 0, 14)
	fillContainer.Position = UDim2.new(0, 35, 0, 10 + ((order - 1) * 22))
	fillContainer.BackgroundTransparency = 1 -- NO BACKGROUND
	fillContainer.BorderSizePixel = 0
	fillContainer.Parent = frameParent

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = fillContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = fill
	
	applyBlackOutline(fill, 2)
	applyInternalGradient(fill, barColorSequence)

	return fill
end

-- ==========================================
-- 1. COIN HUD MODULE
-- ==========================================
local function SetupCoinHUD()
	local function hide()
		local oldGui = playerGui:FindFirstChild(" Coin ui")
		if oldGui then oldGui.Enabled = false end
	end
	hide()
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == " Coin ui" then child.Enabled = false end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "ModernCoinHUD"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	table.insert(MainGameHUDs, gui)

	local container = createGlassFrame("CoinContainer", UDim2.fromOffset(200, 55), UDim2.new(0, 20, 1, -150), gui, true)

	local icon = Instance.new("ImageLabel")
	icon.Name = "CoinIcon"
	icon.Size = UDim2.fromOffset(45, 45)
	icon.Position = UDim2.new(0, 15, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://117582891502895"
	icon.Parent = container

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 55, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 28
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "0"
	label.Parent = container
	applyBlackOutline(label, 3)
	applyInternalGradient(label, THEME.COIN_GRADIENT)

	local plusButton = Instance.new("TextButton")
	plusButton.Name = "PlusButton"
	plusButton.Size = UDim2.fromOffset(28, 28)
	plusButton.Position = UDim2.new(1, -12, 0.5, 0) -- Centered
	plusButton.AnchorPoint = Vector2.new(1, 0.5)
	plusButton.BackgroundColor3 = THEME.GOLD
	plusButton.Text = "+"
	plusButton.TextColor3 = THEME.BLACK
	plusButton.Font = Enum.Font.GothamBlack
	plusButton.TextSize = 24
	plusButton.AutoButtonColor = true
	plusButton.Parent = container
	
	local plusCorner = Instance.new("UICorner")
	plusCorner.CornerRadius = UDim.new(0, 16) -- Much more rounded (total bubbliness)
	plusCorner.Parent = plusButton
	
	local plusStroke = Instance.new("UIStroke")
	plusStroke.Thickness = 3
	plusStroke.Color = Color3.fromRGB(0, 0, 0) -- Matches THEME.SECONDARY/WHITE for "sticker" look
	plusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	plusStroke.Parent = plusButton
	
	local plusGrad = Instance.new("UIGradient")
	plusGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 220, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0))
	})
	plusGrad.Rotation = 90
	plusGrad.Parent = plusButton

	plusButton.MouseButton1Click:Connect(function()
		print("[UIPolisher] Plus button clicked, firing OpenCoinShopModule")
		require(ReplicatedStorage:WaitForChild("OpenCoinShopModule"))()
	end)

	local function update(val)
		label.Text = tostring(player:GetAttribute("Coins") or 0)
		applyInternalGradient(label, THEME.COIN_GRADIENT) -- Ensure gradient persists after text updates
		TweenService:Create(container, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(220, 65)}):Play()
		task.wait(0.15)
		TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = UDim2.fromOffset(200, 55)}):Play()
	end

	player:GetAttributeChangedSignal("Coins"):Connect(update)
	label.Text = tostring(player:GetAttribute("Coins") or 0)
end

-- ==========================================
-- 2. TIMER HUD MODULE
-- ==========================================
local function SetupTimerHUD()
	local function hide()
		local oldGui = playerGui:FindFirstChild("RoundGui")
		if oldGui then oldGui.Enabled = false end
	end
	hide()
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "RoundGui" then child.Enabled = false end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "ModernTimerHUD"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	table.insert(MainGameHUDs, gui)

	local container = createGlassFrame("TimerContainer", UDim2.fromOffset(400, 60), UDim2.new(0.5, 0, 0, 25), gui, true)
	container.AnchorPoint = Vector2.new(0.5, 0)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 26
	label.Text = "WAITING..."
	label.Parent = container
	applyBlackOutline(label, 3)
	applyInternalGradient(label, THEME.MATCH_GRADIENT)

	local status = ReplicatedStorage:WaitForChild("Stat", 2)
	if status then
		status.Changed:Connect(function()
			label.Text = status.Value:upper()
		end)
		label.Text = status.Value:upper()
	else
		label.Text = "SYSTEM ACTIVE"
	end
end

-- ==========================================
-- 3. VITALS HUD MODULE
-- ==========================================
local function SetupVitalsHUD()
	for _, oldName in ipairs({"DashUI", "DashGui", "AbilityUI", "AbilityGui", "HealthGui"}) do
		local old = playerGui:FindFirstChild(oldName)
		if old then old.Enabled = false end
	end
	playerGui.ChildAdded:Connect(function(child)
		if table.find({"DashUI", "DashGui", "AbilityUI", "AbilityGui", "HealthGui"}, child.Name) then
			child.Enabled = false
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "ModernVitalsHUD"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	table.insert(MainGameHUDs, gui)

	local coreContainer = createGlassFrame("VitalsContainer", UDim2.fromOffset(200, 65), UDim2.new(0, 20, 1, -85), gui, true)

	local dashBar = createProgressBar("Dash", THEME.DASH_GRADIENT, "⚡", 1, coreContainer)
	local healthBar = createProgressBar("Health", THEME.HEALTH_GRADIENT, "❤️", 2, coreContainer)

	local function bindCharacterVitals(char)
		local hum = char:WaitForChild("Humanoid", 3) or char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		local function sync()
			local targetRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
			TweenService:Create(healthBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(targetRatio, 0, 1, 0)}):Play()
		end

		hum.HealthChanged:Connect(sync)
		hum:GetPropertyChangedSignal("MaxHealth"):Connect(sync)
		sync()
	end

	if player.Character then
		task.spawn(bindCharacterVitals, player.Character)
	end
	player.CharacterAdded:Connect(bindCharacterVitals)

	local lastDashInteraction = 0
	local baseDashCooldown = 3.87

	local function processDashVisualTrigger()
		lastDashInteraction = os.clock()
		dashBar.Size = UDim2.new(0, 0, 1, 0)

		local activeCooldown = player:GetAttribute("DashRegenTime") or player:GetAttribute("DashCooldown") or baseDashCooldown
		TweenService:Create(dashBar, TweenInfo.new(activeCooldown, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}):Play()
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Q then
			local activeCooldown = player:GetAttribute("DashRegenTime") or player:GetAttribute("DashCooldown") or baseDashCooldown
			if os.clock() - lastDashInteraction >= activeCooldown then
				processDashVisualTrigger()
			end
		end
	end)

	player.AttributeChanged:Connect(function(attribute)
		if attribute == "CurrentDashes" or attribute == "DashCount" then
			local max = player:GetAttribute("MaxDashes") or 1
			local current = player:GetAttribute("CurrentDashes") or 0
			if current < max then
				processDashVisualTrigger()
			else
				TweenService:Create(dashBar, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 1, 0)}):Play()
			end
		end
	end)
end

-- ==========================================
-- 4. SPECTATE SYSTEM MODULE
-- ==========================================
local function SetupSpectateSystem()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ModernSpectateUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui
	table.insert(MainGameHUDs, gui)

	local spectateToggle = Instance.new("ImageButton")
	spectateToggle.Name = "SpectateToggle"
	spectateToggle.Size = UDim2.fromOffset(65, 65)
	spectateToggle.Position = UDim2.new(0, 10, 0.5, 110) -- Moved down to avoid overlap
	spectateToggle.BackgroundColor3 = THEME.SPECTATE_BLUE
	spectateToggle.Image = "rbxassetid://131012605615689" -- Eye Icon
	spectateToggle.Visible = false
	spectateToggle.Parent = gui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 12)
	toggleCorner.Parent = spectateToggle

	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Thickness = 3
	toggleStroke.Color = THEME.WHITE
	toggleStroke.Parent = spectateToggle

	spectateToggle.MouseEnter:Connect(function()
		TweenService:Create(spectateToggle, TweenInfo.new(0.2), {Size = UDim2.fromOffset(72, 72), BackgroundColor3 = Color3.fromRGB(80, 200, 255)}):Play()
	end)

	spectateToggle.MouseLeave:Connect(function()
		TweenService:Create(spectateToggle, TweenInfo.new(0.2), {Size = UDim2.fromOffset(65, 65), BackgroundColor3 = THEME.SPECTATE_BLUE}):Play()
	end)

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 150)
	mainFrame.Position = UDim2.new(0.5, -250, 1, 180)
	mainFrame.BackgroundColor3 = THEME.BLACK
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.Visible = false
	mainFrame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 24)
	corner.Parent = mainFrame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Thickness = 4
	frameStroke.Color = THEME.SPECTATE_BLUE
	frameStroke.Transparency = 0.4
	frameStroke.Parent = mainFrame

	local frameGrad = Instance.new("UIGradient")
	frameGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 70)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 35))
	})
	frameGrad.Rotation = 45
	frameGrad.Parent = mainFrame

	local detailsFrame = Instance.new("Frame")
	detailsFrame.Name = "DetailsPanel"
	detailsFrame.Size = UDim2.new(1, -40, 1, -40)
	detailsFrame.Position = UDim2.fromOffset(20, 15)
	detailsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	detailsFrame.BackgroundTransparency = 0.5
	detailsFrame.Parent = mainFrame

	local detailsCorner = Instance.new("UICorner")
	detailsCorner.CornerRadius = UDim.new(0, 15)
	detailsCorner.Parent = detailsFrame

	local playerInfo = Instance.new("Frame")
	playerInfo.Name = "PlayerInfo"
	playerInfo.Size = UDim2.new(1, 0, 1, 0)
	playerInfo.BackgroundTransparency = 1
	playerInfo.Parent = detailsFrame

	local avatarIcon = Instance.new("ImageLabel")
	avatarIcon.Name = "Avatar"
	avatarIcon.Size = UDim2.new(0, 65, 0, 65)
	avatarIcon.Position = UDim2.new(0, 15, 0.5, -32)
	avatarIcon.BackgroundColor3 = THEME.BLACK
	avatarIcon.BackgroundTransparency = 0.3
	avatarIcon.Image = ""
	avatarIcon.Parent = playerInfo

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 12)
	avatarCorner.Parent = avatarIcon

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Thickness = 2
	avatarStroke.Color = THEME.WHITE
	avatarStroke.Transparency = 0.5
	avatarStroke.Parent = avatarIcon

	local playerName = Instance.new("TextLabel")
	playerName.Name = "PlayerName"
	playerName.Size = UDim2.new(1, -220, 0, 30)
	playerName.Position = UDim2.new(0, 95, 0.2, -2)
	playerName.BackgroundTransparency = 1
	playerName.Font = Enum.Font.FredokaOne
	playerName.Text = "NONE"
	playerName.TextColor3 = THEME.WHITE
	playerName.TextSize = 24
	playerName.TextXAlignment = Enum.TextXAlignment.Left
	playerName.Parent = playerInfo
	playerName.BorderSizePixel = 0
	applyBlackOutline(playerName, 3)
	applyInternalGradient(playerName, THEME.MATCH_GRADIENT)

	local healthContainer = Instance.new("Frame")
	healthContainer.Name = "HealthContainer"
	healthContainer.Size = UDim2.new(1, -220, 0, 12)
	healthContainer.Position = UDim2.new(0, 95, 0.6, 2)
	healthContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	healthContainer.Parent = playerInfo

	local healthCorner = Instance.new("UICorner")
	healthCorner.CornerRadius = UDim.new(1, 0)
	healthCorner.Parent = healthContainer

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	healthBar.Parent = healthContainer

	local healthCorner2 = Instance.new("UICorner")
	healthCorner2.CornerRadius = UDim.new(1, 0)
	healthCorner2.Parent = healthBar

	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.Size = UDim2.new(0, 110, 1, 0)
	controls.Position = UDim2.new(1, -125, 0, 0)
	controls.BackgroundTransparency = 1
	controls.Parent = playerInfo

	local function createControlBtn(name, text, pos)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0, 50, 0, 50)
		btn.Position = pos
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		btn.BackgroundTransparency = 0.2
		btn.Font = Enum.Font.FredokaOne
		btn.Text = text
		btn.TextColor3 = THEME.WHITE
		btn.TextSize = 28
		btn.Parent = controls

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 12)
		bCorner.Parent = btn

		local bStroke = Instance.new("UIStroke")
		bStroke.Thickness = 2
		bStroke.Color = THEME.SECONDARY
		bStroke.Transparency = 0.6
		bStroke.Parent = btn
		table.insert(RainbowElements, bStroke)

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
			TweenService:Create(bStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}):Play()
			TweenService:Create(bStroke, TweenInfo.new(0.2), {Transparency = 0.6}):Play()
		end)

		return btn
	end

	local prevBtn = createControlBtn("Prev", "<", UDim2.new(0, 0, 0.5, -25))
	local nextBtn = createControlBtn("Next", ">", UDim2.new(1, -50, 0.5, -25))

	local spectatorCountLabel = Instance.new("TextLabel")
	spectatorCountLabel.Size = UDim2.new(1, 0, 0, 20)
	spectatorCountLabel.Position = UDim2.new(0, 25, 1, -22)
	spectatorCountLabel.BackgroundTransparency = 1
	spectatorCountLabel.Font = Enum.Font.SourceSansBold
	spectatorCountLabel.Text = "👀 0 SPECTATORS"
	spectatorCountLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
	spectatorCountLabel.TextSize = 14
	spectatorCountLabel.TextXAlignment = Enum.TextXAlignment.Left
	spectatorCountLabel.Parent = mainFrame

	local isSpectating = false
	local spectateIndex = 1
	local targetPlayer = nil

	local function getIngamePlayers()
		local ingame = {}
		local ingameFolder = Workspace:FindFirstChild("Ingame")
		if ingameFolder then
			for _, character in ipairs(ingameFolder:GetChildren()) do
				local p = Players:GetPlayerFromCharacter(character)
				if p and p ~= player and p.Character and p.Character:FindFirstChildOfClass("Humanoid") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
					table.insert(ingame, p)
				end
			end
		end
		
		-- Sort by name or ID to keep index stable
		table.sort(ingame, function(a, b) return a.Name < b.Name end)
		return ingame
	end

	local function stopSpectating()
		if not isSpectating then return end
		isSpectating = false
		targetPlayer = nil
		if SpectateSync then
			SpectateSync:FireServer(nil)
		end

		local currentCamera = Workspace.CurrentCamera
		if currentCamera then
			currentCamera.CameraType = Enum.CameraType.Custom
			if player.Character then
				currentCamera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid") or player.Character
			end
		end

		TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -250, 1, 180)}):Play()
		task.delay(0.4, function()
			if not isSpectating then
				mainFrame.Visible = false
			end
		end)
	end

	local function updateSpectate()
		if not isSpectating then return end

		local ingame = getIngamePlayers()
		if #ingame == 0 then
			stopSpectating()
			return
		end

		-- Clamp or wrap index
		if spectateIndex > #ingame then spectateIndex = 1 end
		if spectateIndex < 1 then spectateIndex = #ingame end

		local newTarget = ingame[spectateIndex]
		if not newTarget or not newTarget.Character or not newTarget.Character:FindFirstChildOfClass("Humanoid") then
			-- Target invalid, remove and retry
			table.remove(ingame, spectateIndex)
			if #ingame > 0 then
				updateSpectate()
			else
				stopSpectating()
			end
			return
		end

		targetPlayer = newTarget
		playerName.Text = targetPlayer.DisplayName:upper()
		avatarIcon.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", targetPlayer.UserId)

		local currentCamera = Workspace.CurrentCamera
		if currentCamera then
			currentCamera.CameraType = Enum.CameraType.Custom
			currentCamera.CameraSubject = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		end

		if SpectateSync then
			SpectateSync:FireServer(newTarget)
		end

		playerName.TextTransparency = 1
		TweenService:Create(playerName, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
	end

	local currentCamera = Workspace.CurrentCamera
	local function manageCameraConnection(enable)
		if cameraConn then cameraConn:Disconnect() cameraConn = nil end
		if enable then
			cameraConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
				if isSpectating and targetPlayer and targetPlayer.Character then
					local hum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
					local currentCamera = Workspace.CurrentCamera
					if currentCamera and hum then
						currentCamera.CameraType = Enum.CameraType.Custom
						currentCamera.CameraSubject = hum
					end
				end
			end)
		end
	end
	
	manageCameraConnection(true)

	player.CharacterAdded:Connect(function()
		if isSpectating then
			task.wait(0.1) -- Wait for camera to initialize
			updateSpectate()
		end
	end)

	spectateToggle.MouseButton1Click:Connect(function()
		if not isSpectating then
			local ingame = getIngamePlayers()
			if #ingame == 0 then return end
			isSpectating = true
			spectateIndex = 1
			mainFrame.Visible = true
			mainFrame.Position = UDim2.new(0.5, -250, 1, 180)
			TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -250, 1, -175)}):Play()
			updateSpectate()
		else
			stopSpectating()
		end
	end)

	nextBtn.MouseButton1Click:Connect(function()
		local ingame = getIngamePlayers()
		if #ingame > 0 then
			spectateIndex = (spectateIndex % #ingame) + 1
			updateSpectate()
		else
			stopSpectating()
		end
	end)

	prevBtn.MouseButton1Click:Connect(function()
		local ingame = getIngamePlayers()
		if #ingame > 0 then
			spectateIndex = (spectateIndex - 2 + #ingame) % #ingame + 1
			updateSpectate()
		else
			stopSpectating()
		end
	end)

	RunService.RenderStepped:Connect(function()
		local currentCamera = Workspace.CurrentCamera
		if not currentCamera then return end

		local ingameFolder = Workspace:FindFirstChild("Ingame")
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		
		local isIngame = character and character.Parent == ingameFolder
		local matchActive = Workspace:GetAttribute("MatchActive") == true
		local dead = not character or not humanoid or humanoid.Health <= 0

		local canSpectate = (not isIngame and matchActive) or (isIngame and dead)

		if isSpectating then
			spectateToggle.Visible = true
		else
			spectateToggle.Visible = canSpectate
		end

		if isSpectating then
			if not canSpectate then
				stopSpectating()
				return
			end
			
			if not targetPlayer or not targetPlayer.Character or targetPlayer.Character.Parent ~= ingameFolder then
				updateSpectate()
				return
			end

			local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
			if not targetHum or targetHum.Health <= 0 then
				updateSpectate()
				return
			end

			if currentCamera.CameraType ~= Enum.CameraType.Custom then
				currentCamera.CameraType = Enum.CameraType.Custom
			end
			if currentCamera.CameraSubject ~= targetHum then
				currentCamera.CameraSubject = targetHum
			end

			local healthPercent = math.clamp(targetHum.Health / targetHum.MaxHealth, 0, 1)
			healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
			healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			applyInternalGradient(healthBar, THEME.HEALTH_GRADIENT)

			local sCount = targetPlayer:GetAttribute("SpectatorCount") or 0
			spectatorCountLabel.Text = string.format("👀 %d SPECTATORS", sCount)
		end
	end)
end

-- ==========================================
-- 5. PLAYERS REMAINING HUD MODULE
-- ==========================================
local function SetupPlayersRemainingHUD()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ModernPlayersRemainingHUD"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	table.insert(MainGameHUDs, gui)

	local container = createGlassFrame("RemainingContainer", UDim2.fromOffset(130, 55), UDim2.new(1, -150, 1, -85), gui, true)
	container.Visible = false

	local icon = Instance.new("TextLabel")
	icon.Name = "PlayersIcon"
	icon.Size = UDim2.fromOffset(40, 45)
	icon.Position = UDim2.new(0, 15, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.FredokaOne
	icon.Text = "👤"
	icon.TextSize = 26
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Parent = container
	applyBlackOutline(icon, 2)
	applyInternalGradient(icon, THEME.MATCH_GRADIENT)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 60, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 28
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "0"
	label.Parent = container
	applyBlackOutline(label, 3)
	applyInternalGradient(label, THEME.MATCH_GRADIENT)

	local lastCount = -1
	RunService.PostSimulation:Connect(function()
		local matchActive = Workspace:GetAttribute("MatchActive") == true
		local ingameFolder = Workspace:FindFirstChild("Ingame")

		if matchActive and ingameFolder then
			local currentCount = #ingameFolder:GetChildren()
			if currentCount > 0 then
				container.Visible = true
				if currentCount ~= lastCount then
					lastCount = currentCount
					label.Text = tostring(currentCount)
					TweenService:Create(container, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(145, 63)}):Play()
					task.wait(0.12)
					TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Safe), {Size = UDim2.fromOffset(130, 55)}):Play()
				end
			else
				container.Visible = false
			end
		else
			container.Visible = false
			lastCount = -1
		end
	end)
end

-- ==========================================
-- 6. DASHBOARD SETTINGS SYSTEM
-- ==========================================
local function SetupSettingsSystem()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ModernSettingsUI"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local toggleBtn = Instance.new("ImageButton")
	toggleBtn.Name = "SettingsToggle"
	toggleBtn.Size = UDim2.fromOffset(65, 65)
	toggleBtn.Position = UDim2.new(0, 10, 0.5, -35)
	toggleBtn.BackgroundColor3 = THEME.PRIMARY
	toggleBtn.Image = "rbxassetid://119570973950437"
	toggleBtn.Parent = gui

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = toggleBtn

	local btnStroke = applyBlackOutline(toggleBtn, 2)
	btnStroke.Color = THEME.WHITE
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	toggleBtn.MouseEnter:Connect(function()
		TweenService:Create(toggleBtn, TweenInfo.new(0.2), {Size = UDim2.fromOffset(72, 72), BackgroundColor3 = THEME.ACCENT}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = THEME.WHITE}):Play()
	end)

	toggleBtn.MouseLeave:Connect(function()
		TweenService:Create(toggleBtn, TweenInfo.new(0.2), {Size = UDim2.fromOffset(65, 65), BackgroundColor3 = THEME.PRIMARY}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = THEME.WHITE}):Play()
	end)

	local mainPanel = createGlassFrame("SettingsPanel", UDim2.fromScale(.55, .65), UDim2.new(0.5, 0, 1.5, 0), gui)
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.BackgroundColor3 = THEME.BLACK
	mainPanel.BackgroundTransparency = 0
	
	local panelStroke = applyBlackOutline(mainPanel, 2)
	panelStroke.Color = THEME.SURFACE_LIGHT
	panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	
	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 80)
	header.BackgroundColor3 = THEME.SURFACE
	header.BorderSizePixel = 0
	header.Parent = mainPanel
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	local panelTitle = Instance.new("TextLabel")
	panelTitle.Size = UDim2.new(0, 200, 1, 0)
	panelTitle.Position = UDim2.fromOffset(25, 0)
	panelTitle.BackgroundTransparency = 1
	panelTitle.Font = Enum.Font.GothamBlack
	panelTitle.Text = "SETTINGS"
	panelTitle.TextColor3 = THEME.WHITE
	panelTitle.TextSize = 20
	panelTitle.TextXAlignment = Enum.TextXAlignment.Left
	panelTitle.Parent = header
	
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(40, 40)
	closeBtn.Position = UDim2.new(1, -55, 0.5, -20)
	closeBtn.BackgroundColor3 = THEME.RED
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextColor3 = THEME.WHITE
	closeBtn.TextSize = 18
	closeBtn.Parent = header
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = closeBtn

	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, 0, 1, -80)
	contentArea.Position = UDim2.fromOffset(0, 80)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainPanel

	local containerLeft = Instance.new("Frame")
	containerLeft.Size = UDim2.new(0.5, -30, 1, -40)
	containerLeft.Position = UDim2.fromOffset(20, 20)
	containerLeft.BackgroundTransparency = 1
	containerLeft.Parent = contentArea

	local containerRight = Instance.new("Frame")
	containerRight.Size = UDim2.new(0.5, -30, 1, -40)
	containerRight.Position = UDim2.new(0.5, 10, 0, 20)
	containerRight.BackgroundTransparency = 1
	containerRight.Parent = contentArea

	local function createSliderRow(name, labelText, yPos, defaultValue, layoutParent, onUpdate)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 20)
		lbl.Position = UDim2.fromOffset(10, yPos)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.Text = labelText
		lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = layoutParent
		applyBlackOutline(lbl, 2)

		local track = Instance.new("TextButton")
		track.Name = name .. "Track"
		track.Size = UDim2.new(1, -20, 0, 10)
		track.Position = UDim2.fromOffset(10, yPos + 28)
		track.BackgroundColor3 = THEME.SURFACE
		track.Text = ""
		track.AutoButtonColor = false
		track.Parent = layoutParent
		applyBlackOutline(track, 1.5)

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(1, 0)
		trackCorner.Parent = track

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(defaultValue, 0, 1, 0)
		fill.BackgroundColor3 = THEME.SECONDARY
		fill.BorderSizePixel = 0
		fill.Parent = track

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = fill

		local knob = Instance.new("TextButton")
		knob.Size = UDim2.fromOffset(20, 20)
		knob.Position = UDim2.new(defaultValue, -10, 0.5, -10)
		knob.BackgroundColor3 = THEME.WHITE
		knob.Text = ""
		knob.Parent = track
		applyBlackOutline(knob, 2)

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(1, 0)
		knobCorner.Parent = knob

		local activeSliding = false

		local function update()
			local mLoc = UserInputService:GetMouseLocation()
			local ratio = math.clamp((mLoc.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			knob.Position = UDim2.new(ratio, -10, 0.5, -10)
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			onUpdate(ratio, lbl)
		end

		knob.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				activeSliding = true
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				activeSliding = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if activeSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				update()
			end
		end)

		track.MouseButton1Down:Connect(function()
			activeSliding = true
			update()
		end)
	end

	local function createToggleRow(labelText, yPos, layoutParent, onToggle)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -65, 0, 30)
		lbl.Position = UDim2.fromOffset(10, yPos)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.Text = labelText
		lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = layoutParent
		applyBlackOutline(lbl, 2)

		local tgl = Instance.new("TextButton")
		tgl.Size = UDim2.fromOffset(50, 28)
		tgl.Position = UDim2.new(1, -55, 0, yPos + 1)
		tgl.BackgroundColor3 = THEME.SURFACE
		tgl.Text = ""
		tgl.Parent = layoutParent
		applyBlackOutline(tgl, 2)

		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(1, 0)
		toggleCorner.Parent = tgl

		local thumb = Instance.new("Frame")
		thumb.Size = UDim2.fromOffset(22, 22)
		thumb.Position = UDim2.new(0, 3, 0.5, -11)
		thumb.BackgroundColor3 = THEME.WHITE
		thumb.Parent = tgl

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = UDim.new(1, 0)
		thumbCorner.Parent = thumb

		local state = false
		tgl.MouseButton1Click:Connect(function()
			state = not state
			if state then
				TweenService:Create(thumb, TweenInfo.new(0.15), {Position = UDim2.new(1, -25, 0.5, -11)}):Play()
				TweenService:Create(tgl, TweenInfo.new(0.15), {BackgroundColor3 = THEME.HEALTH}):Play()
			else
				TweenService:Create(thumb, TweenInfo.new(0.15), {Position = UDim2.new(0, 3, 0.5, -11)}):Play()
				TweenService:Create(tgl, TweenInfo.new(0.15), {BackgroundColor3 = THEME.SURFACE}):Play()
			end
			onToggle(state)
		end)
	end

	createSliderRow("Volume", "VOLUME: 100%", 10, 1.0, containerLeft, function(ratio, label)
		GlobalVolumeScale = ratio
		label.Text = "VOLUME: " .. math.round(ratio * 100) .. "%"
		ApplyGlobalVolumeMatrix()
	end)

	createSliderRow("FOV", "FIELD OF VIEW: 70°", 75, 0, containerLeft, function(ratio, label)
		local targetFOV = 70 + (ratio * 50)
		label.Text = "FIELD OF VIEW: " .. math.round(targetFOV) .. "°"
		local currentCamera = Workspace.CurrentCamera
		if currentCamera then
			currentCamera.FieldOfView = targetFOV
		end
	end)

	createToggleRow("RAINBOW UI THEME", 140, containerLeft, function(state)
		RainbowModeActive = state
	end)

	createToggleRow("LIGHT PERFORMANCE", 10, containerRight, function(state)
		if state then
			for _, desc in ipairs(Workspace:GetDescendants()) do
				if desc:IsA("ParticleEmitter") or desc:IsA("Smoke") or desc:IsA("Fire") or desc:IsA("Sparkles") then
					OriginalParticleStates[desc] = desc.Enabled
					desc.Enabled = false
				end
			end
		else
			for desc, oldEnabled in pairs(OriginalParticleStates) do
				if desc and desc.Parent then
					desc.Enabled = oldEnabled
				end
			end
			table.clear(OriginalParticleStates)
		end
	end)

	createToggleRow("ANTI-LAG EXTRA", 55, containerRight, function(state)
		if state then
			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("Texture") or v:IsA("Decal") then
					OriginalTextures[v] = v.Transparency
					v.Transparency = 1
				elseif v:IsA("BasePart") and not v:IsA("Terrain") then
					OriginalMaterials[v] = v.Material
					v.Material = Enum.Material.SmoothPlastic
				end
			end
		else
			for part, oldMat in pairs(OriginalMaterials) do
				if part and part.Parent then
					part.Material = oldMat
				end
			end
			for visual, oldTrans in pairs(OriginalTextures) do
				if visual and visual.Parent then
					visual.Transparency = oldTrans
				end
			end
			table.clear(OriginalMaterials)
			table.clear(OriginalTextures)
		end
	end)

	local panelOpen = false
	local function togglePanel()
		panelOpen = not panelOpen
		if panelOpen then
			MainGameHUDs[1].Enabled = false -- Hide some HUDs when settings open to match shop behavior
			TweenService:Create(mainPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
		else
			MainGameHUDs[1].Enabled = true
			TweenService:Create(mainPanel, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 1.5)}):Play()
		end
	end

	toggleBtn.MouseButton1Click:Connect(togglePanel)
	closeBtn.MouseButton1Click:Connect(togglePanel)
end

-- ==========================================
-- LIVE REPETITIVE VFX & SYSTEM TICK ROUTINES
-- ==========================================
RunService.RenderStepped:Connect(function()
	if RainbowModeActive then
		local hue = (os.clock() * 0.15) % 1
		local rainbowColor = Color3.fromHSV(hue, 0.8, 1)
		for _, uiElement in ipairs(RainbowElements) do
			if uiElement and uiElement.Parent then
				uiElement.Color = rainbowColor
			end
		end
	else
		for _, uiElement in ipairs(RainbowElements) do
			if uiElement and uiElement.Parent then
				if uiElement.Parent.Name == "SettingsToggle" or uiElement.Parent.Name == "SettingsPanel" then
					uiElement.Color = THEME.PRIMARY
				elseif uiElement.Parent.Name == "SpectateToggle" or uiElement.Parent.Name == "MainFrame" then
					uiElement.Color = THEME.SPECTATE_BLUE
				else
					uiElement.Color = THEME.SECONDARY
				end
			end
		end
	end
end)

-- ==========================================
-- MASTER SYSTEM LOAD MATRIX
-- ==========================================
task.spawn(SetupCoinHUD)
task.spawn(SetupTimerHUD)
task.spawn(SetupVitalsHUD)
task.spawn(SetupSpectateSystem)
task.spawn(SetupPlayersRemainingHUD)
task.spawn(SetupSettingsSystem)
task.spawn(ApplyGlobalVolumeMatrix)

-- ==========================================
-- BUTTON SOUND EFFECTS
-- ==========================================
local function ApplyButtonSounds(btn, clickId, hoverId)
	if not btn:IsA("GuiButton") then return end

	local clickSound = Instance.new("Sound")
	clickSound.SoundId = clickId or "rbxassetid://459506692" -- Responsive click
	clickSound.Volume = 0.4
	clickSound.Parent = btn

	local hoverSound = Instance.new("Sound")
	hoverSound.SoundId = hoverId or "rbxassetid://9086050352" -- Subtle hover tick
	hoverSound.Volume = 0.2
	hoverSound.Parent = btn

	btn.MouseEnter:Connect(function()
		hoverSound:Play()
	end)

	btn.MouseButton1Click:Connect(function()
		clickSound:Play()
	end)
end

-- Apply to existing buttons in Shop and Dialogue
task.delay(1, function()
	local shopUI = playerGui:FindFirstChild("ShopUI")
	if shopUI then
		local shopItems = shopUI:FindFirstChild("ImageLabel") and shopUI.ImageLabel:FindFirstChild("Items")
		if shopItems then
			local silver = shopItems:FindFirstChild("SilverButton")
			local nature = shopItems:FindFirstChild("NatureButton")
			if silver then ApplyButtonSounds(silver) end
			if nature then ApplyButtonSounds(nature) end
		end
		local close = shopUI.ImageLabel:FindFirstChild("CloseButton")
		if close then ApplyButtonSounds(close) end
	end

	local diagGui = playerGui:FindFirstChild("dialogueGui")
	if diagGui then
		local diagFrame = diagGui:FindFirstChild("Frame")
		if diagFrame then
			local yes = diagFrame:FindFirstChild("YESButton")
			local no = diagFrame:FindFirstChild("NOButton")
			if yes then ApplyButtonSounds(yes) end
			if no then ApplyButtonSounds(no) end
		end
	end

	-- Also apply to Settings toggle
	local settingsUI = playerGui:FindFirstChild("ModernSettingsUI")
	if settingsUI then
		local toggle = settingsUI:FindFirstChild("SettingsToggle")
		if toggle then ApplyButtonSounds(toggle) end
	end
end)

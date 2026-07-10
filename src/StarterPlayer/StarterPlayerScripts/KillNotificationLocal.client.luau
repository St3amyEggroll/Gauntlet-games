local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UITheme = require(ReplicatedStorage:WaitForChild("UITheme"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local KillEvent = ReplicatedStorage:WaitForChild("KillEvent")

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KillNotificationGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Container for notifications
local container = Instance.new("Frame")
container.Name = "Notifications"
container.Size = UDim2.new(0.4, 0, 0.4, 0)
container.Position = UDim2.new(0.5, 0, 0.25, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Parent = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

local function createKillNotification(killerName, victimName)
	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.Size = UDim2.new(0, 0, 0, 40) 
	notification.AutomaticSize = Enum.AutomaticSize.X -- Dynamically resizes background width
	notification.BackgroundColor3 = UITheme.THEME.BG
	notification.BackgroundTransparency = 0.1
	notification.BorderSizePixel = 0
	notification.ClipsDescendants = false
	notification.Parent = container

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0
	uiScale.Parent = notification

	UITheme.corner(notification, 10)
	UITheme.outline(notification, 3)
	local uiStroke = UITheme.addNeonGlow(notification, UITheme.THEME.MAGENTA, 2)

	-- Content padding container
	local content = Instance.new("Frame")
	content.Size = UDim2.new(0, 0, 1, 0)
	content.AutomaticSize = Enum.AutomaticSize.X -- Forces content container to size based on labels
	content.BackgroundTransparency = 1
	content.Parent = notification

	-- Added padding component so text isn't pressed against the edges
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingLeft = UDim.new(0, 15)
	uiPadding.PaddingRight = UDim.new(0, 15)
	uiPadding.Parent = content

	local textLayout = Instance.new("UIListLayout")
	textLayout.FillDirection = Enum.FillDirection.Horizontal
	textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	textLayout.Padding = UDim.new(0, 6)
	textLayout.Parent = content

	local function createLabel(text, color)
		local label = Instance.new("TextLabel")
		label.Text = text
		label.TextColor3 = color
		label.Font = UITheme.THEME.FONT
		label.TextSize = 16
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(0, 0, 1, 0)
		label.AutomaticSize = Enum.AutomaticSize.X
		UITheme.outline(label, 2)
		return label
	end

	-- Color coding
	local killerColor = (killerName == player.Name) and UITheme.THEME.WHITE or UITheme.THEME.YELLOW
	local victimColor = (victimName == player.Name) and UITheme.THEME.RED or Color3.fromRGB(255, 120, 120)
	local actionColor = UITheme.THEME.TEXT_DIM

	local killerLabel = createLabel(killerName, killerColor, true)
	killerLabel.Parent = content

	local actionLabel = createLabel("ELIMINATED", actionColor, false)
	actionLabel.TextSize = 18
	actionLabel.Parent = content

	local victimLabel = createLabel(victimName, victimColor, true)
	victimLabel.Parent = content

	-- Optional aesthetic flair: Make border gold/solid if LocalPlayer did the eliminating
	if killerName == player.Name then
		uiStroke.Color = UITheme.THEME.GOLD
		uiStroke.Transparency = 0
	end

	-- Animation Sequence
	-- 1. Pop In using UIScale
	TweenService:Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	}):Play()

	-- 2. Wait
	task.delay(3, function()
		-- 3. Fade Out and Shrink
		local fadeTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 0, 0) 
		})

		TweenService:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Scale = 0
		}):Play()

		for _, child in notification:GetDescendants() do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
				if child:FindFirstChild("Shadow") then
					TweenService:Create(child.Shadow, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
				end
			elseif child:IsA("UIStroke") then
				TweenService:Create(child, TweenInfo.new(0.2), {Transparency = 1}):Play()
			end
		end

		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			notification:Destroy()
		end)
	end)
end

KillEvent.OnClientEvent:Connect(function(killerName, victimName)
	createKillNotification(killerName, victimName)
end)
--!strict
-- Shared Simulator Store UI theme — thick black outlines, neon glows, glossy gradients
local UITheme = {}

UITheme.THEME = {
	BG = Color3.fromRGB(15, 12, 20), -- Deeper Purple-Black
	PANEL = Color3.fromRGB(22, 18, 28),
	SURFACE = Color3.fromRGB(35, 28, 45),
	SURFACE_LIGHT = Color3.fromRGB(55, 45, 65),

	CYAN = Color3.fromRGB(180, 80, 255), -- Electric Purple
	MAGENTA = Color3.fromRGB(255, 60, 180),
	LIME = Color3.fromRGB(80, 255, 120),
	YELLOW = Color3.fromRGB(255, 220, 40),
	GOLD = Color3.fromRGB(255, 200, 50),
	BLUE = Color3.fromRGB(100, 140, 255),
	ORANGE = Color3.fromRGB(255, 120, 40),
	GREEN = Color3.fromRGB(60, 220, 80),
	RED = Color3.fromRGB(230, 50, 50),
	WHITE = Color3.fromRGB(255, 255, 255),
	BLACK = Color3.fromRGB(0, 0, 0),
	TEXT_DIM = Color3.fromRGB(160, 165, 180),

	OUTLINE = 4,
	FONT = Enum.Font.GothamBlack,
	FONT_BOLD = Enum.Font.GothamBold,
	FONT_MED = Enum.Font.GothamMedium,

	MESH_IMAGE = "rbxassetid://12603411036",

	HEADER_GRADIENT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 100, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 40, 220)),
	}),
	COIN_GRADIENT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0)),
	}),
	HEALTH_GRADIENT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 180, 80)),
	}),
	DASH_GRADIENT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0)),
	}),
	MATCH_GRADIENT = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 180, 220)),
	}),
	YELLOW_TITLE = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0)),
	}),
}

local T = UITheme.THEME

function UITheme.corner(obj: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
	return c
end

function UITheme.outline(element: GuiObject, thickness: number?, color: Color3?, mode: Enum.ApplyStrokeMode?)
	local s = element:FindFirstChild("MainStroke") or Instance.new("UIStroke")
	s.Name = "MainStroke"
	s.Thickness = thickness or T.OUTLINE
	s.Color = color or T.BLACK
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
	if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
		s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Contextual
	end
	s.Parent = element
	return s
end

function UITheme.textGradient(element: GuiObject, colorSequence: ColorSequence?)
	local grad = element:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	grad.Color = colorSequence or T.MATCH_GRADIENT
	grad.Rotation = 90
	grad.Parent = element
	return grad
end

function UITheme.addMeshBackground(parent: GuiObject, tint: Color3?)
	local bgContainer = Instance.new("Frame")
	bgContainer.Name = "MeshBG"
	bgContainer.Size = UDim2.fromScale(1, 1)
	bgContainer.BackgroundTransparency = 1
	bgContainer.ClipsDescendants = true
	bgContainer.ZIndex = 0
	bgContainer.Parent = parent

	local mesh = Instance.new("ImageLabel")
	mesh.Size = UDim2.fromScale(2.2, 2.2)
	mesh.Position = UDim2.fromScale(-0.6, -0.6)
	mesh.BackgroundTransparency = 1
	mesh.Image = T.MESH_IMAGE
	mesh.ImageTransparency = 0.72
	mesh.ImageColor3 = tint or T.CYAN
	mesh.ZIndex = 0
	mesh.Parent = bgContainer

	task.spawn(function()
		while mesh.Parent do
			local t = os.clock()
			mesh.Rotation = t * 3
			mesh.Position = UDim2.new(-0.6 + math.sin(t * 0.4) * 0.08, 0, -0.6 + math.cos(t * 0.4) * 0.08, 0)
			task.wait()
		end
	end)

	return bgContainer
end

function UITheme.addGlossShine(parent: GuiObject)
	local shine = Instance.new("Frame")
	shine.Name = "GlossShine"
	shine.Size = UDim2.new(1, 0, 0.45, 0)
	shine.BackgroundTransparency = 1
	shine.ZIndex = (parent.ZIndex or 1) + 1
	shine.Parent = parent

	local grad = Instance.new("UIGradient")
	grad.Rotation = -25
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.35, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	grad.Color = ColorSequence.new(T.WHITE)
	grad.Parent = shine

	return shine
end

function UITheme.addNeonGlow(parent: GuiObject, neonColor: Color3?, thickness: number?)
	local color = neonColor or T.CYAN
	local t = thickness or 3

	local outer = Instance.new("UIStroke")
	outer.Name = "NeonGlowOuter"
	outer.Thickness = t + 4
	outer.Color = color
	outer.Transparency = 0.65
	outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outer.Parent = parent

	local glow = Instance.new("UIStroke")
	glow.Name = "NeonGlow"
	glow.Thickness = t
	glow.Color = color
	glow.Transparency = 0.2
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Parent = parent
	return glow
end

function UITheme.addGoldCorners(parent: GuiObject)
	-- Removed gold corner brackets as requested
end

function UITheme.createPanel(name: string, size: UDim2, neonColor: Color3?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.BackgroundColor3 = T.BG
	f.BorderSizePixel = 0
	f.ClipsDescendants = false

	UITheme.corner(f, 16)
	UITheme.outline(f, T.OUTLINE)
	UITheme.addNeonGlow(f, neonColor or T.CYAN, 4)

	local panelGrad = Instance.new("UIGradient")
	panelGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 28, 45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 12, 20)),
	})
	panelGrad.Rotation = 90
	panelGrad.Parent = f

	UITheme.addMeshBackground(f, neonColor or T.CYAN)

	return f
end

function UITheme.createHUDBadge(name: string, size: UDim2, neonColor: Color3?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.BackgroundColor3 = T.BG
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 0.05

	UITheme.corner(f, 12)
	UITheme.outline(f, 4)
	UITheme.addNeonGlow(f, neonColor or T.CYAN, 2)

	local panelGrad = Instance.new("UIGradient")
	panelGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 28, 45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 12, 20)),
	})
	panelGrad.Rotation = 90
	panelGrad.Parent = f

	UITheme.addMeshBackground(f, neonColor or T.CYAN)

	return f
end

function UITheme.createTabHeader(parent: GuiObject, text: string, width: number?): TextLabel
	local tab = Instance.new("TextLabel")
	tab.Name = "TabHeader"
	tab.Size = UDim2.fromOffset(width or 160, 44)
	tab.Position = UDim2.new(0, 16, 0, -22)
	tab.BackgroundColor3 = T.CYAN
	tab.Font = T.FONT
	tab.Text = text
	tab.TextColor3 = T.WHITE
	tab.TextSize = 22
	tab.ZIndex = (parent.ZIndex or 1) + 3
	tab.Parent = parent

	UITheme.corner(tab, 10)
	UITheme.outline(tab, 4)
	UITheme.textGradient(tab, T.HEADER_GRADIENT)
	UITheme.addGlossShine(tab)

	return tab
end

function UITheme.createCloseButton(parent: GuiObject, onClick: (() -> ())?): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "CloseButton"
	btn.Size = UDim2.fromOffset(44, 44)
	btn.Position = UDim2.new(1, -12, 0, -12)
	btn.AnchorPoint = Vector2.new(1, 0)
	btn.BackgroundColor3 = T.RED
	btn.Font = T.FONT
	btn.Text = "X"
	btn.TextColor3 = T.WHITE
	btn.TextSize = 22
	btn.AutoButtonColor = false
	btn.ZIndex = (parent.ZIndex or 1) + 5
	btn.Parent = parent

	UITheme.corner(btn, 22)
	UITheme.outline(btn, 4)

	if onClick then
		btn.MouseButton1Click:Connect(onClick)
	end

	return btn
end

function UITheme.createActionButton(text: string, width: number?, height: number?, color: Color3?): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(width or 160, height or 44)
	btn.BackgroundColor3 = color or T.LIME
	btn.Font = T.FONT
	btn.Text = text
	btn.TextColor3 = T.WHITE
	btn.TextSize = 16
	btn.AutoButtonColor = false

	UITheme.corner(btn, 10)
	UITheme.outline(btn, 4)
	UITheme.textGradient(btn, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 255, 220)),
	}))
	UITheme.addGlossShine(btn)

	return btn
end

function UITheme.createSectionLabel(parent: GuiObject, text: string, yPos: number): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 28)
	lbl.Position = UDim2.new(0, 0, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.Font = T.FONT
	lbl.Text = "- " .. text .. " -"
	lbl.TextColor3 = T.WHITE
	lbl.TextSize = 16
	lbl.Parent = parent
	UITheme.outline(lbl, 3)
	return lbl
end

function UITheme.styleCard(card: GuiObject, accentColor: Color3?, bgColor: Color3?)
	if card:IsA("Frame") or card:IsA("TextButton") then
		card.BackgroundColor3 = bgColor or T.SURFACE
	end
	UITheme.corner(card, 14)
	UITheme.outline(card, 4)
	UITheme.addNeonGlow(card, accentColor or T.CYAN, 2)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, (bgColor or T.SURFACE):Lerp(T.WHITE, 0.08)),
		ColorSequenceKeypoint.new(1, (bgColor or T.SURFACE):Lerp(T.BLACK, 0.2)),
	})
	grad.Rotation = 90
	grad.Parent = card
end

function UITheme.styleOutlinedText(label: TextLabel, gradient: ColorSequence?)
	label.Font = T.FONT
	label.TextColor3 = T.WHITE
	UITheme.outline(label, 4)
	UITheme.textGradient(label, gradient or T.MATCH_GRADIENT)
end

function UITheme.applyHover(btn: GuiButton, scaleUp: number?)
	local TweenService = game:GetService("TweenService")
	local origSize = btn.Size
	local origColor = btn.BackgroundColor3
	local bump = scaleUp or 6

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(origSize.X.Scale, origSize.X.Offset + bump, origSize.Y.Scale, origSize.Y.Offset + bump),
			BackgroundColor3 = origColor:Lerp(T.WHITE, 0.15),
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = origSize,
			BackgroundColor3 = origColor,
		}):Play()
	end)
end

return UITheme

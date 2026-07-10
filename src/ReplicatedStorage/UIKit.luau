--!strict
-- UIKit — shared visual language for every interface in Gauntlet Games.
-- Panels, buttons, headers, sliders, toasts, motion presets, sounds and
-- responsive scaling all come from here so every screen looks like one game.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UIKit = {}

--========================================================
-- THEME TOKENS
--========================================================
UIKit.Theme = {
	-- Grounds
	BG_TOP = Color3.fromRGB(40, 46, 105),
	BG_BOTTOM = Color3.fromRGB(20, 23, 58),
	SURFACE_TOP = Color3.fromRGB(58, 66, 138),
	SURFACE_BOTTOM = Color3.fromRGB(33, 38, 88),
	STROKE = Color3.fromRGB(10, 10, 22),
	WHITE = Color3.fromRGB(255, 255, 255),
	TEXT = Color3.fromRGB(255, 255, 255),
	TEXT_DIM = Color3.fromRGB(178, 185, 220),

	-- Header bar
	HEADER_A = Color3.fromRGB(85, 208, 255),
	HEADER_B = Color3.fromRGB(63, 109, 255),

	-- Button families (top, bottom, text)
	LIME_A = Color3.fromRGB(182, 242, 60), LIME_B = Color3.fromRGB(79, 196, 36),
	BLUE_A = Color3.fromRGB(111, 216, 255), BLUE_B = Color3.fromRGB(47, 108, 255),
	RED_A = Color3.fromRGB(255, 141, 94), RED_B = Color3.fromRGB(224, 51, 31),
	GOLD_A = Color3.fromRGB(255, 215, 110), GOLD_B = Color3.fromRGB(216, 148, 0),
	PURPLE_A = Color3.fromRGB(200, 130, 255), PURPLE_B = Color3.fromRGB(122, 47, 216),
	GREY_A = Color3.fromRGB(139, 147, 168), GREY_B = Color3.fromRGB(74, 81, 100),
	ORANGE_A = Color3.fromRGB(255, 157, 77), ORANGE_B = Color3.fromRGB(224, 90, 30),

	GREEN = Color3.fromRGB(110, 235, 90),
	RED = Color3.fromRGB(235, 70, 60),
	GOLD = Color3.fromRGB(255, 205, 80),

	FONT = Enum.Font.FredokaOne,
	FONT_BOLD = Enum.Font.GothamBold,
	FONT_MED = Enum.Font.GothamMedium,

	OUTLINE = 3,
	RADIUS = 14,

	SHADOW_IMAGE = "rbxassetid://1316045217",
	COIN_ICON = "rbxassetid://18209599552",
}

UIKit.Rarity = {
	Common = Color3.fromRGB(140, 145, 155),
	Rare = Color3.fromRGB(0, 160, 255),
	Epic = Color3.fromRGB(165, 80, 255),
	Legendary = Color3.fromRGB(255, 170, 30),
	Mythic = Color3.fromRGB(255, 60, 90),
}
UIKit.RarityOrder = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }

local T = UIKit.Theme

--========================================================
-- SOUNDS (routed through settings attributes)
--========================================================
local SOUND_IDS = {
	Hover = "rbxassetid://10066936758",
	Click = "rbxassetid://6895079853",
	Open = "rbxassetid://6895079853",
	Buy = "rbxassetid://131886985", -- cash register
	Error = "rbxassetid://2390695935",
	Reward = "rbxassetid://17458534837",
	Tick = "rbxassetid://9083627113",
	Notify = "rbxassetid://4590657391",
}

local soundCache: { [string]: Sound } = {}
local player = Players.LocalPlayer

local function sfxVolume(): number
	if not player then return 0.5 end
	local master = player:GetAttribute("Set_Master")
	local sfx = player:GetAttribute("Set_SFX")
	master = typeof(master) == "number" and master or 1
	sfx = typeof(sfx) == "number" and sfx or 1
	return 0.5 * master * sfx
end

function UIKit.play(name: string, pitch: number?)
	local id = SOUND_IDS[name]
	if not id then return end
	local s = soundCache[name]
	if not s or s.Parent == nil then
		s = Instance.new("Sound")
		s.SoundId = id
		s.Name = "UIKit_" .. name
		s:SetAttribute("UIKitSFX", true)
		s.Parent = SoundService
		soundCache[name] = s
	end
	s.Volume = sfxVolume()
	s.PlaybackSpeed = pitch or 1
	s:Play()
end

--========================================================
-- PRIMITIVES
--========================================================
function UIKit.corner(obj: GuiObject, r: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or T.RADIUS)
	c.Parent = obj
	return c
end

function UIKit.stroke(obj: GuiObject, thickness: number?, color: Color3?): UIStroke
	local s = Instance.new("UIStroke")
	s.Name = "KitStroke"
	s.Thickness = thickness or T.OUTLINE
	s.Color = color or T.STROKE
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

function UIKit.textStroke(obj: GuiObject, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Name = "KitTextStroke"
	s.Thickness = thickness or 2
	s.Color = T.STROKE
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = obj
	return s
end

function UIKit.vgradient(obj: GuiObject, top: Color3, bottom: Color3): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(1, bottom),
	})
	g.Rotation = 90
	g.Parent = obj
	return g
end

-- Soft drop shadow behind a panel
function UIKit.shadow(obj: GuiObject, transparency: number?)
	local img = Instance.new("ImageLabel")
	img.Name = "KitShadow"
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.new(0.5, 0, 0.5, 6)
	img.Size = UDim2.new(1, 46, 1, 46)
	img.BackgroundTransparency = 1
	img.Image = T.SHADOW_IMAGE
	img.ImageColor3 = Color3.new(0, 0, 0)
	img.ImageTransparency = transparency or 0.45
	img.ScaleType = Enum.ScaleType.Slice
	img.SliceCenter = Rect.new(10, 10, 118, 118)
	img.ZIndex = (obj.ZIndex or 1) - 1
	img.Parent = obj
	return img
end

-- Subtle white top-edge highlight (the "glossy plastic" read)
function UIKit.gloss(obj: GuiObject)
	local shine = Instance.new("Frame")
	shine.Name = "KitGloss"
	shine.BackgroundColor3 = T.WHITE
	shine.BackgroundTransparency = 0.82
	shine.BorderSizePixel = 0
	shine.Size = UDim2.new(1, -8, 0, 3)
	shine.Position = UDim2.new(0, 4, 0, 2)
	shine.ZIndex = (obj.ZIndex or 1) + 1
	shine.Parent = obj
	UIKit.corner(shine, 2)
	return shine
end

function UIKit.label(parent: GuiObject?, text: string, size: number?, font: Enum.Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = font or T.FONT
	l.TextSize = size or 16
	l.TextColor3 = T.TEXT
	if parent then l.Parent = parent end
	return l
end

function UIKit.formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s
	while true do
		local replaced
		formatted, replaced = string.gsub(formatted, "^(%-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then break end
	end
	return formatted
end

function UIKit.formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

--========================================================
-- PANELS + HEADERS
--========================================================
-- Standard dialog panel: gradient body, thick outline, shadow.
function UIKit.panel(name: string, size: UDim2): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.BackgroundColor3 = T.BG_BOTTOM
	f.BorderSizePixel = 0
	UIKit.corner(f, 18)
	UIKit.stroke(f, T.OUTLINE + 1)
	UIKit.vgradient(f, T.BG_TOP, T.BG_BOTTOM)
	UIKit.shadow(f)
	return f
end

-- Card surface inside a panel
function UIKit.card(name: string, parent: GuiObject?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = T.SURFACE_BOTTOM
	f.BorderSizePixel = 0
	UIKit.corner(f, 14)
	UIKit.stroke(f, T.OUTLINE)
	UIKit.vgradient(f, T.SURFACE_TOP, T.SURFACE_BOTTOM)
	if parent then f.Parent = parent end
	return f
end

-- Header bar with italic bold title + glossy red close button.
-- Returns the close button so callers can hook it.
function UIKit.header(panel: GuiObject, title: string): (Frame, TextButton)
	local bar = Instance.new("Frame")
	bar.Name = "Header"
	bar.Size = UDim2.new(1, 0, 0, 52)
	bar.BackgroundColor3 = T.HEADER_B
	bar.BorderSizePixel = 0
	bar.ZIndex = (panel.ZIndex or 1) + 1
	bar.Parent = panel
	UIKit.corner(bar, 18)
	UIKit.stroke(bar, T.OUTLINE)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, T.HEADER_A),
		ColorSequenceKeypoint.new(1, T.HEADER_B),
	})
	g.Rotation = 8
	g.Parent = bar
	UIKit.gloss(bar)

	-- square off the bottom of the header bar
	local squareBottom = Instance.new("Frame")
	squareBottom.BackgroundColor3 = T.HEADER_B
	squareBottom.BorderSizePixel = 0
	squareBottom.Size = UDim2.new(1, 0, 0, 18)
	squareBottom.Position = UDim2.new(0, 0, 1, -18)
	squareBottom.ZIndex = bar.ZIndex
	squareBottom.Parent = bar
	local g2 = g:Clone()
	g2.Parent = squareBottom

	local titleLabel = UIKit.label(bar, title, 26)
	titleLabel.Size = UDim2.new(1, -120, 1, 0)
	titleLabel.Position = UDim2.new(0, 18, 0, 0)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = bar.ZIndex + 2
	UIKit.textStroke(titleLabel, 2.5)

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, -10, 0.5, 0)
	close.Size = UDim2.fromOffset(38, 38)
	close.BackgroundColor3 = T.RED_B
	close.Text = "X"
	close.Font = T.FONT
	close.TextSize = 22
	close.TextColor3 = T.WHITE
	close.AutoButtonColor = false
	close.ZIndex = bar.ZIndex + 3
	close.Parent = bar
	UIKit.corner(close, 10)
	UIKit.stroke(close, T.OUTLINE)
	UIKit.vgradient(close, T.RED_A, T.RED_B)
	UIKit.textStroke(close, 2)
	UIKit.bindButtonFX(close)

	return bar, close
end

--========================================================
-- BUTTONS
--========================================================
export type ButtonStyle = "lime" | "blue" | "red" | "gold" | "purple" | "grey" | "orange"

local STYLES: { [string]: { Color3 } } = {
	lime = { T.LIME_A, T.LIME_B },
	blue = { T.BLUE_A, T.BLUE_B },
	red = { T.RED_A, T.RED_B },
	gold = { T.GOLD_A, T.GOLD_B },
	purple = { T.PURPLE_A, T.PURPLE_B },
	grey = { T.GREY_A, T.GREY_B },
	orange = { T.ORANGE_A, T.ORANGE_B },
}

-- Hover grow + press squash + click sound, using UIScale so
-- it composes with any Size the caller sets.
function UIKit.bindButtonFX(btn: GuiButton, silent: boolean?)
	local scale = btn:FindFirstChild("KitScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "KitScale"
		scale.Parent = btn
	end
	local function tweenTo(v: number, t: number, style: Enum.EasingStyle?)
		TweenService:Create(scale :: UIScale, TweenInfo.new(t, style or Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = v }):Play()
	end
	btn.MouseEnter:Connect(function()
		tweenTo(1.05, 0.12, Enum.EasingStyle.Quad)
		if not silent then UIKit.play("Hover", 1.1) end
	end)
	btn.MouseLeave:Connect(function()
		tweenTo(1, 0.12, Enum.EasingStyle.Quad)
	end)
	btn.MouseButton1Down:Connect(function()
		tweenTo(0.93, 0.07, Enum.EasingStyle.Quad)
	end)
	btn.MouseButton1Up:Connect(function()
		tweenTo(1.03, 0.15)
		task.delay(0.1, function() tweenTo(1, 0.12, Enum.EasingStyle.Quad) end)
	end)
	btn.MouseButton1Click:Connect(function()
		if not silent then UIKit.play("Click") end
	end)
end

function UIKit.button(text: string, style: ButtonStyle?, parent: GuiObject?): TextButton
	local colors = STYLES[style or "lime"] or STYLES.lime
	local btn = Instance.new("TextButton")
	btn.Name = "Btn" .. text:gsub("%W", "")
	btn.Size = UDim2.fromOffset(150, 42)
	btn.BackgroundColor3 = colors[2]
	btn.Text = text
	btn.Font = T.FONT
	btn.TextSize = 18
	btn.TextColor3 = (style == "lime") and Color3.fromRGB(20, 62, 0) or T.WHITE
	btn.AutoButtonColor = false
	UIKit.corner(btn, 11)
	UIKit.stroke(btn, T.OUTLINE)
	UIKit.vgradient(btn, colors[1], colors[2])
	UIKit.gloss(btn)
	if style ~= "lime" then UIKit.textStroke(btn, 2) end
	UIKit.bindButtonFX(btn)
	if parent then btn.Parent = parent end
	return btn
end

-- Green price pill with coin icon (or Robux-style text)
function UIKit.pricePill(price: string, parent: GuiObject?, robux: boolean?): TextButton
	local pill = Instance.new("TextButton")
	pill.Name = "PricePill"
	pill.Size = UDim2.fromOffset(110, 34)
	pill.AutoButtonColor = false
	pill.BackgroundColor3 = robux and T.GOLD_B or T.LIME_B
	pill.Text = ""
	UIKit.corner(pill, 9)
	UIKit.stroke(pill, T.OUTLINE)
	if robux then
		UIKit.vgradient(pill, T.GOLD_A, T.GOLD_B)
	else
		UIKit.vgradient(pill, T.LIME_A, T.LIME_B)
	end
	UIKit.gloss(pill)

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(20, 20)
	icon.Position = UDim2.new(0, 7, 0.5, -10)
	icon.Image = T.COIN_ICON
	icon.Visible = not robux
	icon.Parent = pill

	local lbl = UIKit.label(pill, price, 16)
	lbl.Size = UDim2.new(1, robux and -10 or -30, 1, 0)
	lbl.Position = UDim2.new(0, robux and 5 or 28, 0, 0)
	lbl.TextColor3 = robux and T.WHITE or Color3.fromRGB(20, 62, 0)
	if robux then UIKit.textStroke(lbl, 2) end

	UIKit.bindButtonFX(pill)
	if parent then pill.Parent = parent end
	return pill
end

--========================================================
-- MOTION
--========================================================
-- Pop a panel open with a Back-ease overshoot; pass its final size.
function UIKit.popOpen(panel: GuiObject)
	panel.Visible = true
	local scale = panel:FindFirstChild("KitPopScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "KitPopScale"
		scale.Parent = panel
	end
	scale.Scale = 0.8
	UIKit.play("Open", 1.05)
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function UIKit.popClose(panel: GuiObject, onDone: (() -> ())?)
	local scale = panel:FindFirstChild("KitPopScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "KitPopScale"
		scale.Parent = panel
	end
	local tw = TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.82 })
	tw.Completed:Once(function()
		panel.Visible = false
		scale.Scale = 1
		if onDone then onDone() end
	end)
	tw:Play()
end

--========================================================
-- TOAST NOTIFICATIONS (global, stacked top-center)
--========================================================
local toastGui: ScreenGui? = nil
local toastHolder: Frame? = nil

local function ensureToastGui()
	if toastGui and toastGui.Parent then return end
	local pg = player and player:FindFirstChild("PlayerGui")
	if not pg then return end
	toastGui = Instance.new("ScreenGui")
	toastGui.Name = "KitToasts"
	toastGui.ResetOnSpawn = false
	toastGui.DisplayOrder = 5000
	toastGui.Parent = pg

	toastHolder = Instance.new("Frame")
	toastHolder.Name = "Holder"
	toastHolder.AnchorPoint = Vector2.new(0.5, 0)
	toastHolder.Position = UDim2.new(0.5, 0, 0, 12)
	toastHolder.Size = UDim2.new(0, 420, 1, -24)
	toastHolder.BackgroundTransparency = 1
	toastHolder.Parent = toastGui

	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = toastHolder
end

-- icon: emoji string; accent: color of the left stripe
function UIKit.notify(text: string, accent: Color3?, icon: string?, duration: number?)
	ensureToastGui()
	if not toastHolder then return end

	local toast = UIKit.card("Toast")
	toast.Size = UDim2.new(0, 400, 0, 52)
	toast.LayoutOrder = -os.clock()
	toast.Parent = toastHolder

	local stripe = Instance.new("Frame")
	stripe.BackgroundColor3 = accent or T.HEADER_A
	stripe.BorderSizePixel = 0
	stripe.Size = UDim2.new(0, 6, 1, -12)
	stripe.Position = UDim2.new(0, 6, 0, 6)
	stripe.Parent = toast
	UIKit.corner(stripe, 3)

	local iconLbl = UIKit.label(toast, icon or "🔔", 22)
	iconLbl.Size = UDim2.fromOffset(34, 34)
	iconLbl.Position = UDim2.new(0, 18, 0.5, -17)

	local msg = UIKit.label(toast, text, 16, T.FONT_BOLD)
	msg.Size = UDim2.new(1, -70, 1, -10)
	msg.Position = UDim2.new(0, 58, 0, 5)
	msg.TextXAlignment = Enum.TextXAlignment.Left
	msg.TextWrapped = true
	UIKit.textStroke(msg, 1.5)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.7
	scale.Parent = toast
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	UIKit.play("Notify", 1.05)

	task.delay(duration or 3.5, function()
		local out = TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.7 })
		out.Completed:Once(function() toast:Destroy() end)
		out:Play()
	end)
end

--========================================================
-- SLIDER (used by Settings)
--========================================================
function UIKit.slider(parent: GuiObject, labelText: string, initial: number, onChanged: (ratio: number) -> ()): Frame
	local row = Instance.new("Frame")
	row.Name = "Slider" .. labelText:gsub("%W", "")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 62)
	row.Parent = parent

	local lbl = UIKit.label(row, labelText, 17)
	lbl.Size = UDim2.new(0.6, 0, 0, 22)
	lbl.Position = UDim2.new(0, 4, 0, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	UIKit.textStroke(lbl, 2)

	local valueLbl = UIKit.label(row, "100%", 16, T.FONT_BOLD)
	valueLbl.Size = UDim2.new(0.4, -8, 0, 22)
	valueLbl.Position = UDim2.new(0.6, 0, 0, 0)
	valueLbl.TextXAlignment = Enum.TextXAlignment.Right
	valueLbl.TextColor3 = T.TEXT_DIM

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundColor3 = Color3.fromRGB(14, 16, 40)
	track.BorderSizePixel = 0
	track.Size = UDim2.new(1, -8, 0, 14)
	track.Position = UDim2.new(0, 4, 0, 32)
	track.Parent = row
	UIKit.corner(track, 7)
	UIKit.stroke(track, 2.5)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = T.BLUE_B
	fill.Size = UDim2.new(math.clamp(initial, 0, 1), 0, 1, 0)
	fill.Parent = track
	UIKit.corner(fill, 7)
	UIKit.vgradient(fill, T.BLUE_A, T.BLUE_B)

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(22, 22)
	knob.Position = UDim2.new(math.clamp(initial, 0, 1), 0, 0.5, 0)
	knob.BackgroundColor3 = T.WHITE
	knob.ZIndex = 3
	knob.Parent = track
	UIKit.corner(knob, 11)
	UIKit.stroke(knob, 2.5)

	local function apply(ratio: number, fire: boolean)
		ratio = math.clamp(ratio, 0, 1)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueLbl.Text = string.format("%d%%", math.round(ratio * 100))
		if fire then onChanged(ratio) end
	end
	apply(initial, false)

	local dragging = false
	local function ratioFromX(x: number): number
		return math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			apply(ratioFromX(input.Position.X), true)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			apply(ratioFromX(input.Position.X), true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return row
end

--========================================================
-- RESPONSIVE SCALING + DEVICE
--========================================================
function UIKit.deviceType(): string
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		local cam = workspace.CurrentCamera
		local size = cam and cam.ViewportSize or Vector2.new(1280, 720)
		if math.min(size.X, size.Y) <= 500 then
			return "Phone"
		end
		return "Tablet"
	end
	return "PC"
end

-- Adds a UIScale to the gui that tracks viewport size, designed around 1280x720.
function UIKit.autoScale(gui: ScreenGui, minScale: number?, maxScale: number?)
	local scale = Instance.new("UIScale")
	scale.Name = "KitAutoScale"
	scale.Parent = gui

	local function update()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local v = cam.ViewportSize
		local s = math.min(v.X / 1280, v.Y / 720)
		scale.Scale = math.clamp(s, minScale or 0.62, maxScale or 1.35)
	end
	update()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
	RunService.Heartbeat:Once(update)
	return scale
end

-- Exclusive-open manager so only one big menu shows at a time.
local openPanels: { [string]: () -> () } = {}
function UIKit.registerExclusive(name: string, closeFn: () -> ())
	openPanels[name] = closeFn
end
function UIKit.closeOthers(except: string?)
	for name, closeFn in pairs(openPanels) do
		if name ~= except then
			pcall(closeFn)
		end
	end
end

return UIKit

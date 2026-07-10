--!strict
-- SpinWheelLocal — coins-only reward wheel with tick sounds, ease-out landing
-- and an animated reward popup. Server (GameExtrasServer) owns the result.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")
local SpinRequest = ReplicatedStorage:WaitForChild("SpinRequest") :: RemoteFunction

local SEGMENTS = GameConfig.SpinSegments
local SEG_COUNT = #SEGMENTS
local SEG_ANGLE = 360 / SEG_COUNT

local gui = Instance.new("ScreenGui")
gui.Name = "SpinWheelUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 105
gui.Parent = playerGui
UIKit.autoScale(gui)

local panel = UIKit.panel("SpinPanel", UDim2.fromOffset(460, 470))
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Visible = false
panel.Parent = gui

local _, closeBtn = UIKit.header(panel, "LUCKY SPIN")

--========================================================
-- WHEEL (segments as rotated wedges around a hub)
--========================================================
local wheelHolder = Instance.new("Frame")
wheelHolder.Name = "WheelHolder"
wheelHolder.BackgroundTransparency = 1
wheelHolder.AnchorPoint = Vector2.new(0.5, 0)
wheelHolder.Position = UDim2.new(0.5, 0, 0, 66)
wheelHolder.Size = UDim2.fromOffset(280, 280)
wheelHolder.Parent = panel

local wheel = Instance.new("Frame")
wheel.Name = "Wheel"
wheel.BackgroundColor3 = Color3.fromRGB(14, 16, 40)
wheel.Size = UDim2.fromScale(1, 1)
wheel.Parent = wheelHolder
UIKit.corner(wheel, 140)
UIKit.stroke(wheel, 4)

-- Segment labels arranged in a ring, rotated with the wheel
for i, seg in ipairs(SEGMENTS) do
	local angle = (i - 1) * SEG_ANGLE
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.Rotation = angle
	holder.Parent = wheel

	local chip = Instance.new("Frame")
	chip.AnchorPoint = Vector2.new(0.5, 0)
	chip.Position = UDim2.new(0.5, 0, 0, 10)
	chip.Size = UDim2.fromOffset(64, 46)
	chip.BackgroundColor3 = seg.Color
	chip.Parent = holder
	UIKit.corner(chip, 10)
	UIKit.stroke(chip, 2.5)

	local lbl = UIKit.label(chip, tostring(seg.Coins), 17)
	lbl.Size = UDim2.new(1, 0, 0, 24)
	lbl.Position = UDim2.new(0, 0, 0, 2)
	UIKit.textStroke(lbl, 2)

	local coinIcon = UIKit.label(chip, "🪙", 13)
	coinIcon.Size = UDim2.new(1, 0, 0, 16)
	coinIcon.Position = UDim2.new(0, 0, 0, 26)
end

local hub = Instance.new("Frame")
hub.AnchorPoint = Vector2.new(0.5, 0.5)
hub.Position = UDim2.fromScale(0.5, 0.5)
hub.Size = UDim2.fromOffset(70, 70)
hub.BackgroundColor3 = T.HEADER_B
hub.ZIndex = 3
hub.Parent = wheelHolder
UIKit.corner(hub, 35)
UIKit.stroke(hub, 3.5)
UIKit.vgradient(hub, T.HEADER_A, T.HEADER_B)
local hubLbl = UIKit.label(hub, "SPIN", 18)
hubLbl.Size = UDim2.fromScale(1, 1)
hubLbl.ZIndex = 4
UIKit.textStroke(hubLbl, 2)

-- Pointer at the top
local pointer = UIKit.label(panel, "▼", 30)
pointer.AnchorPoint = Vector2.new(0.5, 0)
pointer.Position = UDim2.new(0.5, 0, 0, 46)
pointer.Size = UDim2.fromOffset(40, 30)
pointer.TextColor3 = T.GOLD
pointer.ZIndex = 5
UIKit.textStroke(pointer, 2.5)

--========================================================
-- SPIN BUTTON + COOLDOWN
--========================================================
local spinBtn = UIKit.button("SPIN!", "lime", panel)
spinBtn.Size = UDim2.new(0, 220, 0, 46)
spinBtn.AnchorPoint = Vector2.new(0.5, 1)
spinBtn.Position = UDim2.new(0.5, 0, 1, -14)

local spinning = false

local function updateSpinButton()
	if spinning then return end
	local readyAt = player:GetAttribute("SpinReadyAt")
	local left = typeof(readyAt) == "number" and (readyAt - os.time()) or 0
	local grad = spinBtn:FindFirstChildOfClass("UIGradient")
	if left > 0 then
		spinBtn.Text = "NEXT SPIN " .. UIKit.formatTime(left)
		spinBtn.TextColor3 = T.WHITE
		if grad then
			grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, T.GREY_A), ColorSequenceKeypoint.new(1, T.GREY_B) })
		end
	else
		spinBtn.Text = "SPIN!"
		spinBtn.TextColor3 = Color3.fromRGB(20, 62, 0)
		if grad then
			grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, T.LIME_A), ColorSequenceKeypoint.new(1, T.LIME_B) })
		end
	end
end

task.spawn(function()
	while true do
		updateSpinButton()
		task.wait(1)
	end
end)

--========================================================
-- REWARD POPUP
--========================================================
local function showReward(coins: number)
	local popup = UIKit.card("RewardPopup", gui)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Position = UDim2.new(0.5, 0, 0.42, 0)
	popup.Size = UDim2.fromOffset(300, 170)
	popup.ZIndex = 200

	local burst = UIKit.label(popup, "✨", 40)
	burst.Size = UDim2.new(1, 0, 0, 50)
	burst.Position = UDim2.new(0, 0, 0, 8)
	burst.ZIndex = 201

	local msg = UIKit.label(popup, "YOU WON", 18)
	msg.Size = UDim2.new(1, 0, 0, 24)
	msg.Position = UDim2.new(0, 0, 0, 58)
	msg.TextColor3 = T.TEXT_DIM
	msg.ZIndex = 201
	UIKit.textStroke(msg, 2)

	local amount = UIKit.label(popup, "🪙 " .. UIKit.formatNumber(coins), 34)
	amount.Size = UDim2.new(1, 0, 0, 44)
	amount.Position = UDim2.new(0, 0, 0, 84)
	amount.TextColor3 = T.GOLD
	amount.ZIndex = 201
	UIKit.textStroke(amount, 3)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.4
	scale.Parent = popup
	UIKit.play("Reward")
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	-- gentle shimmer on the amount
	task.spawn(function()
		for _ = 1, 6 do
			TweenService:Create(amount, TweenInfo.new(0.25), { TextColor3 = T.WHITE }):Play()
			task.wait(0.25)
			TweenService:Create(amount, TweenInfo.new(0.25), { TextColor3 = T.GOLD }):Play()
			task.wait(0.25)
		end
	end)

	task.delay(2.6, function()
		local out = TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.3 })
		out.Completed:Once(function() popup:Destroy() end)
		out:Play()
	end)
end

--========================================================
-- SPIN FLOW
--========================================================
local function doSpin()
	if spinning then return end
	local readyAt = player:GetAttribute("SpinReadyAt")
	if typeof(readyAt) == "number" and os.time() < readyAt then
		UIKit.play("Error")
		UIKit.notify("The wheel needs " .. UIKit.formatTime(readyAt - os.time()) .. " to recharge!", T.RED, "🎡")
		return
	end

	spinning = true
	spinBtn.Text = "SPINNING..."

	local result: any = nil
	local ok = pcall(function()
		result = SpinRequest:InvokeServer()
	end)
	if not ok or typeof(result) ~= "table" or not result.ok then
		spinning = false
		updateSpinButton()
		if typeof(result) == "table" and result.reason == "cooldown" then
			UIKit.notify("The wheel is still recharging!", T.RED, "🎡")
		else
			UIKit.notify("Spin failed — try again in a moment.", T.RED, "⚠️")
		end
		return
	end

	-- Animate: land segment `index` under the top pointer.
	-- Segment i sits at rotation (i-1)*SEG_ANGLE at the top when wheel rotation
	-- is -(i-1)*SEG_ANGLE. Add full turns for drama.
	local index = result.index :: number
	local targetRotation = 360 * 5 - (index - 1) * SEG_ANGLE
	wheel.Rotation = wheel.Rotation % 360

	local duration = 4.2
	local tween = TweenService:Create(wheel, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Rotation = targetRotation })
	tween:Play()

	-- tick sounds as segments pass the pointer
	task.spawn(function()
		local lastSegment = -1
		local start = os.clock()
		while os.clock() - start < duration do
			local seg = math.floor(((wheel.Rotation % 360) / SEG_ANGLE))
			if seg ~= lastSegment then
				lastSegment = seg
				UIKit.play("Tick", 1 + math.random() * 0.15)
			end
			task.wait(0.03)
		end
	end)

	tween.Completed:Wait()
	spinning = false
	updateSpinButton()
	showReward(result.coins :: number)
end

spinBtn.MouseButton1Click:Connect(doSpin)
hub.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		doSpin()
	end
end)

--========================================================
-- OPEN / CLOSE
--========================================================
local isOpen = false
local function close()
	if not isOpen then return end
	isOpen = false
	UIKit.popClose(panel)
end
local function open()
	UIKit.closeOthers("Spin")
	isOpen = true
	updateSpinButton()
	UIKit.popOpen(panel)
end
UIKit.registerExclusive("Spin", close)
closeBtn.MouseButton1Click:Connect(close)

;(UIBus:WaitForChild("OpenSpin") :: BindableEvent).Event:Connect(function()
	if isOpen then close() else open() end
end)

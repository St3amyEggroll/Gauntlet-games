--!strict
-- TrollMenuLocal — standalone troll menu (own HUD button, not inside the shop)
-- plus the client-side receiver for troll effects (blur, jumpscare) and the
-- global "PlayerName used X!" broadcasts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")
local TrollEffect = ReplicatedStorage:WaitForChild("TrollEffect") :: RemoteEvent

--========================================================
-- MENU
--========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "TrollMenuUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 110
gui.Parent = playerGui
UIKit.autoScale(gui)

local panel = UIKit.panel("TrollPanel", UDim2.fromOffset(680, 440))
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Visible = false
panel.Parent = gui

local _, closeBtn = UIKit.header(panel, "TROLL MENU")

local subtitle = UIKit.label(panel, "Every purchase hits every player except YOU. Use responsibly... or don't.", 14, T.FONT_BOLD)
subtitle.Size = UDim2.new(1, -30, 0, 20)
subtitle.Position = UDim2.new(0, 15, 0, 58)
subtitle.TextColor3 = T.TEXT_DIM

local scroll = Instance.new("ScrollingFrame")
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Size = UDim2.new(1, -28, 1, -96)
scroll.Position = UDim2.new(0, 14, 0, 84)
scroll.ScrollBarThickness = 5
scroll.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(200, 150)
layout.CellPadding = UDim2.fromOffset(12, 12)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingLeft = UDim.new(0, 4)
pad.Parent = scroll

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 16)
end)

for i, item in ipairs(GameConfig.TrollItems) do
	local card = UIKit.card(item.Key, scroll)
	card.LayoutOrder = i

	local icon = UIKit.label(card, item.Icon, 34)
	icon.Size = UDim2.fromOffset(44, 44)
	icon.Position = UDim2.new(0, 8, 0, 8)

	local name = UIKit.label(card, item.Name, 15)
	name.Size = UDim2.new(1, -60, 0, 40)
	name.Position = UDim2.new(0, 56, 0, 8)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextWrapped = true
	UIKit.textStroke(name, 2)

	local desc = UIKit.label(card, item.Desc, 12, T.FONT_MED)
	desc.Size = UDim2.new(1, -16, 0, 48)
	desc.Position = UDim2.new(0, 8, 0, 52)
	desc.TextWrapped = true
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextColor3 = T.TEXT_DIM

	local buy = UIKit.button(item.Id > 0 and "USE  💥" or "COMING SOON", item.Id > 0 and "red" or "grey", card)
	buy.Size = UDim2.new(1, -16, 0, 34)
	buy.Position = UDim2.new(0, 8, 1, -42)
	buy.TextSize = 15

	buy.MouseButton1Click:Connect(function()
		if item.Id <= 0 then
			UIKit.play("Error")
			UIKit.notify("This troll item isn't set up yet — the owner needs to add its product ID in GameConfig.", T.GREY_B, "🛠️")
			return
		end
		if item.Kind == "Gamepass" then
			MarketplaceService:PromptGamePassPurchase(player, item.Id)
		else
			MarketplaceService:PromptProductPurchase(player, item.Id)
		end
	end)
end

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
	UIKit.closeOthers("Troll")
	isOpen = true
	UIKit.popOpen(panel)
end
UIKit.registerExclusive("Troll", close)
closeBtn.MouseButton1Click:Connect(close)

;(UIBus:WaitForChild("OpenTroll") :: BindableEvent).Event:Connect(function()
	if isOpen then close() else open() end
end)

--========================================================
-- EFFECT RECEIVER (blur / jumpscare hit this client;
-- broadcast toasts reach everyone)
--========================================================
local jumpscareGui: ScreenGui? = nil

local function doJumpscare()
	if jumpscareGui then jumpscareGui:Destroy() end
	local jg = Instance.new("ScreenGui")
	jg.Name = "Jumpscare"
	jg.IgnoreGuiInset = true
	jg.DisplayOrder = 10000
	jg.ResetOnSpawn = false
	jg.Parent = playerGui
	jumpscareGui = jg

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromScale(1, 1)
	img.BackgroundColor3 = Color3.new(0, 0, 0)
	img.Image = "rbxassetid://4772783906" -- scary face
	img.ScaleType = Enum.ScaleType.Crop
	img.Parent = jg

	local scream = Instance.new("Sound")
	scream.SoundId = "rbxassetid://5567523997"
	scream.Volume = 0.9
	scream.Parent = SoundService
	scream:Play()

	local shake = Instance.new("UIScale")
	shake.Parent = img
	task.spawn(function()
		for _ = 1, 14 do
			shake.Scale = 1 + math.random() * 0.08
			img.Position = UDim2.fromOffset(math.random(-14, 14), math.random(-14, 14))
			task.wait(0.05)
		end
	end)

	task.delay(1.1, function()
		local fade = TweenService:Create(img, TweenInfo.new(0.4), { ImageTransparency = 1, BackgroundTransparency = 1 })
		fade.Completed:Once(function()
			jg:Destroy()
			if jumpscareGui == jg then jumpscareGui = nil end
		end)
		fade:Play()
		scream.Ended:Once(function() scream:Destroy() end)
	end)
end

local trollBlur: BlurEffect? = nil
local blurToken = 0

local function doBlur(duration: number)
	blurToken += 1
	local myToken = blurToken
	if not trollBlur or not trollBlur.Parent then
		trollBlur = Instance.new("BlurEffect")
		trollBlur.Name = "TrollBlur"
		trollBlur.Size = 0
		trollBlur.Parent = Lighting
	end
	TweenService:Create(trollBlur :: BlurEffect, TweenInfo.new(0.3), { Size = 32 }):Play()
	task.delay(duration, function()
		if blurToken == myToken and trollBlur then
			TweenService:Create(trollBlur :: BlurEffect, TweenInfo.new(0.5), { Size = 0 }):Play()
		end
	end)
end

TrollEffect.OnClientEvent:Connect(function(action: string, payload: any)
	if action == "Broadcast" then
		UIKit.notify(tostring(payload), T.RED, "🃏", 4.5)
	elseif action == "Jumpscare" then
		doJumpscare()
	elseif action == "Blur" then
		doBlur(typeof(payload) == "number" and payload or 3)
	end
end)

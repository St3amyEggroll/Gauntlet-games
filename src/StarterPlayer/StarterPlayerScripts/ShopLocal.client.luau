--!strict
-- ShopLocal — premium storefront. Side nav (Gauntlets / Coins), gauntlet grid
-- with View buttons, detail side panel, coin pack screen (also opened by the
-- + button next to the coin counter). Replaces ShopSystemLocal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")

local PurchaseEvent = ReplicatedStorage:WaitForChild("PurchaseToolEvent") :: RemoteEvent
local GetOwnedTools = ReplicatedStorage:WaitForChild("GetOwnedTools") :: RemoteFunction
local PurchaseFinished = ReplicatedStorage:WaitForChild("PurchaseFinished") :: RemoteEvent
local SelectGauntlet = ReplicatedStorage:WaitForChild("SelectGauntlet") :: RemoteEvent

local blur = Lighting:FindFirstChild("MenuBlur") :: BlurEffect?
if not blur then
	blur = Instance.new("BlurEffect")
	blur.Name = "MenuBlur"
	blur.Size = 0
	blur.Parent = Lighting
end

--========================================================
-- GUI SHELL
--========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ShopUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui
UIKit.autoScale(gui)

local panel = UIKit.panel("ShopPanel", UDim2.fromOffset(780, 480))
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Visible = false
panel.Parent = gui

local _, closeBtn = UIKit.header(panel, "GAUNTLET SHOP")

-- coin balance readout in the header
local balancePill = UIKit.card("Balance", panel)
balancePill.AnchorPoint = Vector2.new(1, 0.5)
balancePill.Position = UDim2.new(1, -58, 0, 26)
balancePill.Size = UDim2.fromOffset(130, 36)
balancePill.ZIndex = 5
balancePill.ZIndex = 5
local balIcon = Instance.new("ImageLabel")
balIcon.BackgroundTransparency = 1
balIcon.Size = UDim2.fromOffset(22, 22)
balIcon.Position = UDim2.new(0, 7, 0.5, -11)
balIcon.Image = T.COIN_ICON
balIcon.ZIndex = 6
balIcon.Parent = balancePill
local balLabel = UIKit.label(balancePill, "0", 17)
balLabel.Size = UDim2.new(1, -38, 1, 0)
balLabel.Position = UDim2.new(0, 34, 0, 0)
balLabel.TextXAlignment = Enum.TextXAlignment.Left
balLabel.TextColor3 = T.GOLD
balLabel.ZIndex = 6
UIKit.textStroke(balLabel, 2)
local function refreshBalance()
	balLabel.Text = UIKit.formatNumber(player:GetAttribute("Coins") or 0)
end
player:GetAttributeChangedSignal("Coins"):Connect(refreshBalance)
refreshBalance()

--========================================================
-- SIDE NAV
--========================================================
local nav = Instance.new("Frame")
nav.Name = "Nav"
nav.BackgroundTransparency = 1
nav.Position = UDim2.new(0, 14, 0, 66)
nav.Size = UDim2.fromOffset(120, 400)
nav.Parent = panel

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 8)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = nav

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 146, 0, 66)
content.Size = UDim2.new(1, -160, 1, -80)
content.Parent = panel

local tabs: { [string]: Frame } = {}
local tabButtons: { [string]: TextButton } = {}
local activeTab = "Gauntlets"
local setTab: (key: string) -> ()

local function makeTab(key: string, icon: string, order: number): Frame
	local btn = UIKit.button(icon .. "  " .. key, "blue", nav)
	btn.Size = UDim2.new(1, 0, 0, 44)
	btn.TextSize = 15
	btn.LayoutOrder = order
	tabButtons[key] = btn

	local page = Instance.new("Frame")
	page.Name = key .. "Page"
	page.BackgroundTransparency = 1
	page.Size = UDim2.fromScale(1, 1)
	page.Visible = false
	page.Parent = content
	tabs[key] = page

	btn.MouseButton1Click:Connect(function()
		setTab(key)
	end)
	return page
end

setTab = function(key: string)
	activeTab = key
	for k, page in pairs(tabs) do
		page.Visible = (k == key)
		local b = tabButtons[k]
		local grad = b:FindFirstChildOfClass("UIGradient")
		if grad then
			if k == key then
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, T.BLUE_A),
					ColorSequenceKeypoint.new(1, T.BLUE_B),
				})
			else
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, T.GREY_A),
					ColorSequenceKeypoint.new(1, T.GREY_B),
				})
			end
		end
	end
end

local gauntletPage = makeTab("Gauntlets", "🧤", 1)
local coinsPage = makeTab("Coins", "🪙", 2)

--========================================================
-- GAUNTLETS TAB: grid + detail side panel
--========================================================
local owned: { string } = {}
local equipped: string? = nil

local function refreshOwned()
	local ok, result = pcall(function()
		return GetOwnedTools:InvokeServer()
	end)
	if ok and typeof(result) == "table" then
		owned = result
	end
	if not table.find(owned, "Starter Gauntlet") then
		table.insert(owned, "Starter Gauntlet")
	end
	for name, info in pairs(GameConfig.Gauntlets) do
		if info.GamepassId and not table.find(owned, name) then
			local s, res = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, info.GamepassId :: number)
			end)
			if s and res then
				table.insert(owned, name)
			end
		end
	end
end

local gridScroll = Instance.new("ScrollingFrame")
gridScroll.Name = "Grid"
gridScroll.BackgroundTransparency = 1
gridScroll.BorderSizePixel = 0
gridScroll.Size = UDim2.new(1, -240, 1, 0)
gridScroll.ScrollBarThickness = 5
gridScroll.ScrollBarImageColor3 = T.HEADER_B
gridScroll.Parent = gauntletPage

local gridPad = Instance.new("UIPadding")
gridPad.PaddingTop = UDim.new(0, 6)
gridPad.PaddingLeft = UDim.new(0, 6)
gridPad.PaddingRight = UDim.new(0, 6)
gridPad.PaddingBottom = UDim.new(0, 6)
gridPad.Parent = gridScroll

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(120, 158)
gridLayout.CellPadding = UDim2.fromOffset(10, 10)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = gridScroll

gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	gridScroll.CanvasSize = UDim2.fromOffset(0, gridLayout.AbsoluteContentSize.Y + 16)
end)

-- Detail panel (right side)
local detail = UIKit.card("Detail", gauntletPage)
detail.Size = UDim2.new(0, 224, 1, 0)
detail.Position = UDim2.new(1, -224, 0, 0)

local detailIcon = Instance.new("ImageLabel")
detailIcon.BackgroundTransparency = 1
detailIcon.Size = UDim2.fromOffset(110, 110)
detailIcon.Position = UDim2.new(0.5, -55, 0, 14)
detailIcon.ScaleType = Enum.ScaleType.Fit
detailIcon.Parent = detail

local detailName = UIKit.label(detail, "Pick a gauntlet", 19)
detailName.Size = UDim2.new(1, -16, 0, 26)
detailName.Position = UDim2.new(0, 8, 0, 126)
detailName.TextWrapped = true
UIKit.textStroke(detailName, 2)

local detailRarity = UIKit.label(detail, "", 13)
detailRarity.Size = UDim2.new(1, -16, 0, 18)
detailRarity.Position = UDim2.new(0, 8, 0, 152)

local detailDesc = UIKit.label(detail, "Select any gauntlet in the grid to see its details.", 13, T.FONT_MED)
detailDesc.Size = UDim2.new(1, -24, 0, 84)
detailDesc.Position = UDim2.new(0, 12, 0, 174)
detailDesc.TextWrapped = true
detailDesc.TextYAlignment = Enum.TextYAlignment.Top
detailDesc.TextColor3 = T.TEXT_DIM

local detailAbility = UIKit.label(detail, "", 13, T.FONT_BOLD)
detailAbility.Size = UDim2.new(1, -24, 0, 40)
detailAbility.Position = UDim2.new(0, 12, 0, 258)
detailAbility.TextWrapped = true
detailAbility.TextYAlignment = Enum.TextYAlignment.Top
detailAbility.TextXAlignment = Enum.TextXAlignment.Left
detailAbility.TextColor3 = T.HEADER_A

local actionBtn = UIKit.button("PURCHASE", "lime", detail)
actionBtn.Size = UDim2.new(1, -24, 0, 44)
actionBtn.Position = UDim2.new(0, 12, 1, -56)

local selected: string? = nil
local cardRefreshers: { [string]: () -> () } = {}

local function refreshDetail()
	if not selected then return end
	local info = GameConfig.Gauntlets[selected]
	if not info then return end

	detailIcon.Image = info.Icon ~= "" and info.Icon or GameConfig.FallbackIcon
	detailName.Text = selected :: string
	detailRarity.Text = string.upper(info.Rarity)
	detailRarity.TextColor3 = UIKit.Rarity[info.Rarity] or T.TEXT_DIM
	detailDesc.Text = info.Desc
	if info.Ability then
		detailAbility.Text = ("⚡ Ability: %s\n⏳ Cooldown: %ds"):format(info.Ability, info.Cooldown or 0)
	else
		detailAbility.Text = "🛡️ Passive — always active, no cooldown."
	end

	local grad = actionBtn:FindFirstChildOfClass("UIGradient")
	local function paint(a: Color3, b: Color3, textColor: Color3)
		if grad then
			grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b) })
		end
		actionBtn.TextColor3 = textColor
	end

	if table.find(owned, selected :: string) then
		if equipped == selected then
			actionBtn.Text = "EQUIPPED ✓"
			paint(T.GREY_A, T.GREY_B, T.WHITE)
		else
			actionBtn.Text = "EQUIP"
			paint(T.BLUE_A, T.BLUE_B, T.WHITE)
		end
	elseif info.GamepassId then
		actionBtn.Text = "BUY  R$ " .. info.Price
		paint(T.GOLD_A, T.GOLD_B, T.WHITE)
	else
		actionBtn.Text = "BUY  🪙 " .. UIKit.formatNumber(info.Price)
		paint(T.LIME_A, T.LIME_B, Color3.fromRGB(20, 62, 0))
	end
end

actionBtn.MouseButton1Click:Connect(function()
	if not selected then return end
	local name = selected :: string
	local info = GameConfig.Gauntlets[name]
	if not info then return end

	if table.find(owned, name) then
		-- Equip it for the next round
		equipped = name
		SelectGauntlet:FireServer(name)
		UIKit.notify("Equipped " .. name .. " for the next round!", T.HEADER_A, "🧤")
		refreshDetail()
		return
	end

	if info.GamepassId then
		MarketplaceService:PromptGamePassPurchase(player, info.GamepassId :: number)
		return
	end

	local coins = player:GetAttribute("Coins") or 0
	if coins < info.Price then
		UIKit.play("Error")
		UIKit.notify(("You need %s more coins for %s!"):format(UIKit.formatNumber(info.Price - coins), name), T.RED, "❌")
		return
	end
	PurchaseEvent:FireServer(name)
end)

local function makeGauntletCard(name: string, info: any)
	local card = UIKit.card(name, gridScroll)
	card.LayoutOrder = (UIKit.RarityOrder[info.Rarity] or 1) * 10000 + info.Price

	local rarityStripe = Instance.new("Frame")
	rarityStripe.BackgroundColor3 = UIKit.Rarity[info.Rarity] or T.GREY_B
	rarityStripe.BorderSizePixel = 0
	rarityStripe.Size = UDim2.new(1, -12, 0, 17)
	rarityStripe.Position = UDim2.new(0, 6, 0, 5)
	rarityStripe.Parent = card
	UIKit.corner(rarityStripe, 8)
	local rarityLbl = UIKit.label(rarityStripe, string.upper(info.Rarity), 10, T.FONT_BOLD)
	rarityLbl.Size = UDim2.fromScale(1, 1)
	UIKit.textStroke(rarityLbl, 1.5)

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(58, 58)
	icon.Position = UDim2.new(0.5, -29, 0, 26)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Image = info.Icon ~= "" and info.Icon or GameConfig.FallbackIcon
	icon.Parent = card

	local title = UIKit.label(card, (name:gsub(" Gauntlet", "")), 14)
	title.Size = UDim2.new(1, -8, 0, 18)
	title.Position = UDim2.new(0, 4, 0, 84)
	title.TextTruncate = Enum.TextTruncate.AtEnd
	UIKit.textStroke(title, 2)

	local price = UIKit.label(card, "", 12, T.FONT_BOLD)
	price.Size = UDim2.new(1, -8, 0, 14)
	price.Position = UDim2.new(0, 4, 0, 102)
	price.TextColor3 = info.GamepassId and T.GOLD or Color3.fromRGB(158, 232, 112)
	price.Text = info.GamepassId and ("R$ " .. info.Price) or ("🪙 " .. UIKit.formatNumber(info.Price))

	local viewBtn = UIKit.button("VIEW", "blue", card)
	viewBtn.Size = UDim2.new(1, -16, 0, 30)
	viewBtn.Position = UDim2.new(0, 8, 1, -38)
	viewBtn.TextSize = 14

	local ownedBadge = UIKit.label(card, "✓", 16)
	ownedBadge.Size = UDim2.fromOffset(22, 22)
	ownedBadge.Position = UDim2.new(1, -26, 0, 26)
	ownedBadge.TextColor3 = T.GREEN
	ownedBadge.Visible = false
	UIKit.textStroke(ownedBadge, 2)

	local function refresh()
		ownedBadge.Visible = table.find(owned, name) ~= nil
	end
	cardRefreshers[name] = refresh
	refresh()

	local function view()
		selected = name
		refreshDetail()
	end
	viewBtn.MouseButton1Click:Connect(view)
end

for name, info in pairs(GameConfig.Gauntlets) do
	makeGauntletCard(name, info)
end

--========================================================
-- COINS TAB
--========================================================
local coinsTitle = UIKit.label(coinsPage, "Grab more coins — delivered instantly, saved forever.", 15, T.FONT_BOLD)
coinsTitle.Size = UDim2.new(1, 0, 0, 24)
coinsTitle.TextColor3 = T.TEXT_DIM

local coinScroll = Instance.new("ScrollingFrame")
coinScroll.BackgroundTransparency = 1
coinScroll.BorderSizePixel = 0
coinScroll.Size = UDim2.new(1, 0, 1, -30)
coinScroll.Position = UDim2.new(0, 0, 0, 30)
coinScroll.ScrollBarThickness = 5
coinScroll.Parent = coinsPage

local coinLayout = Instance.new("UIGridLayout")
coinLayout.CellSize = UDim2.fromOffset(140, 172)
coinLayout.CellPadding = UDim2.fromOffset(12, 12)
coinLayout.SortOrder = Enum.SortOrder.LayoutOrder
coinLayout.Parent = coinScroll

local coinPagePad = Instance.new("UIPadding")
coinPagePad.PaddingTop = UDim.new(0, 6)
coinPagePad.PaddingLeft = UDim.new(0, 6)
coinPagePad.Parent = coinScroll

coinLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	coinScroll.CanvasSize = UDim2.fromOffset(0, coinLayout.AbsoluteContentSize.Y + 16)
end)

for i, bundle in ipairs(GameConfig.CoinBundles) do
	local card = UIKit.card(bundle.Name, coinScroll)
	card.LayoutOrder = i

	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromOffset(70, 70)
	img.Position = UDim2.new(0.5, -35, 0, 10)
	img.ScaleType = Enum.ScaleType.Fit
	img.Image = bundle.Image
	img.Parent = card

	local amount = UIKit.label(card, "+" .. UIKit.formatNumber(bundle.Amount), 19)
	amount.Size = UDim2.new(1, 0, 0, 24)
	amount.Position = UDim2.new(0, 0, 0, 84)
	amount.TextColor3 = T.GOLD
	UIKit.textStroke(amount, 2)

	local nm = UIKit.label(card, bundle.Name, 12, T.FONT_BOLD)
	nm.Size = UDim2.new(1, -8, 0, 16)
	nm.Position = UDim2.new(0, 4, 0, 108)
	nm.TextColor3 = T.TEXT_DIM

	local buy = UIKit.pricePill("R$ " .. bundle.Robux, card, true)
	buy.Size = UDim2.new(1, -20, 0, 34)
	buy.Position = UDim2.new(0, 10, 1, -42)
	buy.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(player, bundle.ProductId)
	end)
end

--========================================================
-- OPEN / CLOSE
--========================================================
local shopOpen = false

local function closeShop()
	if not shopOpen then return end
	shopOpen = false
	TweenService:Create(blur :: BlurEffect, TweenInfo.new(0.2), { Size = 0 }):Play()
	UIKit.popClose(panel)
end

local function openShop(tab: string?)
	UIKit.closeOthers("Shop")
	if shopOpen and tab then
		setTab(tab)
		return
	end
	shopOpen = true
	task.spawn(refreshOwned)
	setTab(tab or "Gauntlets")
	refreshDetail()
	for _, r in pairs(cardRefreshers) do r() end
	TweenService:Create(blur :: BlurEffect, TweenInfo.new(0.25), { Size = 14 }):Play()
	UIKit.popOpen(panel)
end

UIKit.registerExclusive("Shop", closeShop)
closeBtn.MouseButton1Click:Connect(closeShop)

;(UIBus:WaitForChild("OpenShop") :: BindableEvent).Event:Connect(function(tab: string?)
	if shopOpen and not tab then
		closeShop()
	else
		openShop(tab)
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.B then
		if shopOpen then closeShop() else openShop() end
	end
end)

--========================================================
-- PURCHASE FEEDBACK
--========================================================
PurchaseFinished.OnClientEvent:Connect(function(itemName: string, amount: number?)
	if itemName == "Coins" and amount then
		UIKit.play("Buy")
		UIKit.notify(("+%s coins added to your balance!"):format(UIKit.formatNumber(amount)), T.GOLD, "🪙")
		return
	end
	UIKit.play("Buy")
	UIKit.notify(("You now own the %s!"):format(itemName), T.GREEN, "🧤")
	task.spawn(function()
		refreshOwned()
		for _, r in pairs(cardRefreshers) do r() end
		refreshDetail()
	end)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, _passId, wasPurchased)
	if plr ~= player or not wasPurchased then return end
	task.delay(0.6, function()
		refreshOwned()
		for _, r in pairs(cardRefreshers) do r() end
		refreshDetail()
	end)
end)

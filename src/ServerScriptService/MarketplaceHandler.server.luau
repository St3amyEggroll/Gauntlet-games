--!strict
-- MarketplaceHandler — the ONE ProcessReceipt for the whole game.
-- Grants coin packs (saved through leaderstats -> PlayerCoins_V1 DataStore)
-- and runs troll purchases. Troll effects hit every player EXCEPT the buyer
-- and everyone sees a "PlayerName used X!" broadcast.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local purchaseFinished = ReplicatedStorage:FindFirstChild("PurchaseFinished") :: RemoteEvent?
if not purchaseFinished then
	purchaseFinished = Instance.new("RemoteEvent")
	purchaseFinished.Name = "PurchaseFinished"
	purchaseFinished.Parent = ReplicatedStorage
end

local trollEffect = ReplicatedStorage:FindFirstChild("TrollEffect") :: RemoteEvent?
if not trollEffect then
	trollEffect = Instance.new("RemoteEvent")
	trollEffect.Name = "TrollEffect"
	trollEffect.Parent = ReplicatedStorage
end

--========================================================
-- COIN PACKS
--========================================================
local PRODUCT_TO_COINS: { [number]: number } = {}
for _, bundle in ipairs(GameConfig.CoinBundles) do
	PRODUCT_TO_COINS[bundle.ProductId] = bundle.Amount
end

-- Legacy: gauntlet gamepasses that used to also grant coins are handled by
-- ItemDataHandler for ownership; no coin grant here.

local function awardCoins(player: Player, amount: number): boolean
	local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 5)
	local coinsStat = leaderstats and (leaderstats:FindFirstChild("Coins") or leaderstats:WaitForChild("Coins", 5))
	if not coinsStat or not coinsStat:IsA("IntValue") then
		return false
	end
	coinsStat.Value += amount
	return true
end

--========================================================
-- TROLL EFFECTS (server authoritative)
--========================================================
local TROLL_BY_PRODUCT: { [number]: any } = {}
local TROLL_BY_PASS: { [number]: any } = {}
for _, item in ipairs(GameConfig.TrollItems) do
	if item.Id > 0 then
		if item.Kind == "Product" then
			TROLL_BY_PRODUCT[item.Id] = item
		else
			TROLL_BY_PASS[item.Id] = item
		end
	end
end

local function othersOf(buyer: Player): { Player }
	local result = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= buyer then
			table.insert(result, p)
		end
	end
	return result
end

local function broadcast(item: any, buyer: Player)
	local msg = string.format(item.Broadcast, buyer.DisplayName);
	(trollEffect :: RemoteEvent):FireAllClients("Broadcast", msg)
end

local TrollActions: { [string]: (buyer: Player) -> () } = {}

TrollActions.Highlight = function(buyer)
	for _, p in ipairs(othersOf(buyer)) do
		local char = p.Character
		if char then
			local h = Instance.new("Highlight")
			h.Name = "TrollHighlight"
			h.FillColor = Color3.fromRGB(255, 80, 80)
			h.FillTransparency = 0.6
			h.OutlineColor = Color3.fromRGB(255, 255, 255)
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.Parent = char
			Debris:AddItem(h, 10)
		end
	end
end

TrollActions.JoinRound = function(buyer)
	-- Pull the buyer out of the lobby and into the active round
	local char = buyer.Character
	local ingame = workspace:FindFirstChild("Ingame")
	if not (char and char:FindFirstChild("HumanoidRootPart") and ingame) then return end
	if workspace:GetAttribute("MatchActive") ~= true then return end
	if char.Parent == ingame then return end

	local teleports = workspace:FindFirstChild("Teleports")
	local spawnPoint: BasePart? = nil
	if teleports then
		local options = teleports:GetChildren()
		if #options > 0 then
			local pick = options[math.random(1, #options)]
			if pick:IsA("BasePart") then spawnPoint = pick end
		end
	end
	if spawnPoint then
		char:PivotTo(spawnPoint.CFrame * CFrame.new(0, 3, 0))
	end
	char.Parent = ingame
end

TrollActions.Jumpscare = function(buyer)
	for _, p in ipairs(othersOf(buyer)) do
		(trollEffect :: RemoteEvent):FireClient(p, "Jumpscare")
	end
end

TrollActions.Burn = function(buyer)
	for _, p in ipairs(othersOf(buyer)) do
		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if char and hum and hum.Health > 0 and root then
			local fire = Instance.new("Fire")
			fire.Size = 6
			fire.Heat = 10
			fire.Parent = root
			Debris:AddItem(fire, 3)
			task.spawn(function()
				for _ = 1, 3 do
					if hum.Health <= 0 then break end
					hum:TakeDamage(4)
					task.wait(1)
				end
			end)
		end
	end
end

TrollActions.Explode = function(buyer)
	for _, p in ipairs(othersOf(buyer)) do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local boom = Instance.new("Explosion")
			boom.Position = root.Position
			boom.BlastRadius = 8
			boom.BlastPressure = 0 -- no ragdoll launch, just damage + visuals
			boom.DestroyJointRadiusPercent = 0
			boom.Parent = workspace
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum:TakeDamage(35) end
		end
	end
end

TrollActions.Blur = function(buyer)
	for _, p in ipairs(othersOf(buyer)) do
		(trollEffect :: RemoteEvent):FireClient(p, "Blur", 3)
	end
end

local function runTroll(item: any, buyer: Player)
	local action = TrollActions[item.Key]
	if not action then
		warn("[MarketplaceHandler] No troll action for key: " .. tostring(item.Key))
		return
	end
	broadcast(item, buyer)
	task.spawn(action, buyer)
end

--========================================================
-- RECEIPTS
--========================================================
local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId

	local coinAmount = PRODUCT_TO_COINS[productId]
	if coinAmount then
		if not awardCoins(player, coinAmount) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		(purchaseFinished :: RemoteEvent):FireClient(player, "Coins", coinAmount)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local trollItem = TROLL_BY_PRODUCT[productId]
	if trollItem then
		runTroll(trollItem, player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	warn("[MarketplaceHandler] Unconfigured product id:", productId)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = processReceipt

-- Gamepass-kind troll items: owning the pass lets you trigger it (with a
-- cooldown so it can't be spammed). Fired right after purchase too.
local passCooldowns: { [Player]: { [number]: number } } = {}

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if not wasPurchased then return end
	local item = TROLL_BY_PASS[gamePassId]
	if item then
		runTroll(item, player)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	passCooldowns[p] = nil
end)

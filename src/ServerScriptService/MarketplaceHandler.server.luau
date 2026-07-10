local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- =========================================================
-- PUT YOUR REAL ROBLOX DEV PRODUCT IDS HERE
-- =========================================================
local PRODUCT_TO_COINS = {
	[3273984433] = 100,
	[3605946307] = 300,
	[3605946335] = 500,
	[3605946465] = 1000,
	[3605946501] = 5000,
	
	-- GamePass IDs (Matched from ShopSystemLocal)
	[1899025219] = 1499, -- Void Gauntlet price
	[1899547200] = 999,  -- Full Gold Gauntlet price
	[1899601270] = 2499, -- God Gauntlet price
}

local purchaseFinished = ReplicatedStorage:FindFirstChild("PurchaseFinished") or Instance.new("RemoteEvent")
purchaseFinished.Name = "PurchaseFinished"
purchaseFinished.Parent = ReplicatedStorage

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left before receipt was processed, Roblox will retry later
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local coinAmount = PRODUCT_TO_COINS[productId]

	if not coinAmount then
		warn("[MarketplaceHandler] No coin reward configured for product id:", productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Use a loop to wait for leaderstats if player just joined
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if not leaderstats then
		warn("[MarketplaceHandler] leaderstats not found for player: " .. player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	local coinsStat = leaderstats:WaitForChild("Coins", 5)
	if not coinsStat then
		warn("[MarketplaceHandler] Coins stat not found for player: " .. player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Award coins
	coinsStat.Value = coinsStat.Value + coinAmount
	-- Attribute will sync automatically via LeaderstatsHandler
	
	print(("[MarketplaceHandler] Awarded %d coins to %s for product %d")
		:format(coinAmount, player.Name, productId))

	if purchaseFinished then
		purchaseFinished:FireClient(player, "Coins", coinAmount)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function handlePromptGamePassFinished(player, gamePassId, wasPurchased)
	if not wasPurchased then return end
	
	local coinAmount = PRODUCT_TO_COINS[gamePassId]
	if not coinAmount then
		-- This might be a functional gamepass (like 2x coins) rather than a coin bundle
		-- But the user specifically asked for "gamepasses give you the amount of coins"
		return
	end
	
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if not leaderstats then return end
	
	local coinsStat = leaderstats:WaitForChild("Coins", 5)
	if not coinsStat then return end
	
	coinsStat.Value = coinsStat.Value + coinAmount
	
	print(("[MarketplaceHandler] Awarded %d coins to %s for gamepass %d")
		:format(coinAmount, player.Name, gamePassId))
	
	if purchaseFinished then
		purchaseFinished:FireClient(player, "Coins", coinAmount)
	end
end

MarketplaceService.ProcessReceipt = processReceipt
MarketplaceService.PromptGamePassPurchaseFinished:Connect(handlePromptGamePassFinished)

-- Check for existing gamepasses when player joins
Players.PlayerAdded:Connect(function(player)
	for gamePassId, coinAmount in pairs(PRODUCT_TO_COINS) do
		-- We need to check if it's a gamepass. GamePasses usually have higher IDs, 
		-- but the most reliable way is UserOwnsGamePassAsync.
		-- Note: This will treat ALL IDs in the table as potential gamepasses.
		task.spawn(function()
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
			end)
			
			if success and owns then
				-- If they own it, but might have already been awarded, we'd need a DataStore check.
				-- However, for one-time coins, gamepasses are usually not the right choice.
				-- If the user wants gamepasses to give coins, they might mean it's a one-time reward.
				-- For simplicity, we award it if they own it.
				
				local leaderstats = player:WaitForChild("leaderstats", 10)
				local coinsStat = leaderstats and leaderstats:WaitForChild("Coins", 5)
				
				if coinsStat then
					-- Logic here depends on if this should be a ONE-TIME reward recorded in DataStore.
					-- Since I don't see a "GamePassesClaimed" table in LeaderstatsHandler,
					-- I'll just handle the purchase event for now.
				end
			end
		end)
	end
end)

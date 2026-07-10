local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
-- Setup DataStore and Remote
local PurchaseToolEvent = ReplicatedStorage:FindFirstChild("PurchaseToolEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
PurchaseToolEvent.Name = "PurchaseToolEvent"

local GetOwnedTools = ReplicatedStorage:FindFirstChild("GetOwnedTools") or Instance.new("RemoteFunction", ReplicatedStorage)
GetOwnedTools.Name = "GetOwnedTools"

local PurchaseFinished = ReplicatedStorage:FindFirstChild("PurchaseFinished") or Instance.new("RemoteEvent", ReplicatedStorage)
PurchaseFinished.Name = "PurchaseFinished"

local PurchasedItemsDataStore = DataStoreService:GetDataStore("PurchasedItems")

local prices = {
	["Rock Gauntlet"] = 800,
	["Grappling Gauntlet"] = 800,
	["Water Gauntlet"] = 300,
	["Energy Gauntlet"] = 100,
	["Ice Gauntlet"] = 300,
	["Space Gauntlet"] = 100,
	["Emerald Gauntlet"] = 100,
	["Fire Gauntlet"] = 300,
	["Nature Gauntlet"] = 500,
	["Wind Gauntlet"] = 1000,
	["X-Ray Gauntlet"] = 600,
	["Missle Gauntlet"] = 800,
	["God Gauntlet"] = 2499,
	["Void Gauntlet"] = 1499,
	["Full Gold Gauntlet"] = 999,
}

local Gamepasses = {
	["Void Gauntlet"] = 1899025219,
	["Full Gold Gauntlet"] = 1899547200,
	["God Gauntlet"] = 1899601270,
}
-- Handle purchase
PurchaseToolEvent.OnServerEvent:Connect(function(player, toolName)
	local coinsValue = player:GetAttribute("Coins") or 0
	local price = prices[toolName]

	if not price then 
		warn("[ItemDataHandler] No price found for " .. tostring(toolName))
		return 
	end

	-- Check if already owned
	local success, saved = pcall(function()
		return PurchasedItemsDataStore:GetAsync(player.UserId)
	end)
	local owned = (success and type(saved) == "table") and saved or {}
	
	if table.find(owned, toolName) then
		print(player.Name .. " already owns " .. toolName)
		return
	end

	local gamepassId = Gamepasses[toolName]

	if gamepassId then
		local ownsPass = false

		local success, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
		end)

		if success then
			ownsPass = result
		end

		if not ownsPass then
			warn(player.Name .. " tried to obtain " .. toolName .. " without owning the Game Pass.")
			return
		end

		table.insert(owned, toolName)

		local saveSuccess, err = pcall(function()
			PurchasedItemsDataStore:SetAsync(player.UserId, owned)
		end)

		if saveSuccess then
			local finishedEvent = ReplicatedStorage:FindFirstChild("PurchaseFinished")
			if finishedEvent then
				finishedEvent:FireClient(player, toolName)
			end
		end

		return
	end
	
	if coinsValue >= price then
		-- Deduct coins
		player:SetAttribute("Coins", coinsValue - price)
		print("Deducted " .. price .. " coins from " .. player.Name .. ". Remaining: " .. player:GetAttribute("Coins"))

		-- Save the tool
		table.insert(owned, toolName)
		local saveSuccess, err = pcall(function()
			PurchasedItemsDataStore:SetAsync(player.UserId, owned)
		end)
		
		if saveSuccess then
			print("Successfully saved " .. toolName .. " for " .. player.Name)
			-- Notify client
			local finishedEvent = ReplicatedStorage:FindFirstChild("PurchaseFinished")
			if finishedEvent then
				finishedEvent:FireClient(player, toolName)
			end
		else
			warn("Failed to save tool for " .. player.Name .. ": " .. tostring(err))
		end
	else
		warn(player.Name .. " does not have enough coins for " .. toolName .. " (Price: " .. price .. ", Balance: " .. (player:GetAttribute("Coins") or 0) .. ")")
	end
end)

-- Give back tools on join (Modified: We actually use specialized logic in RoundManager or InventorySystem usually, but keeping this for safety)
-- However, for this specific game, the InventorySystemLocal handles the GUI, and tools are likely given at round start.
-- I'll keep the storage logic here.

-- Allow client to ask for tools
GetOwnedTools.OnServerInvoke = function(player)
	local success, tools = pcall(function()
		return PurchasedItemsDataStore:GetAsync(player.UserId)
	end)
	return (success and tools) or {}
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if not purchased then
		return
	end

	local toolName

	for name, id in pairs(Gamepasses) do
		if id == gamePassId then
			toolName = name
			break
		end
	end

	if not toolName then
		return
	end

	local success, owned = pcall(function()
		return PurchasedItemsDataStore:GetAsync(player.UserId)
	end)

	owned = (success and type(owned) == "table") and owned or {}

	if not table.find(owned, toolName) then
		table.insert(owned, toolName)
		pcall(function()
			PurchasedItemsDataStore:SetAsync(player.UserId, owned)
		end)
	end

	local finishedEvent = ReplicatedStorage:FindFirstChild("PurchaseFinished")
	if finishedEvent then
		finishedEvent:FireClient(player, toolName)
	end
end)
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local PurchasedItemsDataStore = DataStoreService:GetDataStore("PurchasedItems")
local SelectGauntlet = ReplicatedStorage:FindFirstChild("SelectGauntlet") or Instance.new("RemoteEvent", ReplicatedStorage)
SelectGauntlet.Name = "SelectGauntlet"

local STARTER_GAUNTLETS = {"Space Gauntlet", "Energy Gauntlet", "Emerald Gauntlet"}

SelectGauntlet.OnServerEvent:Connect(function(player, gauntletName)
	if not table.find(STARTER_GAUNTLETS, gauntletName) then
		warn(player.Name .. " tried to select invalid starter gauntlet: " .. tostring(gauntletName))
		return
	end

	-- Check if player already has any tools (to prevent re-claiming)
	local success, saved = pcall(function()
		return PurchasedItemsDataStore:GetAsync(player.UserId)
	end)
	
	if success and saved and type(saved) == "table" and #saved > 0 then
		warn(player.Name .. " already has owned tools, cannot claim starter gauntlet.")
		return
	end

	-- Save the selected gauntlet
	local owned = {gauntletName}
	local saveSuccess, err = pcall(function()
		PurchasedItemsDataStore:SetAsync(player.UserId, owned)
	end)

	if saveSuccess then
		print("Successfully assigned starter gauntlet " .. gauntletName .. " to " .. player.Name)
		player:SetAttribute("TutorialComplete", true)
		-- Notify client for UI cleanup or refresh
		local finishedEvent = ReplicatedStorage:FindFirstChild("PurchaseFinished")
		if finishedEvent then
			finishedEvent:FireClient(player, gauntletName)
		end
	else
		warn("Failed to save starter gauntlet for " .. player.Name .. ": " .. tostring(err))
	end
end)

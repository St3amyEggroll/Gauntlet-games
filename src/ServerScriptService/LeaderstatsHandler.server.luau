local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local CoinDataStore = DataStoreService:GetDataStore("PlayerCoins_V1")

local function SaveData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	local kills = leaderstats and leaderstats:FindFirstChild("Kills")
	
	if not coins then return end
	
	local data = {
		Coins = coins.Value,
		Wins = wins and wins.Value or 0,
		Kills = kills and kills.Value or 0
	}
	
	local success, err = pcall(function()
		CoinDataStore:SetAsync(player.UserId, data)
	end)
	
	if not success then
		warn("[LeaderstatsHandler] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	else
		print("[LeaderstatsHandler] Successfully saved data for " .. player.Name)
	end
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = leaderstats
	
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
	
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Parent = leaderstats
	
	leaderstats.Parent = player
	
	-- Load data
	local data
	local success, err = pcall(function()
		data = CoinDataStore:GetAsync(player.UserId)
	end)
	
	if success and data then
		if type(data) == "table" then
			coins.Value = data.Coins or 0
			wins.Value = data.Wins or 0
			kills.Value = data.Kills or 0
		else
			-- Legacy support: if data was just a number (coins)
			coins.Value = data
		end
		player:SetAttribute("Coins", coins.Value)
	else
		if not success then
			warn("[LeaderstatsHandler] Error loading data for " .. player.Name .. ": " .. tostring(err))
		end
		player:SetAttribute("Coins", 0)
	end
	
	-- Sync attribute to stat (for systems using attributes)
	player:GetAttributeChangedSignal("Coins"):Connect(function()
		local newValue = player:GetAttribute("Coins") or 0
		if coins.Value ~= newValue then
			coins.Value = newValue
		end
	end)
	
	-- Sync stat to attribute
	coins.Changed:Connect(function()
		if player:GetAttribute("Coins") ~= coins.Value then
			player:SetAttribute("Coins", coins.Value)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	SaveData(player)
end)

game:BindToClose(function()
	if RunService:IsStudio() then task.wait(1) return end
	
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			SaveData(player)
		end)
	end
	
	-- Wait for all saves to finish or timeout
	local start = tick()
	while #Players:GetPlayers() > 0 and tick() - start < 10 do
		task.wait(0.5)
	end
end)

-- Auto-save every 5 minutes
task.spawn(function()
	while true do
		task.wait(300)
		for _, player in ipairs(Players:GetPlayers()) do
			SaveData(player)
		end
	end
end)

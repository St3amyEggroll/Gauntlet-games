--!strict
-- GameExtrasServer — passive income (10 coins / 5 min), spin wheel, quests,
-- and settings persistence. All coin grants go through leaderstats so they
-- save via LeaderstatsHandler's PlayerCoins_V1 DataStore.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local SpinStore = DataStoreService:GetDataStore("SpinData_v1")
local QuestStore = DataStoreService:GetDataStore("Quests_v1")
local SettingsStore = DataStoreService:GetDataStore("PlayerSettings_v1")

local function ensureRemote(name: string, class: string): Instance
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local SpinRequest = ensureRemote("SpinRequest", "RemoteFunction") :: RemoteFunction
local QuestSync = ensureRemote("QuestSync", "RemoteFunction") :: RemoteFunction
local QuestClaim = ensureRemote("QuestClaim", "RemoteEvent") :: RemoteEvent
local SaveSettings = ensureRemote("SaveSettings", "RemoteEvent") :: RemoteEvent

local function addCoins(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value += amount
	else
		player:SetAttribute("Coins", (player:GetAttribute("Coins") or 0) + amount)
	end
end

--========================================================
-- SESSION STATE
--========================================================
type QuestProgress = { Progress: { [string]: number }, Claimed: { [string]: boolean }, Day: string }
local questData: { [Player]: QuestProgress } = {}
local spinReadyAt: { [Player]: number } = {}
local baselines: { [Player]: { Kills: number, Wins: number, Coins: number } } = {}

local function todayKey(): string
	return os.date("!%Y-%m-%d") :: string
end

--========================================================
-- PLAYER SETUP
--========================================================
local function loadPlayer(player: Player)
	-- Settings
	task.spawn(function()
		local ok, data = pcall(function()
			return SettingsStore:GetAsync(tostring(player.UserId))
		end)
		local s = (ok and typeof(data) == "table") and data or {}
		player:SetAttribute("Set_Master", typeof(s.Master) == "number" and s.Master or 1)
		player:SetAttribute("Set_Music", typeof(s.Music) == "number" and s.Music or 1)
		player:SetAttribute("Set_SFX", typeof(s.SFX) == "number" and s.SFX or 1)
	end)

	-- Spin cooldown
	task.spawn(function()
		local ok, last = pcall(function()
			return SpinStore:GetAsync(tostring(player.UserId))
		end)
		local lastSpin = (ok and typeof(last) == "number") and last or 0
		spinReadyAt[player] = lastSpin + GameConfig.SpinCooldown
		player:SetAttribute("SpinReadyAt", spinReadyAt[player])
	end)

	-- Quests (daily reset)
	task.spawn(function()
		local ok, data = pcall(function()
			return QuestStore:GetAsync(tostring(player.UserId))
		end)
		local qd: QuestProgress
		if ok and typeof(data) == "table" and data.Day == todayKey() then
			qd = data :: QuestProgress
		else
			qd = { Progress = {}, Claimed = {}, Day = todayKey() }
		end
		questData[player] = qd
	end)

	-- Passive income
	player:SetAttribute("NextPassiveAt", os.time() + GameConfig.PassiveInterval)

	-- Baselines for quest tracking (count only what happens this session)
	local leaderstats = player:WaitForChild("leaderstats", 15)
	if leaderstats then
		local kills = leaderstats:FindFirstChild("Kills")
		local wins = leaderstats:FindFirstChild("Wins")
		local coins = leaderstats:FindFirstChild("Coins")
		baselines[player] = {
			Kills = kills and (kills :: IntValue).Value or 0,
			Wins = wins and (wins :: IntValue).Value or 0,
			Coins = coins and (coins :: IntValue).Value or 0,
		}

		local function hook(stat: Instance?, statName: string)
			if not stat or not stat:IsA("IntValue") then return end
			stat.Changed:Connect(function()
				local base = baselines[player]
				local qd = questData[player]
				if not base or not qd then return end
				local gained = stat.Value - (base :: any)[statName]
				if gained > 0 then
					local key = statName -- "Kills" | "Wins" | "Coins"
					qd.Progress[key] = math.max(qd.Progress[key] or 0, gained)
				end
			end)
		end
		hook(kills, "Kills")
		hook(wins, "Wins")
		hook(coins, "Coins")
	end
end

local function savePlayer(player: Player)
	local qd = questData[player]
	if qd then
		pcall(function()
			QuestStore:SetAsync(tostring(player.UserId), qd)
		end)
	end
	local settings = {
		Master = player:GetAttribute("Set_Master"),
		Music = player:GetAttribute("Set_Music"),
		SFX = player:GetAttribute("Set_SFX"),
	}
	pcall(function()
		SettingsStore:SetAsync(tostring(player.UserId), settings)
	end)
	questData[player] = nil
	spinReadyAt[player] = nil
	baselines[player] = nil
end

Players.PlayerAdded:Connect(loadPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayer, p)
end
Players.PlayerRemoving:Connect(savePlayer)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(savePlayer, p)
	end
	task.wait(2)
end)

--========================================================
-- PASSIVE INCOME + PLAYTIME QUEST LOOP
--========================================================
task.spawn(function()
	while true do
		task.wait(5)
		local now = os.time()
		for _, player in ipairs(Players:GetPlayers()) do
			local nextAt = player:GetAttribute("NextPassiveAt")
			if typeof(nextAt) == "number" and now >= nextAt then
				addCoins(player, GameConfig.PassiveReward)
				player:SetAttribute("NextPassiveAt", now + GameConfig.PassiveInterval)
				player:SetAttribute("PassiveRewardPing", now) -- client toast trigger
			end

			-- playtime quest, in minutes
			local qd = questData[player]
			if qd then
				qd.Progress.Playtime = (qd.Progress.Playtime or 0) + (5 / 60)
			end
		end
	end
end)

--========================================================
-- SPIN WHEEL
--========================================================
local totalWeight = 0
for _, seg in ipairs(GameConfig.SpinSegments) do
	totalWeight += seg.Weight
end

SpinRequest.OnServerInvoke = function(player)
	local readyAt = spinReadyAt[player] or 0
	local now = os.time()
	if now < readyAt then
		return { ok = false, reason = "cooldown", readyAt = readyAt }
	end

	local roll = math.random() * totalWeight
	local acc = 0
	local index = 1
	for i, seg in ipairs(GameConfig.SpinSegments) do
		acc += seg.Weight
		if roll <= acc then
			index = i
			break
		end
	end

	local coins = GameConfig.SpinSegments[index].Coins
	addCoins(player, coins)

	spinReadyAt[player] = now + GameConfig.SpinCooldown
	player:SetAttribute("SpinReadyAt", spinReadyAt[player])
	task.spawn(function()
		pcall(function()
			SpinStore:SetAsync(tostring(player.UserId), now)
		end)
	end)

	return { ok = true, index = index, coins = coins, readyAt = spinReadyAt[player] }
end

--========================================================
-- QUESTS
--========================================================
local function questSnapshot(player: Player)
	local qd = questData[player]
	if not qd then
		return { ready = false }
	end
	local list = {}
	for _, quest in ipairs(GameConfig.Quests) do
		local progress = 0
		if quest.Type == "Playtime" then
			progress = math.floor(qd.Progress.Playtime or 0)
		else
			progress = math.floor(qd.Progress[quest.Type] or 0)
		end
		table.insert(list, {
			Key = quest.Key,
			Progress = math.min(progress, quest.Goal),
			Done = progress >= quest.Goal,
			Claimed = qd.Claimed[quest.Key] == true,
		})
	end
	return { ready = true, quests = list }
end

QuestSync.OnServerInvoke = questSnapshot

QuestClaim.OnServerEvent:Connect(function(player, questKey: string)
	local qd = questData[player]
	if not qd or typeof(questKey) ~= "string" then return end
	if qd.Claimed[questKey] then return end

	local quest = nil
	for _, q in ipairs(GameConfig.Quests) do
		if q.Key == questKey then
			quest = q
			break
		end
	end
	if not quest then return end

	local progress = quest.Type == "Playtime" and (qd.Progress.Playtime or 0) or (qd.Progress[quest.Type] or 0)
	if progress < quest.Goal then return end

	qd.Claimed[questKey] = true
	addCoins(player, quest.Reward)
	player:SetAttribute("QuestClaimPing", os.time())
end)

--========================================================
-- SETTINGS SAVE
--========================================================
SaveSettings.OnServerEvent:Connect(function(player, settings)
	if typeof(settings) ~= "table" then return end
	local function clean(v: any): number?
		return typeof(v) == "number" and math.clamp(v, 0, 1) or nil
	end
	local m, mu, s = clean(settings.Master), clean(settings.Music), clean(settings.SFX)
	if m then player:SetAttribute("Set_Master", m) end
	if mu then player:SetAttribute("Set_Music", mu) end
	if s then player:SetAttribute("Set_SFX", s) end
end)

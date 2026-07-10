--!strict
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RewardDataStore = DataStoreService:GetDataStore("DailyRewards_v1")

local ClaimRewardEvent = ReplicatedStorage:FindFirstChild("ClaimDailyReward") or Instance.new("RemoteEvent", ReplicatedStorage)
ClaimRewardEvent.Name = "ClaimDailyReward"

local GetRewardStatus = ReplicatedStorage:FindFirstChild("GetDailyRewardStatus") or Instance.new("RemoteFunction", ReplicatedStorage)
GetRewardStatus.Name = "GetDailyRewardStatus"

local COOLDOWN_SECONDS = 86400  -- 24 hours
local RESET_SECONDS = 172800    -- 48 hours (Missing this window resets the streak)

local function getStatus(player: Player)
	local success, data = pcall(function()
		return RewardDataStore:GetAsync(tostring(player.UserId))
	end)

	if success and type(data) == "number" then
		data = { LastClaim = data, Streak = 1 }
	elseif not success or type(data) ~= "table" then
		data = { LastClaim = 0, Streak = 0 }
	end

	local currentTime = os.time()
	local lastClaim = data.LastClaim or 0
	local streak = data.Streak or 0

	local timePassed = currentTime - lastClaim
	local canClaim = false
	local timeLeft = 0
	local currentDay = 1

	if lastClaim == 0 then
		canClaim = true
		currentDay = 1
	elseif timePassed >= COOLDOWN_SECONDS then
		canClaim = true
		if timePassed >= RESET_SECONDS then
			currentDay = 1
		else
			currentDay = streak + 1
			if currentDay > 5 then
				currentDay = 1
			end
		end
	else
		canClaim = false
		timeLeft = COOLDOWN_SECONDS - timePassed
		currentDay = streak + 1
		if currentDay > 5 then
			currentDay = 1
		end
	end

	return {
		CanClaim = canClaim,
		TimeLeft = math.max(0, math.floor(timeLeft)),
		CurrentDay = currentDay,
		RewardAmount = currentDay * 5
	}
end

GetRewardStatus.OnServerInvoke = getStatus

ClaimRewardEvent.OnServerEvent:Connect(function(player)
	local status = getStatus(player)

	if status.CanClaim then
		local currentCoins = player:GetAttribute("Coins") or 0
		player:SetAttribute("Coins", currentCoins + status.RewardAmount)

		local saveData = {
			LastClaim = os.time(),
			Streak = status.CurrentDay
		}

			local saveSuccess, err = pcall(function()
				RewardDataStore:SetAsync(tostring(player.UserId), saveData)
			end)

			if not saveSuccess then
				warn("Failed to save daily reward data for " .. player.Name .. ": " .. tostring(err))
			end

			print(player.Name .. " claimed Day " .. status.CurrentDay .. " reward of " .. status.RewardAmount .. " coins.")
	else
		warn(player.Name .. " tried to claim reward early. Seconds left: " .. status.TimeLeft)
	end
end)
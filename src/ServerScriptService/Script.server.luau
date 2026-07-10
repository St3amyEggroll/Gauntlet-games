-- Server-side script (in a Script, not a LocalScript)
local RoundManager = script -- Or however you get your RoundManager
local NoJoinRoundEvent = script:FindFirstChild("NoJoinRoundEvent") or Instance.new("RemoteEvent", script)
NoJoinRoundEvent.Name = "NoJoinRoundEvent"

local NoJoinPlayers = {} -- Table to store players who don't want to join

local function onNoJoinRound(player, shouldNoJoin)
	if shouldNoJoin then
		-- Player wants to be excluded from the round
		NoJoinPlayers[player.UserId] = true -- Use UserId as key
		print(player.Name .. " does not want to join the round.")
	else
		-- Player wants to join the round
		NoJoinPlayers[player.UserId] = nil -- Remove the player from the table
		print(player.Name .. " wants to join the round.")
	end
end

NoJoinRoundEvent.OnServerEvent:Connect(onNoJoinRound)

-- Example: In your round starting logic, check this table:
local function startRound()
	print("Starting round...")
	local playersToInclude = {}
	for _, player in ipairs(game.Players:GetPlayers()) do
		if NoJoinPlayers[player.UserId] == nil then -- nil means they are not in the NoJoinPlayers table
			table.insert(playersToInclude, player)
		else
			print(player.Name .. " is excluded from this round.")
		end
	end
	-- Use 'playersToInclude' to start the round with the correct players.
	for i, player in ipairs(playersToInclude) do
		print("Included " .. player.Name .. " in the round")
	end
	-- Your round start logic here
end

-- Example of how to use the startRound function
function BeginRound()
	startRound()
end
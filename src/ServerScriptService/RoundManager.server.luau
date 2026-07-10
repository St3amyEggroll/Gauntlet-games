local localStatus = game.ReplicatedStorage.Stat
-- CHANGED: Now uses WaitForChild to ensure Maps is a member of ReplicatedStorage
local maps = game.ReplicatedStorage:WaitForChild("Maps"):GetChildren()
local DataStoreService = game:GetService("DataStoreService")
local winsDataStore = DataStoreService:GetDataStore("PlayerWins")
local coinsDataStore = DataStoreService:GetDataStore("PlayerCoins")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local roundWinReward = 25
local delay = 20
local minimumPlayersToStart = 2
local selectionTime = 10

local KillEvent = ReplicatedStorage:WaitForChild("KillEvent")
local SpectateSync = ReplicatedStorage:WaitForChild("SpectateSync")

-- ============================================================================
-- MAP ENVIRONMENT CONFIGURATION (Skyboxes, Music & Ambient)
-- ============================================================================
-- THE COLOR PICKERS ARE BELOW
-- You can now click the colored squares next to the Color3.fromRGB lines to pick a color!
local MAP_THEMES = {
	["Nuclear Plant"] = {
		MusicId = "rbxassetid://140662001078259",
		Ambient = Color3.fromRGB(39, 102, 22),
		OutdoorAmbient = Color3.fromRGB(39, 102, 22),
		Brightness = 0.2,
		Skybox = {
			SkyboxBk = "rbxassetid://11941775243",
			SkyboxDn = "rbxassetid://11941774975",
			SkyboxFt = "rbxassetid://11941774655",
			SkyboxLf = "rbxassetid://11941774369",
			SkyboxRt = "rbxassetid://11941774042",
			SkyboxUp = "rbxassetid://11941773718"
		}
	},
	["Sinking Ship"] = {
		MusicId = "rbxassetid://89514398603321", 
		Ambient = Color3.fromRGB(0, 0, 0),
		OutdoorAmbient = Color3.fromRGB(0, 0, 0),
		Brightness = 0.08,
		Skybox = {
			SkyboxBk = "rbxassetid://1014344",
			SkyboxDn = "rbxassetid://1014344",
			SkyboxFt = "rbxassetid://1014344",
			SkyboxLf = "rbxassetid://1014344",
			SkyboxRt = "rbxassetid://1014344",
			SkyboxUp = "rbxassetid://1014344"
		}
	},
	["City"] = {
		MusicId = "rbxassetid://140399422898344", 
		Ambient = Color3.fromRGB(6, 17, 182),
		OutdoorAmbient = Color3.fromRGB(0, 0, 0),
		Brightness = 0.08,
		Skybox = {
			SkyboxBk = "rbxassetid://12064107",
			SkyboxDn = "rbxassetid://12064152",
			SkyboxFt = "rbxassetid://12064121",
			SkyboxLf = "rbxassetid://12063984",
			SkyboxRt = "rbxassetid://12064115",
			SkyboxUp = "rbxassetid://12064131"
		}
	},
	["Crane"] = {
		MusicId = "rbxassetid://140228184971194", 
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Skybox = {
			SkyboxBk = "rbxassetid://271042516",
			SkyboxDn = "rbxassetid://271077243",
			SkyboxFt = "rbxassetid://271042556",
			SkyboxLf = "rbxassetid://271042310",
			SkyboxRt = "rbxassetid://271042467",
			SkyboxUp = "rbxassetid://271077958"
		}
	},
	["Dinner Table"] = {
		MusicId = "rbxassetid://1848028342", 
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Skybox = {
			SkyboxBk = "rbxassetid://129337684272305",
			SkyboxDn = "rbxassetid://81970274034692",
			SkyboxFt = "rbxassetid://106604582088111",
			SkyboxLf = "rbxassetid://139407886515901",
			SkyboxRt = "rbxassetid://87166111951608",
			SkyboxUp = "rbxassetid://87944750029450"
		}
	},
	["Island"] = {
		MusicId = "rbxassetid://1839921975", 
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Skybox = {
			SkyboxBk = "rbxassetid://58372690",
			SkyboxDn = "rbxassetid://58372722",
			SkyboxFt = "rbxassetid://58372742",
			SkyboxLf = "rbxassetid://58372777",
			SkyboxRt = "rbxassetid://58372794",
			SkyboxUp = "rbxassetid://58372812"
		}
	},
	["Pirate Ships"] = {
		MusicId = "rbxassetid://1835322563", 
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Skybox = {
			SkyboxBk = "rbxassetid://150283828",
			SkyboxDn = "rbxassetid://150283728",
			SkyboxFt = "rbxassetid://150283781",
			SkyboxLf = "rbxassetid://150283702",
			SkyboxRt = "rbxassetid://150283748",
			SkyboxUp = "rbxassetid://150283877"
		}
	},
	["Pyramid"] = {
		MusicId = "rbxassetid://132982807182450", 
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Skybox = {
			SkyboxBk = "rbxassetid://921878400",
			SkyboxDn = "rbxassetid://921878168",
			SkyboxFt = "rbxassetid://921878504",
			SkyboxLf = "rbxassetid://921878103",
			SkyboxRt = "rbxassetid://921878250",
			SkyboxUp = "rbxassetid://921878634"
		}
	},
	["Skyscraper"] = {
		MusicId = "rbxassetid://85837065623863", 
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Skybox = {
			SkyboxBk = "rbxassetid://58372690",
			SkyboxDn = "rbxassetid://58372722",
			SkyboxFt = "rbxassetid://58372742",
			SkyboxLf = "rbxassetid://58372777",
			SkyboxRt = "rbxassetid://58372794",
			SkyboxUp = "rbxassetid://58372812"
		}
	},
	["Boxing Ring"] = {
		MusicId = "rbxassetid://102541608932632", 
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Skybox = {
			SkyboxBk = "rbxassetid://0",
			SkyboxDn = "rbxassetid://0",
			SkyboxFt = "rbxassetid://0",
			SkyboxLf = "rbxassetid://0",
			SkyboxRt = "rbxassetid://0",
			SkyboxUp = "rbxassetid://0"
		}
	},
	["Mountain Side"] = {
		MusicId = "rbxassetid://70872914929613", 
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Skybox = {
			SkyboxBk = "rbxassetid://1361097",
			SkyboxDn = "rbxassetid://1361097",
			SkyboxFt = "rbxassetid://1361097",
			SkyboxLf = "rbxassetid://1361097",
			SkyboxRt = "rbxassetid://1361097",
			SkyboxUp = "rbxassetid://1361097"
		}
	},
	["Train"] = {
		MusicId = "rbxassetid://9039704032", 
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Skybox = {
			SkyboxBk = "rbxassetid://566598488",
			SkyboxDn = "rbxassetid://566598717",
			SkyboxFt = "rbxassetid://566598536",
			SkyboxLf = "rbxassetid://566598581",
			SkyboxRt = "rbxassetid://566598640",
			SkyboxUp = "rbxassetid://566598894"
		}
	},
}

-- Default Audio Track configuration for your Lobby
local LOBBY_MUSIC_ID = "rbxassetid://1846271108" -- Replace with your default Lobby Audio ID

-- Initialize Background Music Channel
local backgroundMusic = Instance.new("Sound")
backgroundMusic.Name = "RoundManagerMusic"
backgroundMusic.SoundId = LOBBY_MUSIC_ID
backgroundMusic.Volume = 0.5
backgroundMusic.Looped = true
backgroundMusic.Parent = workspace
backgroundMusic:Play()

-- Environment cleanup backup storage
local originalSkybox = nil
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalBrightness = Lighting.Brightness

-- Cache the default lobby skybox if it already exists
if Lighting:FindFirstChildOfClass("Sky") then
	originalSkybox = Lighting:FindFirstChildOfClass("Sky"):Clone()
end

-- UTILITY FUNCTION: Seamlessly fade and transition background music tracks
local function transitionMusic(newSoundId)
	if backgroundMusic.SoundId == newSoundId then return end

	-- Fade Out Current Track
	local fadeOut = TweenService:Create(backgroundMusic, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {Volume = 0})
	fadeOut:Play()
	fadeOut.Completed:Wait()

	-- Swap Asset Track and Fade In
	backgroundMusic.SoundId = newSoundId
	backgroundMusic:Play()

	local fadeIn = TweenService:Create(backgroundMusic, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {Volume = 0.5})
	fadeIn:Play()
end

-- UTILITY FUNCTION: Clear out existing skyboxes and drop in custom themes
local function applyMapEnvironment(mapName)
	local theme = MAP_THEMES[mapName]

	-- 1. Handle Music Track Changes
	if theme and theme.MusicId then
		task.spawn(transitionMusic, theme.MusicId)
	else
		task.spawn(transitionMusic, LOBBY_MUSIC_ID)
	end

	-- 2. Handle Custom Skybox Changes
	if theme and theme.Skybox then
		-- Delete existing skyboxes in Lighting
		for _, child in ipairs(Lighting:GetChildren()) do
			if child:IsA("Sky") then
				child:Destroy()
			end
		end

		-- Construct the new structural skybox object mapping
		local newSky = Instance.new("Sky")
		newSky.Name = "ActiveMapSkybox"
		newSky.SkyboxBk = theme.Skybox.SkyboxBk
		newSky.SkyboxDn = theme.Skybox.SkyboxDn
		newSky.SkyboxFt = theme.Skybox.SkyboxFt
		newSky.SkyboxLf = theme.Skybox.SkyboxLf
		newSky.SkyboxRt = theme.Skybox.SkyboxRt
		newSky.SkyboxUp = theme.Skybox.SkyboxUp
		newSky.Parent = Lighting
	end

	-- 3. Handle Ambient Changes
	if theme then
		if theme.Ambient then
			Lighting.Ambient = theme.Ambient
		end
		if theme.OutdoorAmbient then
			Lighting.OutdoorAmbient = theme.OutdoorAmbient
		end
		if theme.Brightness then
			Lighting.Brightness = theme.Brightness
		end
	end
end

-- UTILITY FUNCTION: Clean the match workspace environment back to base state
local function resetEnvironment()
	-- Return to baseline Lobby tracks
	task.spawn(transitionMusic, LOBBY_MUSIC_ID)

	-- Clean custom map skyboxes
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end

	-- Reinstate original base lobby sky layout
	if originalSkybox then
		originalSkybox:Clone().Parent = Lighting
	end

	-- Reset lighting properties
	Lighting.Ambient = originalAmbient
	Lighting.OutdoorAmbient = originalOutdoorAmbient
	Lighting.Brightness = originalBrightness
end
-- ============================================================================

local function freezeCharacter(character, shouldFreeze)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = shouldFreeze
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = shouldFreeze and 0 or 16
		humanoid.JumpPower = shouldFreeze and 0 or 50
	end
end

local function loadPlayerData(player)
	local successWins, storedWins = pcall(function()
		return winsDataStore:GetAsync(player.UserId)
	end)
	
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		warn("[RoundManager] leaderstats not found for " .. player.Name)
		return
	end

	if successWins and storedWins ~= nil then
		leaderstats.Wins.Value = storedWins
	else
		leaderstats.Wins.Value = 0
	end

	local successCoins, storedCoins = pcall(function()
		return coinsDataStore:GetAsync(player.UserId)
	end)
	if successCoins and storedCoins ~= nil then
		player:SetAttribute("Coins", storedCoins)
		if leaderstats:FindFirstChild("Coins") then
			leaderstats.Coins.Value = storedCoins
		end
	else
		player:SetAttribute("Coins", 0)
		if leaderstats:FindFirstChild("Coins") then
			leaderstats.Coins.Value = 0
		end
	end
end

local function saveData(player)
	local successWins, errorMessageWins = pcall(function()
		winsDataStore:SetAsync(player.UserId, player.leaderstats.Wins.Value)
	end)
	if not successWins then
		warn("Failed to save wins for " .. player.Name .. ": " .. errorMessageWins)
	end

	local coinsValue = player.leaderstats:FindFirstChild("Coins") and player.leaderstats.Coins.Value or player:GetAttribute("Coins") or 0
	local successCoins, errorMessageCoins = pcall(function()
		coinsDataStore:SetAsync(player.UserId, coinsValue)
	end)
	if not successCoins then
		warn("Failed to save coins for " .. player.Name .. ": " .. errorMessageCoins)
	end
end

local StartMapVote = ReplicatedStorage:WaitForChild("StartMapVote")
local SubmitMapVote = ReplicatedStorage:WaitForChild("SubmitMapVote")
local TutorialCompleteEvent = ReplicatedStorage:WaitForChild("TutorialCompleteEvent")

TutorialCompleteEvent.OnServerEvent:Connect(function(player)
	player:SetAttribute("TutorialComplete", true)
	print("[RoundManager] Tutorial complete for " .. player.Name)
end)

local votes = {}
local UpdateMapVotes = ReplicatedStorage:WaitForChild("UpdateMapVotes")
local OpenGauntletSelection = ReplicatedStorage:WaitForChild("OpenGauntletSelection")

SubmitMapVote.OnServerEvent:Connect(function(player, mapIndex)
	votes[player.UserId] = mapIndex
	UpdateMapVotes:FireAllClients(votes)
end)

-- Handle player selection
ReplicatedStorage:WaitForChild("SelectGauntlet").OnServerEvent:Connect(function(player, gauntletName)
	local gauntlet = ReplicatedStorage.Gauntlets:FindFirstChild(gauntletName)
	if gauntlet then
		player:SetAttribute("EquippedGauntlet", gauntletName)
		print("[RoundManager] Player " .. player.Name .. " selected " .. gauntletName)
	end
end)

-- Handle spectator target tracking
SpectateSync.OnServerEvent:Connect(function(player, targetPlayer)
	player:SetAttribute("SpectatingTarget", targetPlayer)

	-- Refresh all counts more reliably
	local counts = {}
	for _, p in ipairs(game.Players:GetPlayers()) do
		counts[p] = 0
	end

	for _, p in ipairs(game.Players:GetPlayers()) do
		local target = p:GetAttribute("SpectatingTarget")
		if target and target:IsA("Player") then
			counts[target] = (counts[target] or 0) + 1
		end
	end

	for p, count in pairs(counts) do
		p:SetAttribute("SpectatorCount", count)
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	-- Clear attributes on leave to prevent ghost counts
	player:SetAttribute("SpectatingTarget", nil)
	
	-- Tiny delay to let PlayerRemoving finish so the count loop below sees the true remaining player list
	task.defer(function()
		local counts = {}
		local allPlayers = game.Players:GetPlayers()
		for _, p in ipairs(allPlayers) do
			counts[p] = 0
		end

		for _, p in ipairs(allPlayers) do
			local target = p:GetAttribute("SpectatingTarget")
			if target and target:IsA("Player") then
				counts[target] = (counts[target] or 0) + 1
			end
		end

		for p, count in pairs(counts) do
			p:SetAttribute("SpectatorCount", count)
		end
	end)
end)

local function giveEquippedGauntlet(player)
	local gauntletName = player:GetAttribute("EquippedGauntlet")
	if not gauntletName then
		-- Default gauntlet if none picked
		gauntletName = "Starter Gauntlet"
	end

	local gauntletTemplate = ReplicatedStorage.Gauntlets:FindFirstChild(gauntletName)
	if gauntletTemplate then
		local gauntlet = gauntletTemplate:Clone()
		gauntlet:SetAttribute("IsGauntlet", true)
		gauntlet.Parent = player.Backpack
		print("[RoundManager] Gave " .. gauntletName .. " to " .. player.Name)
	end
end

local function removeGauntlets(player)
	if player.Character then
		for _, tool in ipairs(player.Backpack:GetChildren()) do
			if tool:GetAttribute("IsGauntlet") then
				tool:Destroy()
			end
		end
		local charTool = player.Character:FindFirstChildOfClass("Tool")
		if charTool and charTool:GetAttribute("IsGauntlet") then
			charTool:Destroy()
		end
	end
end

-- Handle player joining
game.Players.PlayerAdded:Connect(function(player)
	loadPlayerData(player)
	
	if player.UserId == 1693774950 then
		player:SetAttribute("Coins", 0) -- 10 billion
	end
	
	player:SetAttribute("SpectatorCount", 0)

	player.CharacterAdded:Connect(function(character)
		local spawnLoc
		local lobbySpawnsFolder = workspace:FindFirstChild("LobbySpawns")
		
		-- Check if we are in the middle of a match (Teleports exists)
		if workspace:FindFirstChild("Teleports") and #workspace.Teleports:GetChildren() > 0 then
			local teleports = workspace.Teleports:GetChildren()
			spawnLoc = teleports[math.random(1, #teleports)]
		elseif lobbySpawnsFolder then
			local lobbySpawns = lobbySpawnsFolder:GetChildren()
			if #lobbySpawns > 0 then
				spawnLoc = lobbySpawns[math.random(1, #lobbySpawns)]
			else
				-- Internal fallback to the specific lobby model spawn if the folder is empty
				local backupSpawn = workspace:FindFirstChild("lobby") 
					and workspace.lobby:FindFirstChild("Lobby")
					and workspace.lobby.Lobby:FindFirstChild("Paths")
					and workspace.lobby.Lobby.Paths:FindFirstChild("Spawn point")
				spawnLoc = backupSpawn
			end
		end

		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if spawnLoc and hrp then
			-- Force character to the spawn location and keep trying for 2 seconds to overcome any default spawning logic
			task.spawn(function()
				local startTime = os.clock()
				local targetCFrame = spawnLoc:IsA("Model") and (spawnLoc:GetPrimaryPartCFrame() or spawnLoc:GetPivot()) or spawnLoc.CFrame
				
				while os.clock() - startTime < 2.5 do
					if not character or not character.Parent then break end
					character:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
					task.wait(0.05) -- Faster polling to ensure we beat internal engine repositions
				end
			end)
		end

		character.Parent = workspace.Ingame

		-- Clear gauntlets on death
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			removeGauntlets(player)
			
			-- Wait a bit then reload character to lobby if match is active
			task.delay(3, function()
				if player.Parent then
					player:LoadCharacter()
				end
			end)
			local creator = character.Humanoid:FindFirstChild("creator")
			if creator and creator:IsA("ObjectValue") and creator.Value then
				local killer = creator.Value
				if killer:IsA("Player") then
					-- Reward coins
					local coinsValue = killer:GetAttribute("Coins") or 0
					killer:SetAttribute("Coins", coinsValue + 5)
					
					-- Increment kills
					local kLeaderstats = killer:FindFirstChild("leaderstats")
					if kLeaderstats then
						local killsStat = kLeaderstats:FindFirstChild("Kills")
						if killsStat then
							killsStat.Value += 1
						end
					end

					KillEvent:FireAllClients(killer.Name, player.Name)
				end
			end
		end)
	end)

	player.CharacterRemoving:Connect(function()
		if player.Character and player.Character.Parent == workspace.Ingame then
			player.Character.Parent = nil
		end
	end)
end)

game.Players.PlayerRemoving:Connect(function(player)
	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Wins") then
		saveData(player)
	end
end)

local lastMapName = ""
local OpenGauntletSelection = ReplicatedStorage:WaitForChild("OpenGauntletSelection")

-- Set MatchActive attribute for spectate system
workspace:SetAttribute("MatchActive", false)

while true do
	local currentPlayers = game.Players:GetPlayers()
	if #currentPlayers < minimumPlayersToStart then
		localStatus.Value = "Waiting for more players... (" .. #currentPlayers .. "/" .. minimumPlayersToStart .. " needed)"
		repeat
			task.wait(5)
			currentPlayers = game.Players:GetPlayers()
			localStatus.Value = "Waiting for more players... (" .. #currentPlayers .. "/" .. minimumPlayersToStart .. " needed)"
		until #currentPlayers >= minimumPlayersToStart
	end

	for i = 1, delay do
		localStatus.Value = "Match starts in.. " .. (delay - i)
		task.wait(1)
	end

	-- Map Voting Phase
	local mapOptions = {}
	local availableMapsForVote = {}
	for _, map in ipairs(maps) do
		table.insert(availableMapsForVote, map)
	end

	for i = 1, 3 do
		if #availableMapsForVote > 0 then
			local index = math.random(1, #availableMapsForVote)
			table.insert(mapOptions, availableMapsForVote[index].Name)
			table.remove(availableMapsForVote, index)
		end
	end

	votes = {}
	StartMapVote:FireAllClients(mapOptions, 10)

	for i = 10, 1, -1 do
		localStatus.Value = "Map voting.. " .. i
		task.wait(1)
	end

	local voteCounts = {0, 0, 0}
	for _, voteIndex in pairs(votes) do
		if voteCounts[voteIndex] then
			voteCounts[voteIndex] += 1
		end
	end

	local winningIndex = 1
	local maxVotes = -1
	for i, count in ipairs(voteCounts) do
		if count > maxVotes then
			maxVotes = count
			winningIndex = i
		elseif count == maxVotes and math.random() > 0.5 then
			winningIndex = i
		end
	end

	local selectedMapName = mapOptions[winningIndex]
	local selectedMapTemplate = ReplicatedStorage.Maps:FindFirstChild(selectedMapName)
	if not selectedMapTemplate then
		selectedMapTemplate = maps[math.random(1, #maps)]
	end

	local selectedMap = selectedMapTemplate:Clone()
	lastMapName = selectedMap.Name
	selectedMap.Parent = workspace

	local teleports = selectedMap:FindFirstChild("Teleports"):Clone()
	if teleports then
		teleports.Parent = workspace
		teleports.Name = "Teleports"
	else
		warn("Map '" .. selectedMap.Name .. "' has no 'Teleports' folder. Skipping map.")
		selectedMap:Destroy()
		task.wait(2)
		continue
	end

	localStatus.Value = "Map chosen: " .. selectedMap.Name

	-- DYNAMIC ENVIRONMENTAL TRANSITION CALL
	applyMapEnvironment(selectedMap.Name)

	task.wait(2)

	local spawnPoints = teleports:GetChildren()
	local availableSpawns = {}
	for _, spawn in ipairs(spawnPoints) do
		table.insert(availableSpawns, spawn)
	end

	local players = game.Players:GetPlayers()
	local participants = {}
	for _, player in ipairs(players) do
		if player:GetAttribute("IsAFK") == true then
			continue
		end
		
		local winsStat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Wins")
		local coinsStat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
		
		local wins = winsStat and winsStat.Value or 0
		local coins = coinsStat and coinsStat.Value or 0
		local isNewPlayer = (wins == 0) and (coins == 0)
		
		if isNewPlayer and not player:GetAttribute("TutorialComplete") then
			print("[RoundManager] Skipping player " .. player.Name .. " - Tutorial not complete.")
			continue
		end

		local character = player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			player:LoadCharacter()
			character = player.Character
			if not character then
				task.wait(0.5)
				character = player.Character
			end
		end

		if character and character:FindFirstChild("HumanoidRootPart") then
			table.insert(participants, player)

			local spawnPoint
			if #availableSpawns > 0 then
				local index = math.random(1, #availableSpawns)
				spawnPoint = availableSpawns[index]
				table.remove(availableSpawns, index)
			else
				-- Fallback if more players than spawns
				spawnPoint = spawnPoints[math.random(1, #spawnPoints)]
			end

			local pos = spawnPoint.CFrame * CFrame.new(0, 3, 0)
			character:SetPrimaryPartCFrame(pos)
			character.Parent = workspace.Ingame
			freezeCharacter(character, true)

			-- Remove any existing gauntlets before round
			removeGauntlets(player)
			-- Reset selection
			player:SetAttribute("EquippedGauntlet", nil)
		end
	end

	-- Open Selection UI for participants
	for _, player in ipairs(participants) do
		OpenGauntletSelection:FireClient(player, selectionTime)
	end

	workspace:SetAttribute("MatchActive", true)

	-- Selection countdown
	local selectionFinished = false
	task.spawn(function()
		for i = selectionTime, 1, -1 do
			if selectionFinished then break end
			localStatus.Value = "Pick your gauntlet! (" .. i .. ")"
			task.wait(1)
		end
		selectionFinished = true
	end)

	-- Check if everyone selected
	local startTime = os.clock()
	while os.clock() - startTime < selectionTime do
		local allSelected = true
		for _, player in ipairs(participants) do
			if not player:GetAttribute("EquippedGauntlet") then
				allSelected = false
				break
			end
		end

		if allSelected and #participants > 0 then
			selectionFinished = true
			break
		end
		task.wait(0.5)
	end
	selectionFinished = true

	-- Random selection for those who didn't pick
	for _, player in ipairs(participants) do
		if not player:GetAttribute("EquippedGauntlet") then
			local owned = {}
			
			-- Server-authoritative check for owned tools
			local success, result = pcall(function()
				local PurchasedItemsDataStore = DataStoreService:GetDataStore("PurchasedItems")
				return PurchasedItemsDataStore:GetAsync(player.UserId)
			end)
			
			if success and type(result) == "table" then
				owned = result
			end
			
			-- Ensure Starter Gauntlet is always an option if nothing else is found
			if not table.find(owned, "Starter Gauntlet") then
				table.insert(owned, "Starter Gauntlet")
			end
			
			local randomGauntlet = owned[math.random(1, #owned)]
			player:SetAttribute("EquippedGauntlet", randomGauntlet)
			print("[RoundManager] Randomly selected " .. randomGauntlet .. " for " .. player.Name)
		end
	end

	for _, player in ipairs(participants) do
		if player.Character then
			freezeCharacter(player.Character, false)
			-- Give equipped gauntlet when fight starts
			giveEquippedGauntlet(player)
			
			-- Force equip the gauntlet
			task.spawn(function()
				local character = player.Character
				if not character then return end
				local humanoid = character:WaitForChild("Humanoid")
				
				while workspace:GetAttribute("MatchActive") and character.Parent == workspace.Ingame do
					local currentTool = character:FindFirstChildOfClass("Tool")
					if not currentTool or not currentTool:GetAttribute("IsGauntlet") then
						local backpackTool = player.Backpack:FindFirstChildWhichIsA("Tool")
						if backpackTool and backpackTool:GetAttribute("IsGauntlet") then
							humanoid:EquipTool(backpackTool)
						end
					end
					task.wait(0.5)
				end
			end)
		end
	end

	localStatus.Value = "Fight!"
	local regenEvent = ReplicatedStorage:FindFirstChild("Regen")
	if regenEvent then
		regenEvent:FireAllClients()
	end
	task.wait(1)

	-- INITIALIZE MAP VARIABLES AT THE START OF THE FIGHT
	local acidTween = nil
	local waterTween = nil

	-- Rising Acid logic for Nuclear Plant
	if selectedMap.Name == "Nuclear Plant" then
		local acid = selectedMap:FindFirstChild("RisingAcid")
		local acidEnd = selectedMap:FindFirstChild("RisingAcidEnd")

		if acid and acidEnd then
			local duration = 90

			local tweenInfo = TweenInfo.new(
				duration,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.InOut
			)

			-- This moves it perfectly to the exact CFrame (Position + Rotation) of the end part
			acidTween = TweenService:Create(acid, tweenInfo, {CFrame = acidEnd.CFrame})
			acidTween:Play()
		end
	end

	-- Sinking Ship logic
	if selectedMap.Name == "Sinking Ship" then
		local water = selectedMap:FindFirstChild("SinkingWater")
		local waterEnd = selectedMap:FindFirstChild("SinkingWaterEnd")

		if water and waterEnd then
			local duration = 90

			local tweenInfo = TweenInfo.new(
				duration,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.InOut
			)

			-- This moves the water perfectly to the exact CFrame of the end part over 90 seconds
			waterTween = TweenService:Create(water, tweenInfo, {CFrame = waterEnd.CFrame})
			waterTween:Play()
		end
	end

	-- Countdown loop for active match
	local roundTime = 120
	repeat
		roundTime = roundTime - 1
		localStatus.Value = "Time left.. " .. roundTime
		task.wait(1)
	until roundTime == 0 or #workspace.Ingame:GetChildren() <= 1

	localStatus.Value = "Match Over."
	task.wait(0.1)

	-- Handle match conclusion and rewards
	local alivePlayers = workspace.Ingame:GetChildren()
	if #alivePlayers == 1 then
		local winnerChar = alivePlayers[1]
		local winner = game.Players:GetPlayerFromCharacter(winnerChar)
		
		if winner then
			local leaderstats = winner:FindFirstChild("leaderstats")
			if leaderstats then
				local winsStat = leaderstats:FindFirstChild("Wins")
				if winsStat then
					winsStat.Value += 1
					print("[RoundManager] Awarded win to " .. winner.Name .. ". New total: " .. winsStat.Value)
				else
					warn("[RoundManager] Wins stat missing for " .. winner.Name)
				end
			end
			
			local coinsValue = winner:GetAttribute("Coins") or 0
			winner:SetAttribute("Coins", coinsValue + roundWinReward)
			localStatus.Value = winner.Name .. " wins!"
		else
			warn("[RoundManager] Could not find player for character: " .. winnerChar.Name)
		end
	elseif #alivePlayers == 0 then
		localStatus.Value = "No players remaining!"
	end

	task.wait(1)

	-- CLEANUP ACTIVE TWEENS BEFORE DESTROYING THE MAP Assets
	if acidTween then
		acidTween:Cancel()
	end

	if waterTween then
		waterTween:Cancel()
	end

	selectedMap:Destroy()
	if workspace:FindFirstChild("Teleports") then
		workspace.Teleports:Destroy()
	end

	workspace:SetAttribute("MatchActive", false)

	-- RESET MAP ENVIRONMENT BACK TO DEFAULT LOBBY STATE
	resetEnvironment()

	for _, player in ipairs(game.Players:GetPlayers()) do
		-- Remove gauntlets when round ends
		removeGauntlets(player)
		
		-- Only reload if they are in the game or dead
		if player.Character and player.Character.Parent == workspace.Ingame then
			player:LoadCharacter()
		elseif not player.Character then
			player:LoadCharacter()
		end
	end
end
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
repeat task.wait() until player.Character and player.Character.PrimaryPart

local soundRegionsFolder = workspace:FindFirstChild("SoundRegions")
local interactiveRegionsFolder = workspace:FindFirstChild("InteractiveMusicRegions")

print("[MusicRegions] Initialized. Folders: SoundRegions=" .. tostring(soundRegionsFolder ~= nil) .. ", Interactive=" .. tostring(interactiveRegionsFolder ~= nil))

local currentSongPlaying = nil -- The region PART currently active
local songClonePlay = nil
local currentTween = nil
local TWEEN_INFO = TweenInfo.new(1.5)

local currentPlaylist = {}
local playlistIndex = 1

-- Geometric check for point inside a Part (including rotation)
local function isPointInPart(point, part)
	local relative = part.CFrame:PointToObjectSpace(point)
	local size = part.Size
	return math.abs(relative.X) <= size.X/2 and 
	       math.abs(relative.Y) <= size.Y/2 and 
	       math.abs(relative.Z) <= size.Z/2
end

local function getActiveRegion()
	if not player.Character or not player.Character.PrimaryPart then return nil end
	local pos = player.Character.PrimaryPart.Position
	
	if not interactiveRegionsFolder then return nil end
	
	-- Iterate through all region parts
	for _, region in interactiveRegionsFolder:GetChildren() do
		if region:IsA("BasePart") and isPointInPart(pos, region) then
			return region
		end
	end
	
	return nil
end

local function stopCurrentSong()
	if not currentSongPlaying then return end
	
	print("[MusicRegions] Leaving region:", currentSongPlaying.Name)
	
	local oldSong = songClonePlay
	local oldRegion = currentSongPlaying
	
	currentSongPlaying = nil
	songClonePlay = nil
	currentPlaylist = {}
	
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end
	
	if oldSong then
		local fadeOut = TweenService:Create(oldSong, TWEEN_INFO, {Volume = 0})
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			oldSong:Stop()
			oldSong:Destroy()
			print("[MusicRegions] Sound destroyed for:", oldRegion.Name)
		end)
	end
end

local function playNextInPlaylist()
	if not currentSongPlaying or #currentPlaylist == 0 then return end
	
	playlistIndex = playlistIndex + 1
	if playlistIndex > #currentPlaylist then
		playlistIndex = 1
	end
	
	local nextSoundTemplate = currentPlaylist[playlistIndex]
	if not nextSoundTemplate then return end

	local oldSong = songClonePlay
	if oldSong then
		local fadeOut = TweenService:Create(oldSong, TWEEN_INFO, {Volume = 0})
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			oldSong:Stop()
			oldSong:Destroy()
		end)
	end

	songClonePlay = nextSoundTemplate:Clone()
	songClonePlay.Volume = 0
	songClonePlay.Looped = false -- Let it move to next naturally
	songClonePlay.Parent = script
	songClonePlay:Play()

	local targetVolume = nextSoundTemplate.Volume > 0 and nextSoundTemplate.Volume or 0.5
	currentTween = TweenService:Create(songClonePlay, TWEEN_INFO, {Volume = targetVolume})
	currentTween:Play()

	songClonePlay.Ended:Connect(function()
		if songClonePlay and songClonePlay.Parent == script then
			playNextInPlaylist()
		end
	end)
end

local function playRegionMusic(region)
	if currentSongPlaying == region then return end
	
	print("[MusicRegions] Entering region:", region.Name)
	
	-- If switching directly between regions, stop old one first
	if currentSongPlaying then
		stopCurrentSong()
	end
	
	-- Find sound source asset or playlist
	local playlistFolder = soundRegionsFolder and soundRegionsFolder:FindFirstChild(region.Name .. "Playlist")
	local soundSource = soundRegionsFolder and soundRegionsFolder:FindFirstChild(region.Name)

	if playlistFolder and playlistFolder:IsA("Folder") then
		currentSongPlaying = region
		currentPlaylist = {}
		for _, sound in playlistFolder:GetChildren() do
			if sound:IsA("Sound") then
				table.insert(currentPlaylist, sound)
			end
		end
		
		if #currentPlaylist > 0 then
			playlistIndex = math.random(1, #currentPlaylist)
			local startSoundTemplate = currentPlaylist[playlistIndex]
			
			songClonePlay = startSoundTemplate:Clone()
			songClonePlay.Volume = 0
			songClonePlay.Looped = false
			songClonePlay.Name = "RegionMusic_Playlist"
			songClonePlay.Parent = script
			songClonePlay:Play()
			
			print("[MusicRegions] Playing playlist start:", startSoundTemplate.Name, "Index:", playlistIndex)
			
			local targetVolume = startSoundTemplate.Volume > 0 and startSoundTemplate.Volume or 0.5
			currentTween = TweenService:Create(songClonePlay, TWEEN_INFO, {Volume = targetVolume})
			currentTween:Play()
			
			songClonePlay.Ended:Connect(function()
				if songClonePlay and songClonePlay.Parent == script then
					playNextInPlaylist()
				end
			end)
		end
	elseif soundSource and soundSource:IsA("Sound") then
		currentSongPlaying = region
		songClonePlay = soundSource:Clone()
		songClonePlay.Volume = 0
		songClonePlay.Looped = true
		songClonePlay.Name = "RegionMusic_Single"
		songClonePlay.Parent = script
		
		-- Ensure SoundId is preserved
		if songClonePlay.SoundId == "" then
			songClonePlay.SoundId = soundSource.SoundId
		end
		
		songClonePlay:Play()
		print("[MusicRegions] Playing sound:", soundSource.Name, "ID:", songClonePlay.SoundId)
		
		local targetVolume = soundSource.Volume > 0 and soundSource.Volume or 0.5
		currentTween = TweenService:Create(songClonePlay, TWEEN_INFO, {Volume = targetVolume})
		currentTween:Play()
	else
		warn("[MusicRegions] Missing sound asset in Workspace.SoundRegions for region: " .. region.Name)
	end
end

-- Main loop
RunService.Heartbeat:Connect(function()
	local activeRegion = getActiveRegion()
	
	if activeRegion then
		playRegionMusic(activeRegion)
	elseif currentSongPlaying then
		stopCurrentSong()
	end
end)

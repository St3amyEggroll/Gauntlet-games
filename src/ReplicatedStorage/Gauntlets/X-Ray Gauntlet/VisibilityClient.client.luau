local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local VisibilityRemote = Tool:WaitForChild("VisibilityRemote")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local equipped = false
local visionActive = false
local highlights = {}

----------------------------------------------------
-- HIGHLIGHTS
----------------------------------------------------

local function clearHighlights()
	for _, hl in ipairs(highlights) do
		if hl and hl.Parent then
			hl:Destroy()
		end
	end
	highlights = {}
end

local function addHighlight(character, fillColor, outlineColor, fillTransparency, outlineTransparency, name)
	if not character then return end

	local hl = Instance.new("Highlight")
	hl.Name = name or "VisionHighlight"
	hl.Adornee = character
	hl.FillColor = fillColor
	hl.OutlineColor = outlineColor
	hl.FillTransparency = fillTransparency
	hl.OutlineTransparency = outlineTransparency
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = character

	table.insert(highlights, hl)
	return hl
end

local function applyVision()
	clearHighlights()

	-- WHITE HIGHLIGHT ON YOURSELF
	if player.Character then
		addHighlight(
			player.Character,
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(255, 255, 255),
			1,   -- invisible fill
			0,   -- visible white outline
			"SelfVisionHighlight"
		)
	end

	-- RED HIGHLIGHTS ON EVERYONE ELSE
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			addHighlight(
				otherPlayer.Character,
				Color3.fromRGB(255, 0, 0),
				Color3.fromRGB(255, 0, 0),
				0.25, -- filled red
				0,
				"EnemyVisionHighlight"
			)
		end
	end
end

local function stopVision()
	visionActive = false
	clearHighlights()
end

-- Cleanup when tool is removed or player dies
script.Destroying:Connect(function()
	clearHighlights()
end)

Tool.Equipped:Connect(function()
	equipped = true
end)
Tool.Unequipped:Connect(function()
	equipped = false
	stopVision()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not equipped then return end

	-- Removed F key firing from here because GauntletHUDLocal already handles it for all gauntlets.
	-- This prevents double-firing which causes the ability to toggle On and then immediately Off.
end)

----------------------------------------------------
-- REMOTE EVENTS
----------------------------------------------------

VisibilityRemote.OnClientEvent:Connect(function(action, arg)
	if action == "StartVision" then
		visionActive = true
		applyVision()

	elseif action == "StopVision" then
		stopVision()

	elseif action == "CooldownRemaining" then
		-- optional:
		-- print("Cooldown:", math.ceil(arg))

	elseif action == "CooldownStarted" then
		-- optional:
		-- print("Cooldown started:", arg)
	end
end)

----------------------------------------------------
-- RESPAWN / NEW PLAYERS WHILE VISION ACTIVE
----------------------------------------------------

----------------------------------------------------
-- RESPAWN / DEATH
----------------------------------------------------

local function setupCharacter(char)
	local hum = char:WaitForChild("Humanoid")

	hum.Died:Connect(function()
		visionActive = false
		clearHighlights()
	end)
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(function(char)
	visionActive = false
	clearHighlights()
	setupCharacter(char)
end)
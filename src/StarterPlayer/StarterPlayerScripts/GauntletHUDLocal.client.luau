local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local UITheme = require(ReplicatedStorage:WaitForChild("UITheme"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local THEME = UITheme.THEME
THEME.PRIMARY = THEME.CYAN
THEME.SECONDARY = THEME.MAGENTA
THEME.CANCEL = THEME.RED
THEME.BLACK = THEME.BG

local ICONS = {
	["Emerald Gauntlet"]   = "rbxassetid://132640003436639",
	["Water Gauntlet"]     = "rbxassetid://97379845339532",
	["Fire Gauntlet"]      = "rbxassetid://108789212527369",
	["Ice Gauntlet"]       = "rbxassetid://77632532567521",
	["Rock Gauntlet"]      = "rbxassetid://129278461826205",
	["Nature Gauntlet"]    = "rbxassetid://133298397460165",
	["Energy Gauntlet"]    = "rbxassetid://133298397460165",
	["Space Gauntlet"]     = "rbxassetid://131107012060344",
	["Full Gold Gauntlet"] = "rbxassetid://101627968386615",
	["God Gauntlet"]       = "rbxassetid://124282535943612",
	["Wind Gauntlet"]      = "rbxassetid://120175668944028",
	["Void Gauntlet"]      = "rbxassetid://82173630536383",
	["X-Ray Gauntlet"]     = "rbxassetid://71772677262812",
	["Missle Gauntlet"]    = "rbxassetid://101627968386615",
	["Grappling Gauntlet"] = "rbxassetid://101627968386615",
}

local GAUNTLETS_WITH_ABILITIES = {
	["Emerald Gauntlet"] = false, 
	["Water Gauntlet"] = true, ["Fire Gauntlet"] = false, ["Ice Gauntlet"] = true,
	["Rock Gauntlet"] = true, ["Nature Gauntlet"] = true, ["Energy Gauntlet"] = true,
	["Space Gauntlet"] = true, ["Full Gold Gauntlet"] = false, ["God Gauntlet"] = false,
	["Wind Gauntlet"] = true, ["Void Gauntlet"] = true, ["X-Ray Gauntlet"] = true,
	["Missle Gauntlet"] = true, ["Grappling Gauntlet"] = true,
}

local ABILITY_COOLDOWNS = {
	["Water Gauntlet"] = 5, ["Energy Gauntlet"] = 8, ["Space Gauntlet"] = 5,
	["Wind Gauntlet"] = 6, ["X-Ray Gauntlet"] = 5, ["Missle Gauntlet"] = 6,
	["Grappling Gauntlet"] = 6, ["Nature Gauntlet"] = 8, ["Ice Gauntlet"] = 10, ["Void Gauntlet"] = 5, ["Rock Gauntlet"] = 8,
}

local CANCELABLE_GAUNTLETS = {
	["Wind Gauntlet"] = true,
	["X-Ray Gauntlet"] = true,
	["Void Gauntlet"] = true,
}

local TRIGGER_ON_HIT_GAUNTLETS = {
	["Water Gauntlet"] = true,
	["Ice Gauntlet"] = true,
	["Rock Gauntlet"] = true,
}

-- UI Initialization
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "GauntletHUD"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false

local container = Instance.new("Frame", screenGui)
container.Name = "GauntletContainer"
container.Size = UDim2.fromOffset(130, 130)
container.Position = UDim2.new(0.5, 0, 1, -30) 
container.AnchorPoint = Vector2.new(0.5, 1)
container.BackgroundTransparency = 1
container.Visible = false

local bg = Instance.new("Frame", container)
bg.Size = UDim2.fromScale(0.8, 0.8); bg.Position = UDim2.fromScale(0.5, 0.5); bg.AnchorPoint = Vector2.new(0.5, 0.5)
bg.BackgroundColor3 = THEME.BG
UITheme.corner(bg, 999)
UITheme.outline(bg, 4)
local bgStroke = UITheme.addNeonGlow(bg, THEME.CYAN, 3)

local icon = Instance.new("ImageLabel", bg)
icon.Size = UDim2.fromScale(0.7, 0.7); icon.Position = UDim2.fromScale(0.5, 0.5); icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.BackgroundTransparency = 1

local keyLabel = Instance.new("TextLabel", bg)
keyLabel.Size = UDim2.fromOffset(30, 30); keyLabel.Position = UDim2.new(1, 0, 1, 0); keyLabel.AnchorPoint = Vector2.new(1, 1)
keyLabel.BackgroundColor3 = THEME.BLUE; keyLabel.Text = "F"; keyLabel.TextColor3 = THEME.WHITE
keyLabel.Font = THEME.FONT; keyLabel.TextSize = 16
UITheme.corner(keyLabel, 8)
UITheme.outline(keyLabel, 3)

local progressRing = Instance.new("Frame", bg)
progressRing.Size = UDim2.fromScale(1.1, 1.1); progressRing.Position = UDim2.fromScale(0.5, 0.5); progressRing.AnchorPoint = Vector2.new(0.5, 0.5)
progressRing.BackgroundTransparency = 1
local ringStroke = Instance.new("UIStroke", progressRing); ringStroke.Thickness = 5; ringStroke.Color = THEME.SECONDARY
local ringGradient = Instance.new("UIGradient", ringStroke)
ringGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.501, 1), NumberSequenceKeypoint.new(1, 1)})

local currentGauntlet = nil
local cooldownActive = false
local abilityActive = false
local cooldownConnection = nil

local function triggerCooldown(duration)
	if cooldownActive then return end
	cooldownActive = true
	abilityActive = false
	keyLabel.BackgroundColor3 = THEME.SECONDARY
	
	local startTime = os.clock()
	TweenService:Create(bgStroke, TweenInfo.new(0.2), {Color = THEME.SECONDARY, Thickness = 5}):Play()

	if cooldownConnection then cooldownConnection:Disconnect() end
	cooldownConnection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		local progress = math.clamp(elapsed / duration, 0, 1)
		ringGradient.Rotation = ((1 - progress) * 360)
		if progress >= 1 then
			cooldownConnection:Disconnect()
			cooldownConnection = nil
			cooldownActive = false
			TweenService:Create(bgStroke, TweenInfo.new(0.5), {Color = THEME.PRIMARY, Thickness = 3}):Play()
			ringGradient.Rotation = 0
		end
	end)
end

local function handleAbilityTrigger()
	if cooldownActive then return end
	
	local isCancelable = CANCELABLE_GAUNTLETS[currentGauntlet]
	local triggerOnHit = TRIGGER_ON_HIT_GAUNTLETS[currentGauntlet]
	
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	if not (tool and tool:FindFirstChild("Remote")) then return end
	
	if isCancelable and abilityActive then
		local remoteAction

		if currentGauntlet == "X-Ray Gauntlet" then
			remoteAction = "ToggleInvis"
		elseif currentGauntlet == "Wind Gauntlet" then
			remoteAction = "StopFly"
		elseif currentGauntlet == "Void Gauntlet" then
			remoteAction = "Ability" -- second press tells the server to end the void ability
		end

		if remoteAction then
			tool.Remote:FireServer(remoteAction)
		end

		abilityActive = false
		triggerCooldown(ABILITY_COOLDOWNS[currentGauntlet] or 3)
		return
	end

	-- Activate ability
	abilityActive = true
	local effectDuration = 10 -- Default fallback duration
	
	if currentGauntlet == "Wind Gauntlet" then
		tool.Remote:FireServer("Fly")
		effectDuration = 3 -- Wind FlyTime is 3
	elseif currentGauntlet == "X-Ray Gauntlet" then
		tool.Remote:FireServer("ToggleInvis")
		effectDuration = 5 -- X-Ray INVIS_DURATION is 5
	else
		tool.Remote:FireServer("Ability")
	end
	
	if isCancelable then
		-- Change UI to show cancel option
		keyLabel.BackgroundColor3 = THEME.CANCEL
		-- Start an auto-cooldown timer if not canceled
		if currentGauntlet ~= "Void Gauntlet" then
			task.delay(effectDuration, function()
				if abilityActive then
					triggerCooldown(ABILITY_COOLDOWNS[currentGauntlet] or 3)
				end
			end)
		end
	elseif not triggerOnHit then
		-- Instant cooldown for non-hit, non-cancelable ones (Energy, Space, etc.)
		triggerCooldown(ABILITY_COOLDOWNS[currentGauntlet] or 3)
	end
end

local function updateHUDVisibility()
	local isMatchActive = workspace:GetAttribute("MatchActive") == true
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")

	if isMatchActive and tool then
		if currentGauntlet ~= tool.Name then
			currentGauntlet = tool.Name
			icon.Image = ICONS[currentGauntlet] or ""
			-- Reset states on switch
			abilityActive = false
			cooldownActive = false
			if cooldownConnection then 
				cooldownConnection:Disconnect()
				cooldownConnection = nil
			end
			bgStroke.Color = THEME.PRIMARY
			bgStroke.Thickness = 3
			ringGradient.Rotation = 0
			keyLabel.BackgroundColor3 = THEME.SECONDARY
			
			-- Setup remote listener for the new tool
			local remote = tool:FindFirstChild("Remote")
			if remote and remote:IsA("RemoteEvent") then
				remote.OnClientEvent:Connect(function(action)
					if action == "StartCooldown" then
						triggerCooldown(ABILITY_COOLDOWNS[currentGauntlet] or 3)
					end
				end)
			end
		end
		
		container.Visible = true
		local hasAbility = GAUNTLETS_WITH_ABILITIES[currentGauntlet] == true
		keyLabel.Visible = hasAbility
		progressRing.Visible = hasAbility
	else
		container.Visible = false
	end
end

-- Remote Listeners for specific gauntlets
local function setupRemoteListeners()
	-- This assumes the game has a way to notify the HUD about specific events like "Hit"
	-- For Water, Ice, Rock, we need to know when they hit someone to start the cooldown
	
	-- We can listen to the Tool's Remote event if it fires back to clients
	-- Or check for specific attributes/state changes
end

-- Listen for Gauntlet specific cooldown starts (for when server triggers it)
ReplicatedStorage.ChildAdded:Connect(function(child)
	-- Fallback for remote-triggered cooldowns
end)

-- Specific listener for hit-based gauntlets (if the server script fires back)
-- We'll add a generic way for server to tell HUD to start cooldown
-- For now, handled by manual trigger in InputBegan where applicable 
-- and expecting server-to-client notifications if possible.

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or not container.Visible or (cooldownActive and not abilityActive) then return end
	if input.KeyCode == Enum.KeyCode.F and GAUNTLETS_WITH_ABILITIES[currentGauntlet] then
		handleAbilityTrigger()
	end
end)

workspace:GetAttributeChangedSignal("MatchActive"):Connect(updateHUDVisibility)
player.CharacterAdded:Connect(function(c) 
	c.ChildAdded:Connect(updateHUDVisibility)
	c.ChildRemoved:Connect(function() task.defer(updateHUDVisibility) end)
end)

-- Global Remote listener for hit-based cooldowns
-- The server scripts for Water/Rock don't currently fire back to HUD, 
-- but I'll add logic to handle it if they do or if we add that.
-- For now, let's update the server scripts to notify the player.

updateHUDVisibility()

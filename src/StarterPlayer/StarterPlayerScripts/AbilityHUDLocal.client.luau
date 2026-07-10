--!strict
-- AbilityHUDLocal — the gauntlet ability button (F key / mobile POWER button)
-- with a circular cooldown readout. Replaces GauntletHUDLocal, same logic:
-- cancelable abilities, hit-triggered cooldowns via the tool's Remote.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")

-- Behavior tables (which gauntlets have activated abilities and how they act)
local HAS_ABILITY: { [string]: boolean } = {}
local COOLDOWNS: { [string]: number } = {}
for name, info in pairs(GameConfig.Gauntlets) do
	HAS_ABILITY[name] = info.Ability ~= nil
	if info.Cooldown then
		COOLDOWNS[name] = info.Cooldown
	end
end
-- passive-on-hit gauntlets still cooldown when they land a hit
local TRIGGER_ON_HIT = { ["Water Gauntlet"] = true, ["Ice Gauntlet"] = true, ["Rock Gauntlet"] = true }
local CANCELABLE = { ["Wind Gauntlet"] = true, ["X-Ray Gauntlet"] = true, ["Void Gauntlet"] = true }

local gui = Instance.new("ScreenGui")
gui.Name = "AbilityHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 15
gui.Parent = playerGui
UIKit.autoScale(gui)

-- Ability button sits bottom-center, above the health/dash bars in MainHUD
local container = Instance.new("Frame")
container.Name = "AbilityContainer"
container.AnchorPoint = Vector2.new(0.5, 1)
container.Position = UDim2.new(0.5, 0, 1, -68)
container.Size = UDim2.fromOffset(92, 92)
container.BackgroundTransparency = 1
container.Visible = false
container.Parent = gui

local ring = Instance.new("Frame")
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Position = UDim2.fromScale(0.5, 0.5)
ring.Size = UDim2.fromScale(0.92, 0.92)
ring.BackgroundColor3 = Color3.fromRGB(14, 16, 40)
ring.Parent = container
UIKit.corner(ring, 999)
local ringStroke = UIKit.stroke(ring, 4)
UIKit.vgradient(ring, T.SURFACE_TOP, T.SURFACE_BOTTOM)

local icon = Instance.new("ImageLabel")
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.fromScale(0.5, 0.5)
icon.Size = UDim2.fromScale(0.66, 0.66)
icon.BackgroundTransparency = 1
icon.ScaleType = Enum.ScaleType.Fit
icon.Parent = ring

local keyBadge = Instance.new("TextLabel")
keyBadge.AnchorPoint = Vector2.new(1, 1)
keyBadge.Position = UDim2.new(1, 2, 1, 2)
keyBadge.Size = UDim2.fromOffset(28, 28)
keyBadge.BackgroundColor3 = T.BLUE_B
keyBadge.Text = "F"
keyBadge.Font = T.FONT
keyBadge.TextSize = 15
keyBadge.TextColor3 = T.WHITE
keyBadge.ZIndex = 3
keyBadge.Parent = ring
UIKit.corner(keyBadge, 8)
UIKit.stroke(keyBadge, 2.5)
UIKit.vgradient(keyBadge, T.BLUE_A, T.BLUE_B)
keyBadge.Visible = UIKit.deviceType() == "PC"

local cooldownLbl = UIKit.label(container, "", 17)
cooldownLbl.AnchorPoint = Vector2.new(0.5, 0.5)
cooldownLbl.Position = UDim2.fromScale(0.5, 0.5)
cooldownLbl.Size = UDim2.fromScale(1, 1)
cooldownLbl.TextColor3 = T.WHITE
cooldownLbl.ZIndex = 5
cooldownLbl.Visible = false
UIKit.textStroke(cooldownLbl, 2.5)

--========================================================
-- STATE
--========================================================
local currentGauntlet: string? = nil
local cooldownActive = false
local abilityActive = false
local cooldownConn: RBXScriptConnection? = nil
local toolRemoteConn: RBXScriptConnection? = nil

local function setUsableAttr()
	player:SetAttribute("AbilityUsable", container.Visible and not cooldownActive)
end

local function triggerCooldown(duration: number)
	if cooldownActive then return end
	cooldownActive = true
	abilityActive = false
	setUsableAttr()

	cooldownLbl.Visible = true
	icon.ImageTransparency = 0.55
	TweenService:Create(ringStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(120, 120, 140) }):Play()

	local startTime = os.clock()
	if cooldownConn then cooldownConn:Disconnect() end
	cooldownConn = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		local left = duration - elapsed
		if left <= 0 then
			if cooldownConn then cooldownConn:Disconnect() cooldownConn = nil end
			cooldownActive = false
			cooldownLbl.Visible = false
			icon.ImageTransparency = 0
			TweenService:Create(ringStroke, TweenInfo.new(0.3), { Color = T.STROKE }):Play()
			-- ready pulse
			local s = ring:FindFirstChild("KitScale") :: UIScale? or Instance.new("UIScale")
			s.Name = "KitScale"
			s.Parent = ring
			TweenService:Create(s, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.12 }):Play()
			task.delay(0.2, function()
				TweenService:Create(s, TweenInfo.new(0.15), { Scale = 1 }):Play()
			end)
			UIKit.play("Tick", 1.3)
			setUsableAttr()
		else
			cooldownLbl.Text = string.format(left >= 10 and "%d" or "%.1f", left)
		end
	end)
end

local function handleAbilityTrigger()
	if cooldownActive and not abilityActive then return end
	local gauntlet = currentGauntlet
	if not gauntlet or not HAS_ABILITY[gauntlet] then return end

	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	local remote = tool and tool:FindFirstChild("Remote")
	if not (tool and remote and remote:IsA("RemoteEvent")) then return end

	if CANCELABLE[gauntlet] and abilityActive then
		local remoteAction = if gauntlet == "X-Ray Gauntlet" then "ToggleInvis"
			elseif gauntlet == "Wind Gauntlet" then "StopFly"
			else "Ability"
		remote:FireServer(remoteAction)
		abilityActive = false
		triggerCooldown(COOLDOWNS[gauntlet] or 3)
		return
	end

	abilityActive = true
	local effectDuration = 10
	if gauntlet == "Wind Gauntlet" then
		remote:FireServer("Fly")
		effectDuration = 3
	elseif gauntlet == "X-Ray Gauntlet" then
		remote:FireServer("ToggleInvis")
		effectDuration = 5
	else
		remote:FireServer("Ability")
	end

	if CANCELABLE[gauntlet] then
		TweenService:Create(ringStroke, TweenInfo.new(0.15), { Color = T.RED }):Play()
		if gauntlet ~= "Void Gauntlet" then
			task.delay(effectDuration, function()
				if abilityActive then
					triggerCooldown(COOLDOWNS[gauntlet] or 3)
				end
			end)
		end
	elseif not TRIGGER_ON_HIT[gauntlet] then
		triggerCooldown(COOLDOWNS[gauntlet] or 3)
	end
end

local function updateVisibility()
	local isMatchActive = workspace:GetAttribute("MatchActive") == true
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")

	if isMatchActive and tool then
		if currentGauntlet ~= tool.Name then
			currentGauntlet = tool.Name
			local info = GameConfig.Gauntlets[tool.Name]
			icon.Image = info and info.Icon or GameConfig.FallbackIcon
			abilityActive = false
			cooldownActive = false
			if cooldownConn then cooldownConn:Disconnect() cooldownConn = nil end
			cooldownLbl.Visible = false
			icon.ImageTransparency = 0
			ringStroke.Color = T.STROKE

			if toolRemoteConn then toolRemoteConn:Disconnect() toolRemoteConn = nil end
			local remote = tool:FindFirstChild("Remote")
			if remote and remote:IsA("RemoteEvent") then
				toolRemoteConn = remote.OnClientEvent:Connect(function(action)
					if action == "StartCooldown" then
						triggerCooldown(COOLDOWNS[currentGauntlet :: string] or 3)
					end
				end)
			end
		end
		container.Visible = HAS_ABILITY[currentGauntlet :: string] == true
	else
		container.Visible = false
		currentGauntlet = nil
	end
	setUsableAttr()
end

--========================================================
-- INPUT (keyboard F, click/tap the button, mobile POWER button)
--========================================================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or not container.Visible then return end
	if input.KeyCode == Enum.KeyCode.F then
		handleAbilityTrigger()
	end
end)

local hitBtn = Instance.new("TextButton")
hitBtn.BackgroundTransparency = 1
hitBtn.Text = ""
hitBtn.Size = UDim2.fromScale(1, 1)
hitBtn.Parent = ring
hitBtn.MouseButton1Click:Connect(handleAbilityTrigger)

;(UIBus:WaitForChild("MobileAbility") :: BindableEvent).Event:Connect(function()
	if container.Visible then
		handleAbilityTrigger()
	end
end)

workspace:GetAttributeChangedSignal("MatchActive"):Connect(updateVisibility)
player.CharacterAdded:Connect(function(c)
	c.ChildAdded:Connect(updateVisibility)
	c.ChildRemoved:Connect(function() task.defer(updateVisibility) end)
end)
if player.Character then
	player.Character.ChildAdded:Connect(updateVisibility)
	player.Character.ChildRemoved:Connect(function() task.defer(updateVisibility) end)
end

updateVisibility()

--!strict
-- Nature Gauntlet Client — premium target indicator that follows the
-- targeted player. Green ring = valid target + ability ready.
-- Grey ring = out of range or on cooldown. Same server protocol as before.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote") :: RemoteEvent

local ABILITY_COOLDOWN = 8
local MAX_RANGE = 120 -- studs; must roughly match the server's vine range
local READY_COLOR = Color3.fromRGB(110, 235, 90)
local BLOCKED_COLOR = Color3.fromRGB(150, 155, 170)

local Tracks: { [string]: AnimationTrack } = {}
local BeganConnection: RBXScriptConnection? = nil
local EndedConnection: RBXScriptConnection? = nil
local RenderConnection: RBXScriptConnection? = nil

local lastAbilityTime = 0

--========================================================
-- TARGET UI (screen-space, follows the target's head)
--========================================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "NatureTargetGui"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 50

local Marker = Instance.new("Frame")
Marker.Name = "Marker"
Marker.AnchorPoint = Vector2.new(0.5, 0.5)
Marker.Size = UDim2.fromOffset(64, 64)
Marker.BackgroundTransparency = 1
Marker.Visible = false
Marker.Parent = Gui

local Ring = Instance.new("Frame")
Ring.AnchorPoint = Vector2.new(0.5, 0.5)
Ring.Position = UDim2.fromScale(0.5, 0.5)
Ring.Size = UDim2.fromScale(1, 1)
Ring.BackgroundTransparency = 1
Ring.Parent = Marker
local RingStroke = Instance.new("UIStroke")
RingStroke.Thickness = 4
RingStroke.Color = READY_COLOR
RingStroke.Parent = Ring
local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(1, 0)
ringCorner.Parent = Ring

-- inner dot
local Dot = Instance.new("Frame")
Dot.AnchorPoint = Vector2.new(0.5, 0.5)
Dot.Position = UDim2.fromScale(0.5, 0.5)
Dot.Size = UDim2.fromOffset(6, 6)
Dot.BackgroundColor3 = READY_COLOR
Dot.BorderSizePixel = 0
Dot.Parent = Marker
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = Dot

-- corner ticks (crosshair feel)
for _, rot in ipairs({ 0, 90, 180, 270 }) do
	local tick = Instance.new("Frame")
	tick.AnchorPoint = Vector2.new(0.5, 0)
	tick.Position = UDim2.fromScale(0.5, 0.5)
	tick.Size = UDim2.fromOffset(3, 10)
	tick.BackgroundColor3 = READY_COLOR
	tick.BorderSizePixel = 0
	tick.Rotation = rot
	tick.Name = "Tick"
	tick.Parent = Marker

	local holder = Instance.new("Frame")
	holder.Name = "TickHolder" .. rot
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.Rotation = rot
	holder.Parent = Marker
	tick.Parent = holder
	tick.Position = UDim2.new(0.5, 0, 0, -6)
end

-- name + state label under the ring
local InfoLabel = Instance.new("TextLabel")
InfoLabel.AnchorPoint = Vector2.new(0.5, 0)
InfoLabel.Position = UDim2.new(0.5, 0, 1, 4)
InfoLabel.Size = UDim2.fromOffset(160, 32)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.FredokaOne
InfoLabel.TextSize = 14
InfoLabel.TextColor3 = READY_COLOR
InfoLabel.Text = ""
InfoLabel.Parent = Marker
local infoStroke = Instance.new("UIStroke")
infoStroke.Thickness = 2
infoStroke.Color = Color3.fromRGB(10, 10, 22)
infoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
infoStroke.Parent = InfoLabel

-- pulse animation while a valid target is locked
local pulseTween: Tween? = nil
local function setPulse(on: boolean)
	if on and not pulseTween then
		pulseTween = TweenService:Create(RingStroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 6 })
		pulseTween:Play()
	elseif not on and pulseTween then
		pulseTween:Cancel()
		pulseTween = nil
		RingStroke.Thickness = 4
	end
end

--========================================================
-- HELPERS
--========================================================
local function playAnimation(name: string)
	if Tracks[name] then
		Tracks[name]:Play()
		return
	end
	local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	local anim = Tool:FindFirstChild(name)
	if hum and anim and anim:IsA("Animation") then
		Tracks[name] = (hum :: any):LoadAnimation(anim)
		Tracks[name]:Play()
	end
end

local function stopAnimation(name: string)
	if Tracks[name] then
		Tracks[name]:Stop()
	end
end

local function getAimPoint(character: Model): Vector3?
	local head = character:FindFirstChild("Head")
	return head and (head :: BasePart).Position or nil
end

local function setMarkerState(ready: boolean, targetName: string, reason: string?)
	local color = ready and READY_COLOR or BLOCKED_COLOR
	RingStroke.Color = color
	Dot.BackgroundColor3 = color
	InfoLabel.TextColor3 = color
	for _, holder in ipairs(Marker:GetChildren()) do
		if holder.Name:match("^TickHolder") then
			local tick = holder:FindFirstChild("Tick")
			if tick and tick:IsA("Frame") then
				tick.BackgroundColor3 = color
			end
		end
	end
	if ready then
		InfoLabel.Text = targetName .. "\n⚡ READY"
	else
		InfoLabel.Text = targetName .. "\n" .. (reason or "")
	end
	setPulse(ready)
end

--========================================================
-- TARGETING
--========================================================
local function updateTarget()
	local character = Player.Character
	local camera = workspace.CurrentCamera
	if not character or not camera then return end

	local myRoot = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not myRoot then return end

	local bestPlayer: Player? = nil
	local bestScreenPos: Vector3? = nil
	local bestDistFromCenter = 150 -- px tolerance from screen center

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character then
			local aim = getAimPoint(plr.Character)
			if aim then
				local screenPos, onScreen = camera:WorldToViewportPoint(aim)
				if onScreen then
					local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
					local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.FilterDescendantsInstances = { character, plr.Character }
					local blocked = workspace:Raycast(camera.CFrame.Position, aim - camera.CFrame.Position, rayParams)

					if not blocked and distFromCenter < bestDistFromCenter then
						bestDistFromCenter = distFromCenter
						bestPlayer = plr
						bestScreenPos = screenPos
					end
				end
			end
		end
	end

	if bestPlayer and bestScreenPos then
		Marker.Position = UDim2.fromOffset(bestScreenPos.X, bestScreenPos.Y)
		Marker.Visible = true

		local aim = getAimPoint((bestPlayer :: Player).Character :: Model)
		local dist = aim and (aim - myRoot.Position).Magnitude or math.huge
		local cooldownLeft = ABILITY_COOLDOWN - (tick() - lastAbilityTime)
		local inRange = dist <= MAX_RANGE
		local ready = inRange and cooldownLeft <= 0

		local name = (bestPlayer :: Player).DisplayName
		if ready then
			setMarkerState(true, name)
		elseif not inRange then
			setMarkerState(false, name, "OUT OF RANGE")
		else
			setMarkerState(false, name, ("⏳ %.1fs"):format(math.max(cooldownLeft, 0)))
		end
	else
		Marker.Visible = false
	end
end

--========================================================
-- INPUT + LIFECYCLE (same server protocol as before)
--========================================================
local function inputBegan(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Remote:FireServer("LeftDown")
	elseif input.KeyCode == Enum.KeyCode.F and (tick() - lastAbilityTime >= ABILITY_COOLDOWN) then
		lastAbilityTime = tick()
		Remote:FireServer("Ability")
	end
end

local function inputEnded(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Remote:FireServer("LeftUp")
	end
end

Tool.Equipped:Connect(function()
	BeganConnection = UIS.InputBegan:Connect(inputBegan)
	EndedConnection = UIS.InputEnded:Connect(inputEnded)
	Gui.Parent = Player:WaitForChild("PlayerGui")
	RenderConnection = RunService.RenderStepped:Connect(updateTarget)
end)

Tool.Unequipped:Connect(function()
	if BeganConnection then BeganConnection:Disconnect() end
	if EndedConnection then EndedConnection:Disconnect() end
	if RenderConnection then RenderConnection:Disconnect() end
	Marker.Visible = false
	setPulse(false)
	Gui.Parent = nil
end)

Remote.OnClientEvent:Connect(function(func: string, ...)
	if func == "PlayAnimation" then
		playAnimation(...)
	elseif func == "StopAnimation" then
		stopAnimation(...)
	end
end)

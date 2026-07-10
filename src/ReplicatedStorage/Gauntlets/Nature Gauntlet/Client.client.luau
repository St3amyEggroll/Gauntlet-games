-- Nature Gauntlet Client
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")

local Tracks = {}
local BeganConnection, EndedConnection, RenderConnection

local ABILITY_COOLDOWN = 6
local lastAbilityTime = 0

-- UI Setup
local Gui = Instance.new("ScreenGui")
Gui.Name = "NatureTargetGui"
Gui.ResetOnSpawn = false

local Crosshair = Instance.new("ImageLabel")
Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
Crosshair.Size = UDim2.fromOffset(34, 34)
Crosshair.BackgroundTransparency = 1
Crosshair.Image = "rbxassetid://632007939"
Crosshair.ImageColor3 = Color3.fromRGB(0, 255, 0)
Crosshair.Visible = false
Crosshair.Parent = Gui

-- Helper Functions
local function playAnimation(name)
	if Tracks[name] then Tracks[name]:Play() return end
	local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	local anim = Tool:FindFirstChild(name)
	if hum and anim then
		Tracks[name] = hum:LoadAnimation(anim)
		Tracks[name]:Play()
	end
end

local function stopAnimation(name)
	if Tracks[name] then Tracks[name]:Stop() end
end

-- FIXED: Target the Head to ensure consistent tracking on R6
local function getAimPoint(character)
	local head = character:FindFirstChild("Head")
	return head and head.Position or nil
end

local function updateTarget()
	local character = Player.Character
	local camera = workspace.CurrentCamera
	if not character or not camera then return end

	local myRoot = character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	local bestPlayer = nil
	local bestPointOnScreen = nil
	local closestDistance = 200 -- Max detection range

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character then
			local targetHead = getAimPoint(plr.Character)
			if targetHead then
				-- Check if target is on screen
				local screenPos, onScreen = camera:WorldToViewportPoint(targetHead)

				if onScreen then
					-- Calculate distance from center of screen
					local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
					local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

					-- Raycast to check for walls
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.FilterDescendantsInstances = {character, plr.Character}
					local ray = workspace:Raycast(camera.CFrame.Position, (targetHead - camera.CFrame.Position), rayParams)

					if not ray and distFromCenter < 150 then
						if distFromCenter < closestDistance then
							closestDistance = distFromCenter
							bestPlayer = plr
							bestPointOnScreen = screenPos
						end
					end
				end
			end
		end
	end

	-- Update Crosshair
	if bestPlayer and bestPointOnScreen then
		Crosshair.Position = UDim2.fromOffset(bestPointOnScreen.X, bestPointOnScreen.Y)
		Crosshair.Visible = true

		-- Ability visual feedback
		local canUseAbility = (tick() - lastAbilityTime >= ABILITY_COOLDOWN)
		Crosshair.ImageColor3 = canUseAbility and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(150, 150, 150)
	else
		Crosshair.Visible = false
	end
end

-- Input Handling
local function inputBegan(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Remote:FireServer("LeftDown")
	elseif input.KeyCode == Enum.KeyCode.F and (tick() - lastAbilityTime >= ABILITY_COOLDOWN) then
		lastAbilityTime = tick()
		Remote:FireServer("Ability")
	end
end

local function inputEnded(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Remote:FireServer("LeftUp")
	end
end

-- Lifecycle
Tool.Equipped:Connect(function()
	BeganConnection = UIS.InputBegan:Connect(inputBegan)
	EndedConnection = UIS.InputEnded:Connect(inputEnded)
	Gui.Parent = Player.PlayerGui
	RenderConnection = RunService.RenderStepped:Connect(updateTarget)
end)

Tool.Unequipped:Connect(function()
	if BeganConnection then BeganConnection:Disconnect() end
	if EndedConnection then EndedConnection:Disconnect() end
	if RenderConnection then RenderConnection:Disconnect() end
	Crosshair.Visible = false
	Gui.Parent = nil
end)

Remote.OnClientEvent:Connect(function(func, ...)
	if func == "PlayAnimation" then playAnimation(...)
	elseif func == "StopAnimation" then stopAnimation(...) end
end)
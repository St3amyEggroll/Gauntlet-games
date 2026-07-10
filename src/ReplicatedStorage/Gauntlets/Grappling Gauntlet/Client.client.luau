local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Mouse = Player:GetMouse()

local Equipped = false
local DotPart
local Tracks = {}
local LastGrapple = 0
local GRAPPLE_COOLDOWN = 6

local function getCharacter()
	return Player.Character or Player.CharacterAdded:Wait()
end

local function getHumanoid()
	local char = getCharacter()
	return char:FindFirstChildOfClass("Humanoid")
end

local function playAnimation(animName)
	local hum = getHumanoid()
	if not hum then return end

	if Tracks[animName] then
		Tracks[animName]:Play()
		return
	end

	local anim = Tool:FindFirstChild(animName)
	if anim and anim:IsA("Animation") then
		local track = hum:LoadAnimation(anim)
		Tracks[animName] = track
		track:Play()
	end
end

local function removeDot()
	if DotPart then
		DotPart:Destroy()
		DotPart = nil
	end
end

local function createDot()
	removeDot()

	local p = Instance.new("Part")
	p.Name = "GrappleAimDot"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.4, 0.4, 0.4)
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(220, 20, 20)
	p.Transparency = 0.3
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = workspace

	DotPart = p
end

local function getGrappleTarget()
	local char = getCharacter()
	if not char then return nil end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {char, Tool}
	rayParams.IgnoreWater = true

	-- Check for player characters first (smart lock-on assist)
	local unitRay = Mouse.UnitRay
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 250, rayParams)
	
	return result
end

local function updateDot()
	if not Equipped then
		removeDot()
		return
	end

	if not DotPart then
		createDot()
	end

	local result = getGrappleTarget()
	local unitRay = Mouse.UnitRay

	if result then
		DotPart.Position = result.Position
		-- Visual feedback for cooldown
		if tick() - LastGrapple < GRAPPLE_COOLDOWN then
			DotPart.Color = Color3.fromRGB(100, 100, 100)
		else
			DotPart.Color = Color3.fromRGB(255, 0, 0)
		end
	else
		DotPart.Position = unitRay.Origin + unitRay.Direction * 250
		DotPart.Color = Color3.fromRGB(100, 100, 100)
	end
end

Tool.Equipped:Connect(function()
	Equipped = true
	createDot()
end)

Tool.Unequipped:Connect(function()
	Equipped = false
	removeDot()
end)

-- left click = normal melee
Tool.Activated:Connect(function()
	if Equipped then
		Remote:FireServer("LeftDown")
	end
end)

-- F = grapple
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not Equipped then return end

	if input.KeyCode == Enum.KeyCode.F then
		if tick() - LastGrapple >= GRAPPLE_COOLDOWN then
			local result = getGrappleTarget()
			if result then
				LastGrapple = tick()
				Remote:FireServer("Grapple", result.Position)
			end
		end
	end
end)

-- animation from server
Remote.OnClientEvent:Connect(function(func, ...)
	if func == "PlayAnimation" then
		playAnimation(...)
	end
end)

RunService.RenderStepped:Connect(function()
	if Equipped then
		updateDot()
	end
end)

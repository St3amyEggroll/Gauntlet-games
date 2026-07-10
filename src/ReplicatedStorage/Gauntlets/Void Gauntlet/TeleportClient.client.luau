local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local TeleportKey = Enum.KeyCode.F
local MaxDistance = 200 
local TeleportCooldown = 5

local isAiming = false
local previewPart = nil
local lastTeleportTime = 0

-- Flawless raycasting function
local function getMouse3DPosition()
	local mouseLocation = UserInputService:GetMouseLocation()
	local cameraRay = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {Player.Character, previewPart}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	local raycastResult = workspace:Raycast(cameraRay.Origin, cameraRay.Direction * 500, raycastParams)

	if raycastResult then
		return raycastResult.Position
	else
		return cameraRay.Origin + cameraRay.Direction * MaxDistance
	end
end

-- Creates a single, physical ghost box that cannot interact with anything
local function createVisualPreviewBox()
	-- Create a single part shaped roughly like a standing player character box
	local part = Instance.new("Part")
	part.Name = "TeleportPreviewBox"
	part.Size = Vector3.new(2.5, 5, 2.5) -- Matches character height/width bounds

	-- Engine properties to ensure 100% ghost behavior
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true

	-- Pure Visual Styling: Sleek Black Hologram Neon Glow
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(0, 0, 0) -- Pure Void Black
	part.Transparency = 0.3 -- Semi-transparent so you can see through it

	-- Optional: Adds a cool border outline to make it highly visible
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Color3 = Color3.fromRGB(0, 0, 0)
	selectionBox.LineThickness = 0.05
	selectionBox.Adornee = part
	selectionBox.Parent = part

	-- CRITICAL: Putting it inside Camera completely isolates it from player physics pushes
	part.Parent = Camera
	return part
end

local function cleanupPreview()
	isAiming = false
	if previewPart then
		previewPart:Destroy()
		previewPart = nil
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if Tool.Parent:IsA("Backpack") then return end 

	if input.KeyCode == TeleportKey then
		local character = Player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then return end

		local currentTime = os.clock()
		if currentTime - lastTeleportTime < TeleportCooldown then 
			return 
		end

		if not isAiming then
			isAiming = true
			previewPart = createVisualPreviewBox()
		else
			local targetPos = getMouse3DPosition()
			local originPos = character.HumanoidRootPart.Position

			if (targetPos - originPos).Magnitude > MaxDistance then
				targetPos = originPos + (targetPos - originPos).Unit * MaxDistance
			end

			lastTeleportTime = os.clock()

			Remote:FireServer("RequestTeleport", targetPos)
			cleanupPreview()
		end
	end
end)

Tool.Unequipped:Connect(cleanupPreview)

workspace:GetAttributeChangedSignal("MatchActive"):Connect(function()
	if not workspace:GetAttribute("MatchActive") then
		cleanupPreview()
	end
end)

RunService.RenderStepped:Connect(function()
	if isAiming and previewPart and Player.Character then
		local character = Player.Character
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local targetPos = getMouse3DPosition()
		local originPos = root.Position 
		local direction = targetPos - originPos

		if direction.Magnitude > MaxDistance then
			targetPos = originPos + direction.Unit * MaxDistance
		end

		-- Offset upward exactly half of the box's height (5 / 2 = 2.5) to rest flat on surfaces
		local finalPosition = targetPos + Vector3.new(0, 2.5, 0)
		local lookTarget = Vector3.new(targetPos.X, finalPosition.Y, targetPos.Z)

		if (lookTarget - finalPosition).Magnitude < 0.5 then
			lookTarget = finalPosition + root.CFrame.LookVector
		end

		previewPart.CFrame = CFrame.lookAt(finalPosition, lookTarget)
	end
end)
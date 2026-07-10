local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
-- Wait for workspace to load the folder safely
local folder = game.Workspace:WaitForChild("SkyParts", 5)

if not folder then
	warn("❌ CRITICAL: Could not find the 'SkyParts' folder in Workspace!")
	return
end

local CanTouch = true
local FADE_DURATION = 2 

local function changeSky(skyName)
	if not CanTouch then return end
	CanTouch = false 
	print("🔄 Starting sky transition to: " .. skyName)

	-- Clear old skyboxes
	for _, child in pairs(Lighting:GetChildren()) do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end

	-- Clone and parent the new Sky object
	local SkyClone = script:FindFirstChild(skyName)
	if SkyClone then
		SkyClone = SkyClone:Clone()
		SkyClone.Parent = Lighting

		local targetOutdoorAmbient = Color3.fromRGB(178, 178, 178) 
		local targetColorShiftTop = Color3.fromRGB(25, 50, 75) 

		Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
		Lighting.ColorShift_Top = Color3.new(0, 0, 0)

		local tweenInfo = TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local fadeTween = TweenService:Create(Lighting, tweenInfo, {
			OutdoorAmbient = targetOutdoorAmbient,
			ColorShift_Top = targetColorShiftTop
		})

		fadeTween:Play()
		fadeTween.Completed:Wait()
		print("✅ Sky transition complete!")
	else
		warn("❌ ERROR: Skybox named '" .. skyName .. "' was not found inside this LocalScript!")
	end

	CanTouch = true
end

-- Function to bind touch events to a part
local function bindPart(part)
	if part:IsA("BasePart") then
		print("🔗 Successfully connected touch event to part: " .. part.Name)

		-- CRITICAL: LocalScripts need CanTouch and CanCollide/CanQuery to be true to register local touches reliably
		part.CanTouch = true 

		part.Touched:Connect(function(hit)
			local character = hit.Parent
			local hitPlayer = Players:GetPlayerFromCharacter(character)

			if hitPlayer == player then
				if script:FindFirstChild(part.Name) then
					changeSky(part.Name)
				else
					print("⚠️ Touched " .. part.Name .. " but no matching Skybox found in script. Defaulting to 'Sky'.")
					changeSky("Sky") 
				end
			end
		end)
	end
end

-- Bind existing parts
for _, part in pairs(folder:GetChildren()) do
	bindPart(part)
end

-- Just in case parts load a split second late
folder.ChildAdded:Connect(bindPart)
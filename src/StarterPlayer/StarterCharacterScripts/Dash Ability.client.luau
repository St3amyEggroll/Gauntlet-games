-- Put "Slide Ability" in StarterPlayer and StarterCharacterScripts
--                 Enjoy This Ability

local UIS = game:GetService("UserInputService")
local char = script.Parent
local humanoid = char:WaitForChild("Humanoid")
local rootPart = char:WaitForChild("HumanoidRootPart")

local slideAnim = Instance.new("Animation")
slideAnim.AnimationId = "rbxassetid://109267687059124" -- Enter your AnimationID

local keybind = Enum.KeyCode.Q -- The key for the ability
local cooldown = 3 -- Change this to your cooldown in seconds
local canslide = true

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	if not canslide then return end
	if humanoid.Health <= 0 then return end

	if input.KeyCode == keybind then
		canslide = false

		local playAnim = humanoid:LoadAnimation(slideAnim)
		playAnim:Play()

		local slide = Instance.new("BodyVelocity")
		slide.MaxForce = Vector3.new(1, 0, 1) * 30000

		-- DIRECTIONAL LOGIC:
		-- If the player is moving, dash in their movement direction.
		-- If they are standing still, dash in the direction they are facing.
		if humanoid.MoveDirection.Magnitude > 0 then
			slide.Velocity = humanoid.MoveDirection * 100
		else
			slide.Velocity = rootPart.CFrame.lookVector * 100
		end

		slide.Parent = rootPart

		for count = 1, 8 do
			task.wait(0.1)
			slide.Velocity *= 0.7
		end

		playAnim:Stop()
		slide:Destroy()

		task.wait(cooldown)
		canslide = true
	end
end)
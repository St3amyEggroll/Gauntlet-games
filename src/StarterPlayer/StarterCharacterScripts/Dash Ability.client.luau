--!strict
-- Dash Ability — Q key (PC) or the HUD's mobile DASH button.
-- Publishes DashReadyAt/DashCooldown attributes so the HUD dash bar is exact.

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char = script.Parent :: Model
local humanoid = char:WaitForChild("Humanoid") :: Humanoid
local rootPart = char:WaitForChild("HumanoidRootPart") :: BasePart

local COOLDOWN = 3
local KEY = Enum.KeyCode.Q

local slideAnim = Instance.new("Animation")
slideAnim.AnimationId = "rbxassetid://109267687059124"

local canDash = true

player:SetAttribute("DashCooldown", COOLDOWN)
player:SetAttribute("DashReadyAt", 0)

local function doDash()
	if not canDash then return end
	if humanoid.Health <= 0 then return end
	canDash = false
	player:SetAttribute("DashReadyAt", os.clock() + COOLDOWN)

	local playAnim = (humanoid :: any):LoadAnimation(slideAnim)
	playAnim:Play()

	local slide = Instance.new("BodyVelocity")
	slide.MaxForce = Vector3.new(1, 0, 1) * 30000

	if humanoid.MoveDirection.Magnitude > 0 then
		slide.Velocity = humanoid.MoveDirection * 100
	else
		slide.Velocity = rootPart.CFrame.LookVector * 100
	end

	slide.Parent = rootPart

	for _ = 1, 8 do
		task.wait(0.1)
		slide.Velocity *= 0.7
	end

	playAnim:Stop()
	slide:Destroy()

	task.wait(COOLDOWN - 0.8)
	canDash = true
end

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	if input.KeyCode == KEY then
		doDash()
	end
end)

-- Mobile dash button (fired by MainHUD)
local UIBus = ReplicatedStorage:WaitForChild("UIBus")
local conn = (UIBus:WaitForChild("MobileDash") :: BindableEvent).Event:Connect(function()
	doDash()
end)
char.AncestryChanged:Connect(function()
	if not char:IsDescendantOf(game) then
		conn:Disconnect()
	end
end)

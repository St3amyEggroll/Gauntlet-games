--!strict
-- SpectateLocal — compact spectate system for lobby players during a match.
-- Fires SpectateSync(targetPlayer|nil) exactly like the old UIPolisher version.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local SpectateSync = ReplicatedStorage:WaitForChild("SpectateSync") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "SpectateUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = playerGui
UIKit.autoScale(gui)

local toggleBtn = UIKit.button("👁 SPECTATE", "purple", gui)
toggleBtn.AnchorPoint = Vector2.new(1, 0)
toggleBtn.Position = UDim2.new(1, -14, 0, 14)
toggleBtn.Size = UDim2.fromOffset(150, 40)
toggleBtn.TextSize = 15
toggleBtn.Visible = false

local bar = UIKit.card("SpectateBar", gui)
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -86)
bar.Size = UDim2.fromOffset(320, 56)
bar.Visible = false

local prevBtn = UIKit.button("◀", "blue", bar)
prevBtn.Size = UDim2.fromOffset(44, 40)
prevBtn.Position = UDim2.new(0, 8, 0.5, -20)

local nextBtn = UIKit.button("▶", "blue", bar)
nextBtn.AnchorPoint = Vector2.new(1, 0)
nextBtn.Position = UDim2.new(1, -8, 0.5, -20)
nextBtn.Size = UDim2.fromOffset(44, 40)

local nameLbl = UIKit.label(bar, "", 17)
nameLbl.Size = UDim2.new(1, -120, 1, 0)
nameLbl.Position = UDim2.new(0, 60, 0, 0)
UIKit.textStroke(nameLbl, 2)

local spectating = false
local targetIndex = 1

local function candidates(): { Player }
	local result = {}
	local ingame = Workspace:FindFirstChild("Ingame")
	if not ingame then return result end
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if p ~= player and char and char.Parent == ingame then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				table.insert(result, p)
			end
		end
	end
	return result
end

local function applyTarget()
	local list = candidates()
	local cam = Workspace.CurrentCamera
	if #list == 0 or not cam then
		return
	end
	if targetIndex > #list then targetIndex = 1 end
	if targetIndex < 1 then targetIndex = #list end
	local target = list[targetIndex]
	local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		cam.CameraSubject = hum
		nameLbl.Text = "👁 " .. target.DisplayName
		SpectateSync:FireServer(target)
	end
end

local function stopSpectating()
	spectating = false
	bar.Visible = false
	toggleBtn.Text = "👁 SPECTATE"
	local cam = Workspace.CurrentCamera
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if cam and hum then
		cam.CameraSubject = hum
	end
	SpectateSync:FireServer(nil)
end

local function startSpectating()
	local list = candidates()
	if #list == 0 then
		UIKit.notify("Nobody to spectate right now!", T.GREY_B, "👁", 2)
		return
	end
	spectating = true
	bar.Visible = true
	toggleBtn.Text = "✕ STOP"
	targetIndex = 1
	applyTarget()
end

toggleBtn.MouseButton1Click:Connect(function()
	if spectating then stopSpectating() else startSpectating() end
end)
prevBtn.MouseButton1Click:Connect(function()
	targetIndex -= 1
	applyTarget()
end)
nextBtn.MouseButton1Click:Connect(function()
	targetIndex += 1
	applyTarget()
end)

-- Show the toggle only while a match is running and we're NOT in it
task.spawn(function()
	while true do
		local active = Workspace:GetAttribute("MatchActive") == true
		local ingame = Workspace:FindFirstChild("Ingame")
		local inRound = ingame and player.Character and player.Character.Parent == ingame
		local shouldShow = active and not inRound

		toggleBtn.Visible = shouldShow
		if not shouldShow and spectating then
			stopSpectating()
		end
		-- keep the camera valid if our target died / left
		if spectating then
			local list = candidates()
			if #list == 0 then
				stopSpectating()
			end
		end
		task.wait(1)
	end
end)

--!strict
-- FirstJoinTutorial — restyled step-by-step intro for brand new players.
-- Fires TutorialCompleteEvent at the end so RoundManager lets them play.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TutorialComplete = ReplicatedStorage:WaitForChild("TutorialCompleteEvent") :: RemoteEvent

--========================================================
-- Only for brand-new players (no wins, no coins) who haven't done it
--========================================================
local leaderstats = player:WaitForChild("leaderstats", 15)
if not leaderstats then return end
local coinsValue = leaderstats:WaitForChild("Coins", 10) :: IntValue?
local winsValue = leaderstats:WaitForChild("Wins", 10) :: IntValue?
task.wait(2) -- let data load

local isNew = coinsValue and winsValue and coinsValue.Value == 0 and winsValue.Value == 0
if not isNew or player:GetAttribute("TutorialComplete") then
	TutorialComplete:FireServer()
	return
end

--========================================================
-- STEPS
--========================================================
local STEPS = {
	{ Icon = "👊", Title = "WELCOME TO GAUNTLET GAMES!", Body = "Fight other players in wild rounds using magical gauntlets. Last one standing wins!" },
	{ Icon = "🧤", Title = "GAUNTLETS ARE EVERYTHING", Body = "Each gauntlet has its own power — fire, ice, flight, teleports and more. Press F (or tap POWER on mobile) to use your ability." },
	{ Icon = "🛒", Title = "THE SHOP", Body = "Open the Shop from the buttons on the left. Buy new gauntlets with coins, or grab coin packs if you're in a hurry." },
	{ Icon = "🪙", Title = "EARNING COINS", Body = "Get coins from knockouts, wins, daily rewards, quests, the spin wheel — and just for playing (10 coins every 5 minutes)!" },
	{ Icon = "💨", Title = "MOVE FAST", Body = "Press Q (or tap DASH) to dash. Watch your health and dash bars at the bottom of the screen." },
	{ Icon = "🏆", Title = "YOU'RE READY!", Body = "A round starts soon. Vote for a map, pick your gauntlet, and go win!" },
}

local gui = Instance.new("ScreenGui")
gui.Name = "TutorialUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 500
gui.Parent = playerGui
UIKit.autoScale(gui)

local dim = Instance.new("Frame")
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.Size = UDim2.fromScale(1, 1)
dim.Parent = gui

local panel = UIKit.panel("TutorialPanel", UDim2.fromOffset(440, 300))
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Parent = gui

local _, closeBtn = UIKit.header(panel, "HOW TO PLAY")

local stepIcon = UIKit.label(panel, "", 44)
stepIcon.Size = UDim2.new(1, 0, 0, 54)
stepIcon.Position = UDim2.new(0, 0, 0, 62)

local stepTitle = UIKit.label(panel, "", 20)
stepTitle.Size = UDim2.new(1, -40, 0, 26)
stepTitle.Position = UDim2.new(0, 20, 0, 118)
stepTitle.TextWrapped = true
UIKit.textStroke(stepTitle, 2)

local stepBody = UIKit.label(panel, "", 15, T.FONT_BOLD)
stepBody.Size = UDim2.new(1, -60, 0, 70)
stepBody.Position = UDim2.new(0, 30, 0, 148)
stepBody.TextWrapped = true
stepBody.TextYAlignment = Enum.TextYAlignment.Top
stepBody.TextColor3 = T.TEXT_DIM

-- progress dots
local dots = Instance.new("Frame")
dots.BackgroundTransparency = 1
dots.AnchorPoint = Vector2.new(0.5, 1)
dots.Position = UDim2.new(0.5, 0, 1, -66)
dots.Size = UDim2.fromOffset(#STEPS * 18, 10)
dots.Parent = panel
local dotFrames: { Frame } = {}
for i = 1, #STEPS do
	local d = Instance.new("Frame")
	d.Size = UDim2.fromOffset(10, 10)
	d.Position = UDim2.fromOffset((i - 1) * 18, 0)
	d.BackgroundColor3 = T.GREY_B
	d.Parent = dots
	UIKit.corner(d, 5)
	table.insert(dotFrames, d)
end

local nextBtn = UIKit.button("NEXT ▶", "lime", panel)
nextBtn.Size = UDim2.fromOffset(180, 44)
nextBtn.AnchorPoint = Vector2.new(0.5, 1)
nextBtn.Position = UDim2.new(0.5, 0, 1, -12)

local current = 0

local function finish()
	TutorialComplete:FireServer()
	UIKit.notify("Tutorial complete — good luck out there!", T.GREEN, "🏆")
	TweenService:Create(dim, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	UIKit.popClose(panel, function()
		gui:Destroy()
	end)
end

local function showStep(i: number)
	current = i
	local step = STEPS[i]
	stepIcon.Text = step.Icon
	stepTitle.Text = step.Title
	stepBody.Text = step.Body
	nextBtn.Text = (i == #STEPS) and "LET'S GO! 🚀" or "NEXT ▶"
	for j, d in ipairs(dotFrames) do
		d.BackgroundColor3 = j <= i and T.HEADER_A or T.GREY_B
	end

	-- little slide-in
	local s = Instance.new("UIScale")
	s.Scale = 0.92
	s.Parent = stepIcon
	TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(0.3, function() s:Destroy() end)
end

nextBtn.MouseButton1Click:Connect(function()
	if current >= #STEPS then
		finish()
	else
		showStep(current + 1)
	end
end)

closeBtn.MouseButton1Click:Connect(finish)

UIKit.popOpen(panel)
showStep(1)

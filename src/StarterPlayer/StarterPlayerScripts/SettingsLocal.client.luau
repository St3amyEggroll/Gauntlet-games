--!strict
-- SettingsLocal — modern settings menu with Master / Music / SFX sliders.
-- Values live in player attributes (Set_Master / Set_Music / Set_SFX),
-- apply to every Sound in the game, and save through GameExtrasServer.
-- Heuristic: looped sounds count as Music, one-shots as SFX.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIBus = ReplicatedStorage:WaitForChild("UIBus")
local SaveSettings = ReplicatedStorage:WaitForChild("SaveSettings") :: RemoteEvent

--========================================================
-- VOLUME ENGINE
--========================================================
local function getSetting(name: string): number
	local v = player:GetAttribute("Set_" .. name)
	return typeof(v) == "number" and math.clamp(v, 0, 1) or 1
end

local function applyToSound(sound: Sound)
	if sound:GetAttribute("UIKitSFX") then
		return -- UIKit reads settings itself on play
	end
	if sound:GetAttribute("OriginalVolume") == nil then
		sound:SetAttribute("OriginalVolume", sound.Volume)
	end
	local base = sound:GetAttribute("OriginalVolume") :: number
	local group = sound.Looped and getSetting("Music") or getSetting("SFX")
	sound.Volume = base * getSetting("Master") * group
end

local function applyAllVolumes()
	for _, inst in ipairs(game:GetDescendants()) do
		if inst:IsA("Sound") then
			pcall(applyToSound, inst)
		end
	end
end

game.DescendantAdded:Connect(function(inst)
	if inst:IsA("Sound") then
		task.defer(function()
			pcall(applyToSound, inst)
		end)
	end
end)

--========================================================
-- MENU
--========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SettingsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 105
gui.Parent = playerGui
UIKit.autoScale(gui)

local panel = UIKit.panel("SettingsPanel", UDim2.fromOffset(420, 380))
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Visible = false
panel.Parent = gui

local _, closeBtn = UIKit.header(panel, "SETTINGS")

local body = Instance.new("Frame")
body.BackgroundTransparency = 1
body.Size = UDim2.new(1, -40, 1, -90)
body.Position = UDim2.new(0, 20, 0, 70)
body.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 14)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = body

local saveDebounce: thread? = nil
local function scheduleSave()
	if saveDebounce then task.cancel(saveDebounce) end
	saveDebounce = task.delay(1, function()
		SaveSettings:FireServer({
			Master = getSetting("Master"),
			Music = getSetting("Music"),
			SFX = getSetting("SFX"),
		})
	end)
end

local function makeVolumeSlider(labelText: string, attr: string, order: number)
	local row = UIKit.slider(body, labelText, getSetting(attr), function(ratio)
		player:SetAttribute("Set_" .. attr, ratio)
		applyAllVolumes()
		scheduleSave()
	end)
	row.LayoutOrder = order
end

makeVolumeSlider("🔊  Master Volume", "Master", 1)
makeVolumeSlider("🎵  Music Volume", "Music", 2)
makeVolumeSlider("💥  SFX Volume", "SFX", 3)

local hint = UIKit.label(body, "Settings save automatically and follow you between servers.", 13, T.FONT_MED)
hint.Size = UDim2.new(1, 0, 0, 30)
hint.TextWrapped = true
hint.TextColor3 = T.TEXT_DIM
hint.LayoutOrder = 4

--========================================================
-- OPEN / CLOSE
--========================================================
local isOpen = false
local function close()
	if not isOpen then return end
	isOpen = false
	UIKit.popClose(panel)
end
local function open()
	UIKit.closeOthers("Settings")
	isOpen = true
	UIKit.popOpen(panel)
end
UIKit.registerExclusive("Settings", close)
closeBtn.MouseButton1Click:Connect(close)

;(UIBus:WaitForChild("OpenSettings") :: BindableEvent).Event:Connect(function()
	if isOpen then close() else open() end
end)

-- Re-apply volumes once the server has loaded saved settings
for _, attr in ipairs({ "Set_Master", "Set_Music", "Set_SFX" }) do
	player:GetAttributeChangedSignal(attr):Connect(applyAllVolumes)
end
task.delay(3, applyAllVolumes)

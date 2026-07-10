--!strict
-- 1) Syntax-compiles every new/changed source file.
-- 2) Round-trips the patched place and confirms expected instances exist.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local files = {
	"src/ReplicatedStorage/UIKit.luau",
	"src/ReplicatedStorage/GameConfig.luau",
	"src/ServerScriptService/MarketplaceHandler.server.luau",
	"src/ServerScriptService/GameExtrasServer.server.luau",
	"src/StarterPlayer/StarterPlayerScripts/MainHUDLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/ShopLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/TrollMenuLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/SpinWheelLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/QuestsLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/DailyRewardLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/SettingsLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/InventorySystemLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/KillNotificationLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/MapVoteLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/AbilityHUDLocal.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/FirstJoinTutorial.client.luau",
	"src/StarterPlayer/StarterPlayerScripts/SpectateLocal.client.luau",
	"src/StarterPlayer/StarterCharacterScripts/Dash Ability.client.luau",
	"src/ReplicatedStorage/Gauntlets/Nature Gauntlet/Client.client.luau",
}

local failures = 0
for _, path in files do
	local src = fs.readFile(path)
	local ok, err = pcall(function()
		luau.compile(src)
	end)
	if ok then
		print("OK   " .. path)
	else
		failures += 1
		print("FAIL " .. path .. "\n     " .. tostring(err))
	end
end

print("\nRound-trip check on patched place...")
local game = roblox.deserializePlace(fs.readFile("GauntletGames.rbxl"))
local RS = game:GetService("ReplicatedStorage")
local SPS = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

local checks = {
	{ RS:FindFirstChild("UIKit"), "UIKit module" },
	{ RS:FindFirstChild("GameConfig"), "GameConfig module" },
	{ RS:FindFirstChild("UIBus"), "UIBus folder" },
	{ RS:FindFirstChild("TrollEffect"), "TrollEffect remote" },
	{ RS:FindFirstChild("SpinRequest"), "SpinRequest remote" },
	{ SPS and SPS:FindFirstChild("MainHUDLocal"), "MainHUDLocal" },
	{ SPS and SPS:FindFirstChild("ShopLocal"), "ShopLocal" },
	{ SPS and SPS:FindFirstChild("TrollMenuLocal"), "TrollMenuLocal" },
	{ SPS and SPS:FindFirstChild("ShopSystemLocal") == nil and true or nil, "old ShopSystemLocal removed" },
	{ SPS and SPS:FindFirstChild("UIPolisherLocal") == nil and true or nil, "old UIPolisherLocal removed" },
}
for _, c in checks do
	if c[1] then
		print("OK   " .. c[2])
	else
		failures += 1
		print("FAIL " .. c[2])
	end
end

local mainHud = SPS and SPS:FindFirstChild("MainHUDLocal")
if mainHud and #((mainHud :: any).Source) > 1000 then
	print("OK   MainHUDLocal source embedded (" .. #((mainHud :: any).Source) .. " bytes)")
else
	failures += 1
	print("FAIL MainHUDLocal source missing/empty")
end

print(failures == 0 and "\nALL CHECKS PASSED" or ("\n" .. failures .. " FAILURES"))

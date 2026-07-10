--!strict
-- Patches GauntletGames.rbxl with the redesigned UI:
--  * removes superseded scripts
--  * writes new/updated scripts from src/
--  * adds the UIBus folder (BindableEvents) and new remotes
-- Output: GauntletGames.rbxl (original kept in git history)

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local IN_PLACE = "GauntletGames.rbxl"
local OUT_PLACE = "GauntletGames.rbxl"

print("Reading " .. IN_PLACE .. "...")
local game = roblox.deserializePlace(fs.readFile(IN_PLACE))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local StarterCharacterScripts = StarterPlayer:FindFirstChild("StarterCharacterScripts")
assert(StarterPlayerScripts, "StarterPlayerScripts missing")
assert(StarterCharacterScripts, "StarterCharacterScripts missing")

local function readSrc(path: string): string
	return fs.readFile("src/" .. path)
end

local function destroyChild(parent: any, name: string)
	while true do
		local child = parent:FindFirstChild(name)
		if not child then break end
		child:Destroy()
		print("  removed " .. name)
	end
end

local function upsertScript(parent: any, name: string, class: string, source: string)
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local s = roblox.Instance.new(class)
	s.Name = name
	;(s :: any).Source = source
	s.Parent = parent
	print("  wrote " .. class .. " " .. name)
end

local function ensureInstance(parent: any, name: string, class: string): any
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == class then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local inst = roblox.Instance.new(class)
	inst.Name = name
	inst.Parent = parent
	print("  created " .. class .. " " .. name)
	return inst
end

--========================================================
print("ReplicatedStorage modules + remotes...")
upsertScript(ReplicatedStorage, "UIKit", "ModuleScript", readSrc("ReplicatedStorage/UIKit.luau"))
upsertScript(ReplicatedStorage, "GameConfig", "ModuleScript", readSrc("ReplicatedStorage/GameConfig.luau"))

-- UIBus folder with BindableEvents for HUD <-> menu communication
local uiBus = ensureInstance(ReplicatedStorage, "UIBus", "Folder")
for _, name in
	{ "OpenShop", "OpenQuests", "OpenSpin", "OpenSettings", "OpenDaily", "OpenTroll", "OpenInventory", "OpenMapVote", "MobileDash", "MobileAbility" }
do
	ensureInstance(uiBus, name, "BindableEvent")
end

-- New remotes used by GameExtrasServer / TrollMenu (server also self-heals)
ensureInstance(ReplicatedStorage, "SpinRequest", "RemoteFunction")
ensureInstance(ReplicatedStorage, "QuestSync", "RemoteFunction")
ensureInstance(ReplicatedStorage, "QuestClaim", "RemoteEvent")
ensureInstance(ReplicatedStorage, "SaveSettings", "RemoteEvent")
ensureInstance(ReplicatedStorage, "TrollEffect", "RemoteEvent")

--========================================================
print("ServerScriptService...")
upsertScript(ServerScriptService, "MarketplaceHandler", "Script", readSrc("ServerScriptService/MarketplaceHandler.server.luau"))
upsertScript(ServerScriptService, "GameExtrasServer", "Script", readSrc("ServerScriptService/GameExtrasServer.server.luau"))

--========================================================
print("StarterPlayerScripts: removing superseded scripts...")
for _, name in
	{ "ShopSystemLocal", "UIPolisherLocal", "GauntletHUDLocal", "DailyRewardLocal", "InventorySystemLocal", "KillNotificationLocal", "FirstJoinTutorial", "Water", "ShopDiagnoser", "GrassTargetingUI" }
do
	destroyChild(StarterPlayerScripts, name)
end

print("StarterPlayerScripts: writing new scripts...")
local newLocals = {
	{ "MainHUDLocal", "MainHUDLocal.client.luau" },
	{ "ShopLocal", "ShopLocal.client.luau" },
	{ "TrollMenuLocal", "TrollMenuLocal.client.luau" },
	{ "SpinWheelLocal", "SpinWheelLocal.client.luau" },
	{ "QuestsLocal", "QuestsLocal.client.luau" },
	{ "DailyRewardLocal", "DailyRewardLocal.client.luau" },
	{ "SettingsLocal", "SettingsLocal.client.luau" },
	{ "InventorySystemLocal", "InventorySystemLocal.client.luau" },
	{ "KillNotificationLocal", "KillNotificationLocal.client.luau" },
	{ "MapVoteLocal", "MapVoteLocal.client.luau" },
	{ "AbilityHUDLocal", "AbilityHUDLocal.client.luau" },
	{ "FirstJoinTutorial", "FirstJoinTutorial.client.luau" },
	{ "SpectateLocal", "SpectateLocal.client.luau" },
}
for _, entry in newLocals do
	upsertScript(StarterPlayerScripts, entry[1], "LocalScript", readSrc("StarterPlayer/StarterPlayerScripts/" .. entry[2]))
end

--========================================================
print("StarterCharacterScripts...")
upsertScript(StarterCharacterScripts, "Dash Ability", "LocalScript", readSrc("StarterPlayer/StarterCharacterScripts/Dash Ability.client.luau"))

--========================================================
print("Nature Gauntlet client...")
local gauntlets = ReplicatedStorage:FindFirstChild("Gauntlets")
assert(gauntlets, "Gauntlets folder missing")
local nature = gauntlets:FindFirstChild("Nature Gauntlet")
assert(nature, "Nature Gauntlet missing")
upsertScript(nature, "Client", "LocalScript", readSrc("ReplicatedStorage/Gauntlets/Nature Gauntlet/Client.client.luau"))

--========================================================
print("Serializing to " .. OUT_PLACE .. "...")
fs.writeFile(OUT_PLACE, roblox.serializePlace(game))
print("Done!")

--!strict
-- GameConfig — every price, product ID, gauntlet stat, troll item, quest and
-- spin segment in one place. Edit values here; no digging through UI code.

local GameConfig = {}

--========================================================
-- GAUNTLETS (name, price, rarity, icon, description, ability info)
--========================================================
export type GauntletInfo = {
	Price: number,
	Rarity: string,
	Icon: string,
	Desc: string,
	Ability: string?, -- nil = passive gauntlet, no activated ability
	Cooldown: number?,
	GamepassId: number?, -- set = bought with Robux instead of coins
}

GameConfig.Gauntlets = {
	["Energy Gauntlet"] = { Price = 100, Rarity = "Common", Icon = "rbxassetid://94440351994069", Desc = "Increases your speed for 3 seconds.", Ability = "Speed Boost", Cooldown = 8 },
	["Space Gauntlet"] = { Price = 100, Rarity = "Common", Icon = "rbxassetid://131107012060344", Desc = "Launches you high up into the air.", Ability = "Sky Launch", Cooldown = 5 },
	["Emerald Gauntlet"] = { Price = 100, Rarity = "Common", Icon = "rbxassetid://132640003436639", Desc = "Heals you with every hit on an opponent.", Ability = nil, Cooldown = nil },
	["Water Gauntlet"] = { Price = 300, Rarity = "Rare", Icon = "rbxassetid://97379845339532", Desc = "Slows a player down and blurs their screen for 3 seconds on hit.", Ability = "Drench (on hit)", Cooldown = 5 },
	["Ice Gauntlet"] = { Price = 300, Rarity = "Rare", Icon = "rbxassetid://77632532567521", Desc = "Freezes a player in place for 3 seconds on hit.", Ability = "Freeze (on hit)", Cooldown = 10 },
	["Fire Gauntlet"] = { Price = 300, Rarity = "Rare", Icon = "rbxassetid://108789212527369", Desc = "Burns enemies with damage over time.", Ability = nil, Cooldown = nil },
	["Nature Gauntlet"] = { Price = 500, Rarity = "Epic", Icon = "rbxassetid://133298397460165", Desc = "Shoots out a vine that pulls the targeted player towards you.", Ability = "Vine Pull", Cooldown = 8 },
	["X-Ray Gauntlet"] = { Price = 600, Rarity = "Epic", Icon = "rbxassetid://71772677262812", Desc = "Highlights all players on the map and turns you invisible for 5 seconds.", Ability = "X-Ray / Invisibility", Cooldown = 5 },
	["Rock Gauntlet"] = { Price = 800, Rarity = "Legendary", Icon = "rbxassetid://129278461826205", Desc = "Smash opponents into the ground and drop a boulder on their head.", Ability = "Boulder Smash (on hit)", Cooldown = 8 },
	["Missle Gauntlet"] = { Price = 800, Rarity = "Legendary", Icon = "rbxassetid://101627968386615", Desc = "Fires 3 homing missiles at the nearest player.", Ability = "Missile Barrage", Cooldown = 6 },
	["Grappling Gauntlet"] = { Price = 800, Rarity = "Legendary", Icon = "rbxassetid://101627968386615", Desc = "Fires a grappling hook and pulls you to wherever it lands.", Ability = "Grapple", Cooldown = 6 },
	["Wind Gauntlet"] = { Price = 1000, Rarity = "Legendary", Icon = "rbxassetid://120175668944028", Desc = "Lets you fly for 3 seconds.", Ability = "Flight", Cooldown = 6 },
	["Full Gold Gauntlet"] = { Price = 999, Rarity = "Mythic", Icon = "rbxassetid://101627968386615", Desc = "Deals 50% damage on every hit.", Ability = nil, Cooldown = nil, GamepassId = 1899547200 },
	["Void Gauntlet"] = { Price = 1499, Rarity = "Mythic", Icon = "rbxassetid://82173630536383", Desc = "Teleport anywhere on the map.", Ability = "Void Teleport", Cooldown = 5, GamepassId = 1899025219 },
	["God Gauntlet"] = { Price = 2499, Rarity = "Mythic", Icon = "rbxassetid://124282535943612", Desc = "Ultimate reality-breaking power. 100% damage per hit.", Ability = nil, Cooldown = nil, GamepassId = 1899601270 },
} :: { [string]: GauntletInfo }

GameConfig.FallbackIcon = "rbxassetid://10614013444"

--========================================================
-- COIN PACKS (developer products)
--========================================================
GameConfig.CoinBundles = {
	{ Name = "Handful of Coins", Amount = 100, Robux = 25, ProductId = 3273984433, Image = "rbxassetid://18209599195" },
	{ Name = "Pouch of Coins", Amount = 300, Robux = 80, ProductId = 3605946307, Image = "rbxassetid://18209599044" },
	{ Name = "Bag of Coins", Amount = 500, Robux = 100, ProductId = 3605946335, Image = "rbxassetid://18209598819" },
	{ Name = "Chest of Coins", Amount = 1000, Robux = 200, ProductId = 3605946465, Image = "rbxassetid://18209598650" },
	{ Name = "Vault of Coins", Amount = 5000, Robux = 800, ProductId = 3605946501, Image = "rbxassetid://18209598496" },
}

--========================================================
-- TROLL MENU
-- Kind = "Product" (buy every use) or "Gamepass" (own forever, use with cooldown).
-- PASTE YOUR REAL IDs BELOW — items with Id = 0 show as "coming soon" in game.
--========================================================
export type TrollItem = {
	Key: string,
	Name: string,
	Desc: string,
	Icon: string, -- emoji shown on the card
	Kind: "Product" | "Gamepass",
	Id: number,
	Broadcast: string, -- %s replaced with the buyer's name
}

GameConfig.TrollItems = {
	{ Key = "Highlight", Name = "Highlight All Players", Desc = "Outlines every other player through walls for 10 seconds.", Icon = "🔦", Kind = "Product", Id = 0, Broadcast = "%s highlighted everyone!" },
	{ Key = "JoinRound", Name = "Play Next Round", Desc = "Stuck in the lobby? Jump straight into the action.", Icon = "🎟️", Kind = "Product", Id = 0, Broadcast = "%s jumped into the round!" },
	{ Key = "Jumpscare", Name = "Jumpscare All", Desc = "Every other player gets a screen-filling jumpscare.", Icon = "👻", Kind = "Product", Id = 0, Broadcast = "%s jumpscared everyone!" },
	{ Key = "Burn", Name = "Burn All", Desc = "Sets every other player on fire for 3 seconds.", Icon = "🔥", Kind = "Product", Id = 0, Broadcast = "%s used Burn All!" },
	{ Key = "Explode", Name = "Explode All", Desc = "Detonates an explosion on every other player.", Icon = "💥", Kind = "Product", Id = 0, Broadcast = "%s used Explode All!" },
	{ Key = "Blur", Name = "Blur Everyone's Screen", Desc = "Blurs every other player's screen for 3 seconds.", Icon = "🌫️", Kind = "Product", Id = 0, Broadcast = "%s blurred everyone's screen!" },
} :: { TrollItem }

--========================================================
-- SPIN WHEEL (coins only). Weight = relative chance.
--========================================================
GameConfig.SpinSegments = {
	{ Coins = 5, Weight = 25, Color = Color3.fromRGB(139, 147, 168) },
	{ Coins = 10, Weight = 22, Color = Color3.fromRGB(111, 216, 255) },
	{ Coins = 15, Weight = 18, Color = Color3.fromRGB(79, 196, 36) },
	{ Coins = 25, Weight = 14, Color = Color3.fromRGB(200, 130, 255) },
	{ Coins = 40, Weight = 10, Color = Color3.fromRGB(255, 157, 77) },
	{ Coins = 75, Weight = 7, Color = Color3.fromRGB(255, 215, 110) },
	{ Coins = 150, Weight = 3, Color = Color3.fromRGB(255, 60, 90) },
	{ Coins = 500, Weight = 1, Color = Color3.fromRGB(85, 208, 255) },
}
GameConfig.SpinCooldown = 10 * 60 -- one free spin every 10 minutes

--========================================================
-- QUESTS (daily). Type: Kills | Wins | Coins | Playtime(min)
--========================================================
GameConfig.Quests = {
	{ Key = "kills5", Name = "Eliminator", Desc = "Knock out 5 players", Type = "Kills", Goal = 5, Reward = 50, Icon = "⚔️" },
	{ Key = "win1", Name = "Champion", Desc = "Win 1 round", Type = "Wins", Goal = 1, Reward = 60, Icon = "🏆" },
	{ Key = "coins100", Name = "Collector", Desc = "Earn 100 coins", Type = "Coins", Goal = 100, Reward = 40, Icon = "🪙" },
	{ Key = "play15", Name = "Regular", Desc = "Play for 15 minutes", Type = "Playtime", Goal = 15, Reward = 30, Icon = "⏱️" },
	{ Key = "kills15", Name = "Warlord", Desc = "Knock out 15 players", Type = "Kills", Goal = 15, Reward = 120, Icon = "💀" },
}

--========================================================
-- PASSIVE INCOME
--========================================================
GameConfig.PassiveReward = 10 -- coins
GameConfig.PassiveInterval = 5 * 60 -- seconds

--========================================================
-- DAILY REWARDS (5-day streak, matches DailyRewardServer)
--========================================================
GameConfig.DailyRewards = { 5, 10, 15, 20, 25 }

return GameConfig

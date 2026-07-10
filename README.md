# Gauntlet Games

`GauntletGames.rbxl` is the game — the full place file with the redesigned UI
already injected. Open it in Roblox Studio and press Play.

## ⚠️ Do NOT run `rojo build` or `rojo serve` here

The `src/` folder contains **scripts only** (extracted for editing and code
review) — none of the maps, parts, or models. Building or syncing with Rojo
would produce a game with no world in it. The place file is the source of
truth.

## How scripts get into the game

`tools/patch.luau` (run with [Lune](https://github.com/lune-org/lune)) writes
the scripts from `src/` into `GauntletGames.rbxl` without touching anything
else. `tools/verify.luau` checks the result.

## Where to configure things

All prices, product IDs, quests, spin segments and troll items live in
`src/ReplicatedStorage/GameConfig.luau` — or edit `ReplicatedStorage → GameConfig`
directly in Studio. Troll Menu items need real developer product IDs pasted
into the `TrollItems` table before they work.

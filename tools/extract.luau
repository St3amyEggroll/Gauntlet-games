--!strict
-- Extracts every Script/LocalScript/ModuleScript from GauntletGames.rbxl into src/
-- and writes a full instance-tree summary for the UI overhaul work.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local PLACE = "GauntletGames.rbxl"
local OUT = "src"
local TREE_OUT = "tools/tree.txt"
local MANIFEST_OUT = "tools/manifest.json"

print("Reading " .. PLACE .. "...")
local game = roblox.deserializePlace(fs.readFile(PLACE))

local function sanitize(name: string): string
	local s = name:gsub("[%c/\\:%*%?\"<>|]", "_")
	if s == "" then s = "_" end
	return s
end

local function suffixFor(class: string): string?
	if class == "Script" then
		return ".server.luau"
	elseif class == "LocalScript" then
		return ".client.luau"
	elseif class == "ModuleScript" then
		return ".luau"
	end
	return nil
end

local manifest = {}
local usedPaths: { [string]: number } = {}

local function ensureDir(path: string)
	local parts = {}
	for part in path:gmatch("[^/]+") do
		table.insert(parts, part)
	end
	table.remove(parts) -- drop filename
	local cur = ""
	for _, part in parts do
		cur = cur == "" and part or (cur .. "/" .. part)
		if not fs.isDir(cur) then
			fs.writeDir(cur)
		end
	end
end

local function relPath(inst: any): string
	local parts = {}
	local cur = inst
	while cur ~= nil and cur.ClassName ~= "DataModel" do
		table.insert(parts, 1, sanitize(cur.Name))
		cur = cur.Parent
	end
	return table.concat(parts, "/")
end

local scriptCount = 0
local function walkScripts(inst: any)
	for _, child in inst:GetChildren() do
		local suffix = suffixFor(child.ClassName)
		if suffix then
			local base = OUT .. "/" .. relPath(child)
			local path = base .. suffix
			if usedPaths[path] then
				usedPaths[path] += 1
				path = base .. "_" .. tostring(usedPaths[path]) .. suffix
			else
				usedPaths[path] = 1
			end
			ensureDir(path)
			local src = (child :: any).Source or ""
			fs.writeFile(path, src)
			scriptCount += 1
			local enabled = true
			if child.ClassName ~= "ModuleScript" then
				local okE, e = pcall(function()
					return (child :: any).Enabled
				end)
				enabled = if okE then e else true
				if enabled == nil then
					local okD, d = pcall(function()
						return (child :: any).Disabled
					end)
					enabled = if okD then not d else true
				end
			end
			table.insert(manifest, {
				path = path,
				class = child.ClassName,
				fullName = child:GetFullName(),
				enabled = enabled,
				bytes = #src,
			})
		end
		walkScripts(child)
	end
end

-- Instance tree summary (names + classes, capped depth for Workspace geometry)
local lines = {}
local function walkTree(inst: any, depth: number, maxDepth: number)
	if depth > maxDepth then
		return
	end
	local children = inst:GetChildren()
	-- Collapse repeated siblings of same Name+Class (map geometry spam)
	local seen: { [string]: number } = {}
	local order = {}
	for _, child in children do
		local key = child.Name .. " [" .. child.ClassName .. "]"
		if not seen[key] then
			seen[key] = 0
			table.insert(order, { key = key, child = child })
		end
		seen[key] += 1
	end
	for _, entry in order do
		local count = seen[entry.key]
		local label = entry.key .. (count > 1 and (" x" .. count) or "")
		table.insert(lines, string.rep("  ", depth) .. label)
		walkTree(entry.child, depth + 1, maxDepth)
	end
end

for _, service in game:GetChildren() do
	local maxDepth
	if service.ClassName == "Workspace" then
		maxDepth = 3
	elseif service.Name == "StarterGui" or service.Name == "ReplicatedStorage"
		or service.Name == "ServerScriptService" or service.Name == "ServerStorage"
		or service.Name == "StarterPlayer" or service.Name == "StarterPack"
		or service.Name == "SoundService" or service.Name == "Lighting" then
		maxDepth = 12
	else
		maxDepth = 2
	end
	table.insert(lines, service.Name .. " [" .. service.ClassName .. "]")
	walkTree(service, 1, maxDepth)
end

walkScripts(game)

ensureDir(TREE_OUT)
fs.writeFile(TREE_OUT, table.concat(lines, "\n"))
fs.writeFile(MANIFEST_OUT, serde.encode("json", manifest, true))
print(("Extracted %d scripts. Tree lines: %d"):format(scriptCount, #lines))

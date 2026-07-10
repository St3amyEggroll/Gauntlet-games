local sandModel = workspace:WaitForChild("sand")

-- Make sure the model has a PrimaryPart
assert(sandModel.PrimaryPart, "The 'sand' model needs a PrimaryPart!")

local SPEED = 75 -- studs per second
local SEGMENTS = 3 -- number of scenery pieces
local DIRECTION = Vector3.new(0, 0, -1) -- direction the scenery moves

-- Get the length of the model along the Z axis
local size = sandModel:GetExtentsSize()
local spacing = math.abs(size.Z)

local segments = {}

-- Store the original
table.insert(segments, sandModel)

-- Clone the rest
for i = 2, SEGMENTS do
	local clone = sandModel:Clone()
	clone.Parent = workspace
	table.insert(segments, clone)
end

-- Position them in a line
local startCF = sandModel:GetPrimaryPartCFrame()

for i, model in ipairs(segments) do
	model:PivotTo(startCF * CFrame.new(0, 0, (i - 1) * spacing))
end

local RunService = game:GetService("RunService")

RunService.Heartbeat:Connect(function(dt)
	for _, model in ipairs(segments) do
		model:PivotTo(model:GetPivot() + DIRECTION * SPEED * dt)
	end

	-- Find the front-most scenery piece
	local frontZ = -math.huge
	for _, model in ipairs(segments) do
		local z = model:GetPivot().Position.Z
		if z > frontZ then
			frontZ = z
		end
	end

	-- Move scenery that has gone too far behind back to the front
	for _, model in ipairs(segments) do
		local pos = model:GetPivot().Position
		if pos.Z < frontZ - spacing * (SEGMENTS - 1) then
			model:PivotTo(model:GetPivot() * CFrame.new(0, 0, spacing * SEGMENTS))
		end
	end
end)
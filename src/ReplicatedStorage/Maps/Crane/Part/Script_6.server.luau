-- Reference to the part the script is inside of
local killPart = script.Parent

-- Function that runs when something touches the part
local function onTouch(otherPart)
	-- Look for a "Humanoid" inside the model that touched the part
	local character = otherPart.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	-- If a Humanoid exists, set its health to 0
	if humanoid then
		humanoid.Health = 0
	end
end

-- Connect the function to the Touched event
killPart.Touched:Connect(onTouch)
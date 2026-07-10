local remote = game.ReplicatedStorage:WaitForChild("HazardEvent")
local players = game:GetService("Players")
local camera = workspace:WaitForChild("Camera") -- Changed to ensure camera exists

-- Pre-create effects
local blur = Instance.new("BlurEffect", camera)
blur.Name = "HazardBlur"
blur.Size = 0

local colorCorrection = Instance.new("ColorCorrectionEffect", camera)
colorCorrection.Name = "HazardColor"
colorCorrection.Enabled = false
colorCorrection.TintColor = Color3.fromRGB(255, 200, 100)

-- Create Highlight
local highlight = Instance.new("Highlight")
highlight.Name = "HazardHighlight"
highlight.FillTransparency = 0.5
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = workspace 

remote.OnClientEvent:Connect(function(enable, part)
	if enable and part then -- Safety check: only run if part exists
		blur.Size = 24
		colorCorrection.Enabled = true
		highlight.Adornee = part
		highlight.Enabled = true
	else
		blur.Size = 0
		colorCorrection.Enabled = false
		highlight.Enabled = false
		highlight.Adornee = nil
	end
end)
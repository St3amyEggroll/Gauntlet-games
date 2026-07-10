--> MADE BY DEVGR8M8 // JOIN OUR GROUP 'THE SWAG BAG!' <--

--> VARIABLES
local Module = script.Parent
local PlayersbeingTeleported = {}
local Deboucne, LastSpeed

--> FUNCTIONS
local function Spin(Character, InitialSpeed, RateOfChange)
	for count = 1, 50 do
		Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(InitialSpeed), 0)
		InitialSpeed += RateOfChange
		task.wait()
	end
	LastSpeed = InitialSpeed
end

local function OnTouch(Hit, TouchedTP)
	if not table.find(PlayersbeingTeleported, Hit.Parent) and Hit.Parent:FindFirstChild("Humanoid") and not Deboucne then
		Deboucne = true
		local Character = Hit.Parent
		table.insert(PlayersbeingTeleported, Character)
		Deboucne = nil
		Character.HumanoidRootPart.Anchored = true
		Character:SetPrimaryPartCFrame(CFrame.new(TouchedTP.Base.Position + Vector3.new(0, 3, 0)))
		Spin(Character, 2, 1)
		local Destination
		if TouchedTP.Name == "Teleporter1" then
			Destination = Module.Teleporter2
		else
			Destination = Module.Teleporter1
		end
		Character:SetPrimaryPartCFrame(CFrame.new(Destination.Base.Position + Vector3.new(0, 3, 0)))
		Spin(Character, LastSpeed, -1)
		Character.HumanoidRootPart.Anchored = false
		task.wait(3)
		for i = 1, #PlayersbeingTeleported do
			if PlayersbeingTeleported[i] == Character then
				table.remove(PlayersbeingTeleported, i)
			end
		end
	end
end

for i, v in pairs(Module:GetChildren()) do
	if v:IsA("Model") then
		v.Base.Touched:Connect(function(Hit)
			OnTouch(Hit, v)
		end)
	end
end
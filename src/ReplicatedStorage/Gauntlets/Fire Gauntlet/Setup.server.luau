if not game:GetService('ServerScriptService'):FindFirstChild("FlareGunManager") then
	local newScript = script.FlareGunManager:Clone()
	newScript.Parent = game:GetService('ServerScriptService')
	newScript.Enabled = true
end

if not game:GetService('ReplicatedStorage'):FindFirstChild("FlareGunShoot") then
	local newRemote = script.FlareGunShoot:Clone()
	newRemote.Parent = game:GetService('ReplicatedStorage')
end

if not game:GetService('ReplicatedStorage'):FindFirstChild("Flare") then
	script.Flare.Parent = game:GetService('ReplicatedStorage')
else
	script.Flare:Remove()
end
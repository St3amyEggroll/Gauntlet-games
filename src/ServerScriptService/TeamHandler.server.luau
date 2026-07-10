local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TestService = game:GetService("TestService")

local DeveloperConfig = require(ReplicatedFirst:WaitForChild("DeveloperConfig"))

Players.PlayerAdded:Connect(function(player)
	local isDev = false
	for _, devName in pairs(DeveloperConfig.developers) do
		if player.Name == devName then
			isDev = true
			break
		end
	end

	if isDev then
		TestService:Message("Developer joined the game.")

		local developerTeam = Teams:FindFirstChild("Developers")
		if not developerTeam then
			warn("Developer team does not exist. Creating it...")
			developerTeam = Instance.new("Team")
			developerTeam.Name = "Developers"
			developerTeam.TeamColor = BrickColor.new("Black")
			developerTeam.AutoAssignable = false
			developerTeam.Parent = Teams
		end

		player.Team = developerTeam
	else
		local playerTeam = Teams:FindFirstChild("Players")
		if not playerTeam then
			warn("Players team does not exist. Creating it...")
			playerTeam = Instance.new("Team")
			playerTeam.Name = "Players"
			playerTeam.TeamColor = BrickColor.new("Really Red")
			playerTeam.AutoAssignable = true
			playerTeam.Parent = Teams
		end

		player.Team = playerTeam
	end
end)

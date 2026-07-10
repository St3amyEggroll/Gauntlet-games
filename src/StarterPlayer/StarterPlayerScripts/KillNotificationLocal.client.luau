--!strict
-- KillNotificationLocal — kill feed toasts in the shared style.
-- Server fires KillEvent(killerName, victimName) to all clients.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local T = UIKit.Theme

local player = Players.LocalPlayer
local KillEvent = ReplicatedStorage:WaitForChild("KillEvent") :: RemoteEvent

KillEvent.OnClientEvent:Connect(function(killerName: string, victimName: string)
	if killerName == player.Name or killerName == player.DisplayName then
		UIKit.play("Reward")
		UIKit.notify(("You knocked out %s!  +5 coins"):format(victimName), T.GOLD, "⚔️", 3)
	elseif victimName == player.Name or victimName == player.DisplayName then
		UIKit.notify(("%s knocked you out!"):format(killerName), T.RED, "💀", 3)
	else
		UIKit.notify(("%s knocked out %s"):format(killerName, victimName), T.HEADER_B, "⚔️", 2.5)
	end
end)

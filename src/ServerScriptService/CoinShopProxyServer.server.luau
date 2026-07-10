
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OpenCoinShopEvent = ReplicatedStorage:FindFirstChild("OpenCoinShopEvent")
if not OpenCoinShopEvent then
	OpenCoinShopEvent = Instance.new("RemoteEvent")
	OpenCoinShopEvent.Name = "OpenCoinShopEvent"
	OpenCoinShopEvent.Parent = ReplicatedStorage
end

OpenCoinShopEvent.OnServerEvent:Connect(function(player)
	print("[CoinShopProxy] Received server event from: " .. player.Name)
	OpenCoinShopEvent:FireClient(player)
end)

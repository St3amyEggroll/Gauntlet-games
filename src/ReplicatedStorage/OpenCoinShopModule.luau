
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OpenCoinShopEvent = ReplicatedStorage:WaitForChild("OpenCoinShopEvent")

return function()
	OpenCoinShopEvent:FireServer()
end

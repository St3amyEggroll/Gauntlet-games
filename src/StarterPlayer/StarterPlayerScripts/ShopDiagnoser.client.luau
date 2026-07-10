
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerScripts = player:WaitForChild("PlayerScripts")

local shopScript = PlayerScripts:WaitForChild("ShopSystemLocal")
print("ShopSystemLocal found. Enabled: " .. tostring(shopScript.Enabled))

shopScript:GetPropertyChangedSignal("Enabled"):Connect(function()
    print("ShopSystemLocal Enabled changed: " .. tostring(shopScript.Enabled))
end)

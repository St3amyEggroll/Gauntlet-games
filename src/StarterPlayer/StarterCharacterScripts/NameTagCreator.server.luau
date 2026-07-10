if game.Players:FindFirstChild(script.Parent.Name).DisplayName == game.Players:FindFirstChild(script.Parent.Name).Name then 
	name = game.Players:FindFirstChild(script.Parent.Name).DisplayName
else
	name = game.Players:FindFirstChild(script.Parent.Name).DisplayName
end

local tag = game.ReplicatedStorage.Nametag:Clone()
tag.NameTag.Text = name
tag.Parent = script.Parent:WaitForChild("Head")

script.Parent:WaitForChild("Hummanoid").DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
local module = {}

function module.load(target)
	_G.target = target
	local target = game.Players:WaitForChild(_G.target)
	script.monster:Clone().Parent = game.Workspace
end

return module

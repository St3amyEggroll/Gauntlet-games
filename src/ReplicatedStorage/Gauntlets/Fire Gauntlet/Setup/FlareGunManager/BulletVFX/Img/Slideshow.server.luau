local imgs = {103740493,103804266,103804383}

for _,v in pairs(imgs) do
	game:GetService("ContentProvider"):Preload("http://www.roblox.com/asset/?ID="..v)
end

script.Parent.Visible = true

for i = 1,#imgs do
	script.Parent.Image = "http://www.roblox.com/asset/?ID="..imgs[i]
	wait()
end

script.Parent.Visible = false

script.Parent.Parent:Remove()

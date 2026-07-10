--\\ Move the regions to where you want.
--\\ The name of the region will determine what music is playing in the folder. SoundRegions.
--\\ For example: The sound region A will play the sound A in SoundRegions.
--\\ This script will unpack everything to where it is suppossed to be. 
--\\ Don't move anything out of this script, and don't ungroup the model InteractiveZones!

--\\ Unpacker

for _, region in pairs(script.Parent.InteractiveMusicRegions:GetChildren()) do
	region.CanCollide = false
	region.Transparency = 0.95 -- set the transparency of the zones here. 1 being completely invisible, 0 being visible.
	region.Locked = true
end

script.Parent.InteractiveMusicRegions.Parent = workspace
script.Parent.SoundRegions.Parent = game.StarterGui
script.Parent.SoundRegionScript.Parent = game.StarterGui
script.Parent:Destroy()
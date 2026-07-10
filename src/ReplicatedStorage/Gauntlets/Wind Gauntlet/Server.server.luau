local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Handle = Tool:WaitForChild("Handle")

local FriendlyFire = false

local ArmMesh

local HitAble = false
local HitWindup = 0.15
local HitWindow = 0.75
local HitDamage = 15
local HitVictims = {}

local SwingAble = true
local SwingRestTime = 2

------------------------
-- FLY
------------------------

local FlyTime = 3
local FlyCooldown = 8
local FlySpeed = 45

local CanFly = true
local FlyData = {}

------------------------

function getPlayer()
	local char = Tool.Parent
	return game:GetService("Players"):GetPlayerFromCharacter(char)
end

function contains(t,v)
	for _,val in pairs(t) do
		if val==v then
			return true
		end
	end
	return false
end

function tagHuman(human)
	local tag = Instance.new("ObjectValue")
	tag.Value = getPlayer()
	tag.Name = "creator"

	tag.Parent = human

	game:GetService(
		"Debris"
	):AddItem(tag)
end

function sameTeam(otherHuman)

	local player = getPlayer()

	local otherPlayer =
		game:GetService("Players")
		:GetPlayerFromCharacter(
			otherHuman.Parent
		)

	if player and otherPlayer then

		if player==otherPlayer then
			return true
		end

		if otherPlayer.Neutral then
			return false
		end

		return player.TeamColor==
			otherPlayer.TeamColor
	end

	return false

end

function checkTeams(otherHuman)

	return not (
		sameTeam(
			otherHuman
		)
			and
			not FriendlyFire
	)

end

------------------------
-- HIT
------------------------

function onTouched(part)

	if part:IsDescendantOf(
		Tool.Parent
		)
	then
		return
	end

	if not HitAble then
		return
	end

	if part.Parent
		and
		part.Parent:
		FindFirstChild(
			"Humanoid"
		)
	then

		local human =
			part.Parent
			.Humanoid

		if contains(
			HitVictims,
			human
			)
		then
			return
		end

		local root =
			part.Parent:
			FindFirstChild(
				"HumanoidRootPart"
			)

		if root
			and
			not root.Anchored
		then

			local myRoot =
				Tool.Parent:
				FindFirstChild(
					"HumanoidRootPart"
				)

			if myRoot
				and
				checkTeams(
					human
				)
			then

				local delta =
					root.Position-
					myRoot.Position

				human.Sit=true

				tagHuman(
					human
				)

				human:
					TakeDamage(
						HitDamage
					)

				table.insert(
					HitVictims,
					human
				)

				local bv=
					Instance.new(
						"BodyVelocity"
					)

				bv.MaxForce=
					Vector3.new(
						1e9,
						1e9,
						1e9
					)

				bv.Velocity=
					delta.Unit
					*
					128

				bv.Parent=
					root

				game:
					GetService(
						"Debris"
					)
					:AddItem(
						bv,
						.05
					)

				Handle
					.Smack
					:Play()

			end
		end
	end

end

------------------------
-- FLY
------------------------

function stopFly(player)

	local f=
		FlyData[player]

	if not f then
		return
	end

	f.vel:Destroy()
	f.wind:Destroy()

	FlyData[player]=nil

	Remote:
		FireClient(
			player,
			"EndFly"
		)

end

function startFly()

	if not CanFly then
		return
	end

	CanFly=false

	task.delay(
		FlyCooldown,
		function()
			CanFly=true
		end
	)

	local player=
		getPlayer()

	local root=
		Tool.Parent:
		FindFirstChild(
			"HumanoidRootPart"
		)

	if not root then
		return
	end

	local vel=
		Instance.new(
			"BodyVelocity"
		)

	vel.MaxForce=
		Vector3.new(
			1e9,
			1e9,
			1e9
		)

	vel.Parent=root

	local wind=
		Instance.new(
			"ParticleEmitter"
		)

	wind.Texture=
		"rbxasset://textures/particles/smoke_main.dds"

	wind.Rate=100

	wind.Speed=
		NumberRange.new(8)

	wind.Parent=root

	FlyData[player]={
		vel=vel,
		wind=wind
	}

	task.delay(
		FlyTime,
		function()

			if FlyData[player] then
				stopFly(
					player
				)
			end

		end
	)

end

function updateFly(
	player,
	look
)

	local f=
		FlyData[player]

	if not f then
		return
	end

	f.vel.Velocity=
		look
		*
		FlySpeed

end

------------------------

function onEquip()

	local char =
		Tool.Parent

	local arm=
		Tool.ArmMesh:
		Clone()

	arm.Parent=
		char:
		FindFirstChild(
			"Right Arm"
		)

	ArmMesh=
		arm

end

function onUnequip()

	if ArmMesh then

		ArmMesh:
			Destroy()

		ArmMesh=nil

	end

	local p=
		getPlayer()

	if p then
		stopFly(
			p
		)
	end

end

function onLeftDown()

	if not SwingAble then
		return
	end

	SwingAble=false

	delay(
		SwingRestTime,
		function()
			SwingAble=true
		end
	)

	delay(
		HitWindup,
		function()

			HitAble=true

			delay(
				HitWindow,
				function()
					HitAble=false
				end
			)

		end
	)

	HitVictims={}

	Remote:
		FireClient(
			getPlayer(),
			"PlayAnimation",
			"Swing"
		)

	wait(.25)

	Handle.Boom:Play()

end

function onRemote(
	player,
	func,
	...
)

	if player~=
		getPlayer()
	then
		return
	end

	if func==
		"LeftDown"
	then

		onLeftDown()

	elseif func==
		"Fly"
	then

		startFly()

	elseif func==
		"StopFly"
	then

		stopFly(
			player
		)

	elseif func==
		"FlyDirection"
	then

		updateFly(
			player,
			...
		)

	end

end

Tool.Equipped:Connect(onEquip)
Tool.Unequipped:Connect(onUnequip)

Handle.Touched:Connect(onTouched)

Remote.OnServerEvent:Connect(onRemote)
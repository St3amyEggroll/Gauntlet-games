local Player =
	game:GetService(
		"Players"
	).LocalPlayer

local UIS =
	game:GetService(
		"UserInputService"
	)

local RunService =
	game:GetService(
		"RunService"
	)

local Tool =
	script.Parent

local Remote =
	Tool:
	WaitForChild(
		"Remote"
	)

local Flying =
	false

local Tracks={}
local Loop

--------------------------------

function playAnim(a)

	if not Tracks[a] then

		local anim=
			Tool:
			FindFirstChild(a)

		local hum=
			Tool.Parent:
			FindFirstChild(
				"Humanoid"
			)

		if anim
			and hum
		then

			Tracks[a]=
				hum:
				LoadAnimation(
					anim
				)

		end
	end

	if Tracks[a] then
		Tracks[a]:
			Play()
	end

end

--------------------------------

function toggleFly()

	if Flying then

		Flying=false

		Remote:
			FireServer(
				"StopFly"
			)

		if Loop then
			Loop:
				Disconnect()
		end

		return

	end

	Flying=true

	Remote:
		FireServer(
			"Fly"
		)

	Loop=
		RunService
		.RenderStepped
		:Connect(
			function()

				if not Flying then
					return
				end

				local cam=
				workspace
				.CurrentCamera

				local hum=
				Tool.Parent:
				FindFirstChild(
					"Humanoid"
				)

				if hum then

					Remote:
					FireServer(
						"FlyDirection",
						cam.CFrame
						.LookVector,
						hum
						.MoveDirection
					)

				end

			end)

end

--------------------------------

UIS.InputBegan:
	Connect(
		function(
			input,
			gp
		)

			if gp then
				return
			end

			if input
				.UserInputType
				==
				Enum
				.UserInputType
				.MouseButton1
			then

				Remote:
				FireServer(
					"LeftDown"
				)

			elseif input
				.KeyCode
				==
				Enum
				.KeyCode
				.F
			then

				toggleFly()

			end

		end)

Remote
	.OnClientEvent
	:Connect(
		function(
			func,
			anim
		)

			if func==
				"PlayAnimation"
			then

				playAnim(
					anim
				)

			elseif func==
				"EndFly"
			then

				Flying=false

				if Loop then
					Loop:
					Disconnect()
				end

			end

		end)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera

local frame = script.Parent.Frame
local textLabel = frame:WaitForChild("TextLabel")
local yesButton = frame:WaitForChild("YESButton")
local noButton = frame:WaitForChild("NOButton")

local dialogueStep = 0
local currentNPC = script.Parent.DialogueNPC.Value.Name

local function getCoins()
	return player:GetAttribute("Coins") or 0
end

local ProximityPrompt  =  script.Parent.DialogueNPC.Value.karol_guy.ProximityPrompt

ProximityPrompt.Triggered:Connect(function()
	currentNPC = "HomelessMan"
	frame.Visible = true
end)

local function updateDialogue()
	local coins = getCoins()

	if currentNPC == "HomelessMan" then
		if dialogueStep == 0 then
			textLabel.Text = "Homeless man - I found this weird glove thing on the ground somewhere"
			yesButton.Text = "Cool"
			noButton.Text = "Nevermind"
		elseif dialogueStep == 1 then
			textLabel.Text = "Homeless man - I’ll trade you it for 50 coins"
			yesButton.Text = "Buy for 50 coins"
			noButton.Text = "Decline"
		elseif dialogueStep == 2 then
			local coins = getCoins()
			if coins >= 50 then
				player:SetAttribute("Coins", coins - 50)
				textLabel.Text = "You bought the glove!"
				local GrassGauntlet  = game.ReplicatedStorage["Grass Gauntlet"]
				local GrassGauntletClone =  GrassGauntlet:Clone()

				GrassGauntletClone.Parent = player.Backpack
				
			else
				textLabel.Text = "You don’t have enough coins."
			end
			yesButton.Visible = false
			noButton.Visible = false
			wait(2)
			frame.Visible = false
		elseif dialogueStep == -1 then
			textLabel.Text = "Maybe next time."
			yesButton.Visible = false
			noButton.Visible = false
			wait(2)
			frame.Visible = false
		end

	elseif currentNPC == "Rock" then
		if dialogueStep == 0 then
			textLabel.Text = "Rock - I am rock"
			yesButton.Text = "Ok"
			noButton.Text = "I'm leaving"
		elseif dialogueStep == 1 then
			textLabel.Text = "Rock - I have gift, but at a price of 100"
			yesButton.Text = "Ok, what is it?"
			noButton.Text = "Too much, bye."
		elseif dialogueStep == 2 then
			textLabel.Text = "Rock - A stone gauntlet, made out of my own kind. Please take it, I can’t look at it any longer."
			yesButton.Text = "Buy for 100 coins"
			noButton.Text = "Decline"
		elseif dialogueStep == 3 then
			local coins = getCoins()
			if coins >= 100 then
				player:SetAttribute("Coins", coins - 100)
				textLabel.Text = "You received the stone gauntlet."
			else
				textLabel.Text = "You don’t have enough coins."
			end
			yesButton.Visible = false
			noButton.Visible = false
			wait(2)
			frame.Visible = false
		elseif dialogueStep == -1 then
			textLabel.Text = "The rock doesn't respond."
			yesButton.Visible = false
			noButton.Visible = false
			wait(2)
			frame.Visible = false
		end

	elseif currentNPC == "King" then
		if dialogueStep == 0 then
			textLabel.Text = "Player - Your majesty, I’ve come to prove my worth."
			yesButton.Text = "How much are we talking?"
			noButton.Text = "No thanks"
		elseif dialogueStep == 1 then
			textLabel.Text = "King - 500 Robux"
			yesButton.Text = "Buy for 500 Robux"
			noButton.Text = "Decline"
		elseif dialogueStep == 2 then
			textLabel.Text = "You bought the king’s finest gauntlet!"
			yesButton.Visible = false
			noButton.Visible = false
			wait(2)
			frame.Visible = false
		elseif dialogueStep == -1 then
			textLabel.Text = "King - Then leave my presence."
			yesButton.Visible = false
			noButton.Visible = false
			wait(2)
			frame.Visible = false
		end

	elseif currentNPC == "Devil" then
		if dialogueStep == 0 then
			textLabel.Text = "Devil - MWAHAHAHA, seems you beat my obby, now you get a reward."
			yesButton.Text = "What is it?"
			noButton.Text = "Nah I'm good."
		elseif dialogueStep == 1 then
			textLabel.Text = "Devil - My special fire gauntlet made in the depths of hell"
			yesButton.Text = "Take it"
			noButton.Text = "Decline"
		elseif dialogueStep == 2 then
			textLabel.Text = "You obtained the fire gauntlet!"
			yesButton.Visible = false
			noButton.Visible = false
			wait(2)
			frame.Visible = false
		elseif dialogueStep == -1 then
			textLabel.Text = "Devil - Foolish mortal. Begone!"
			yesButton.Visible = false
			noButton.Visible = false
			wait(2)
			frame.Visible = false
		end
	end
end

yesButton.MouseButton1Click:Connect(function()
	if currentNPC == "HomelessMan" then
		if dialogueStep == 0 then dialogueStep = 1
		elseif dialogueStep == 1 then dialogueStep = 2 end

	elseif currentNPC == "Rock" then
		if dialogueStep == 0 then dialogueStep = 1
		elseif dialogueStep == 1 then dialogueStep = 2
		elseif dialogueStep == 2 then dialogueStep = 3 end

	elseif currentNPC == "King" then
		if dialogueStep == 0 then dialogueStep = 1
		elseif dialogueStep == 1 then dialogueStep = 2 end

	elseif currentNPC == "Devil" then
		if dialogueStep == 0 then dialogueStep = 1
		elseif dialogueStep == 1 then dialogueStep = 2 end
	end

	updateDialogue()
end)

noButton.MouseButton1Click:Connect(function()
	dialogueStep = -1
	updateDialogue()
end)

frame:GetPropertyChangedSignal("Visible"):Connect(function()
	if frame.Visible then
		dialogueStep = 0
		yesButton.Visible = true
		noButton.Visible = true
		updateDialogue()
	end
end)

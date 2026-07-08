--// Module
local StatesManagerServer = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local core = ReplicatedStorage:WaitForChild("Core")
local data = ReplicatedStorage:WaitForChild("Data")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Data
local statesData = require(data:WaitForChild("States"))
local actionsData = require(data:WaitForChild("Actions"))

--// Events
local changeStateEvent = packet("ChangeState", packet.Instance, packet.String, packet.Boolean8)

--// Tables
local characters = {}

--// Functions
function StatesManagerServer.setStates(character: Model)
	if characters[character] then
		return
	end

	characters[character] = table.clone(statesData)
end

function StatesManagerServer.clearStates(character: Model)
	characters[character] = nil
end

function StatesManagerServer.canPerformAction(character: Model, actionName: string): boolean
	local actionAvailable = true
	local actionRequirements = actionsData[actionName]

	for stateName, stateValue in actionRequirements do
		if characters[character][stateName] ~= stateValue then
			actionAvailable = false
			break
		end
	end

	return actionAvailable
end

function StatesManagerServer.changeState(
	player: Player?,
	character: Model,
	stateName: string,
	stateValue: boolean,
	duration: number?
)
	local previousState = characters[character][stateName]

	characters[character][stateName] = stateValue
	character:SetAttribute(stateName, stateValue)

	if player then
		changeStateEvent:FireClient(player, character, stateName, stateValue)
	end

	if not duration then
		return
	end

	task.delay(duration, function()
		if not character or not characters[character] then
			return
		end

		characters[character][stateName] = previousState
		character:SetAttribute(stateName, previousState)

		if player then
			changeStateEvent:FireClient(player, character, stateName, previousState)
		end
	end)
end

function StatesManagerServer.getState(character: Model, stateName: string): boolean
	return characters[character][stateName]
end

function StatesManagerServer.playerAdded(player: Player)
	local character = player.Character

	if character then
		StatesManagerServer.setStates(character)
	end

	player.CharacterAdded:Connect(StatesManagerServer.setStates)
	player.CharacterRemoving:Connect(StatesManagerServer.clearStates)
end

--// Return
return StatesManagerServer

--// Module
local StatesManagerClient = {}

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
local states: { [string]: boolean } = {}

--// Functions
local function changeState(stateName: string, stateValue: boolean)
	states[stateName] = stateValue
end

function StatesManagerClient.canPerformAction(actionName: string): boolean
	local actionAvailable = true
	local actionRequirements = actionsData[actionName]

	for stateName, stateValue in actionRequirements do
		if states[stateName] ~= stateValue then
			actionAvailable = false
			break
		end
	end

	return actionAvailable
end

function StatesManagerClient.characterAdded(newCharacter: Model)
	states = table.clone(statesData)
end

function StatesManagerClient.characterRemoving()
	states = {}
end

function StatesManagerClient.initialize()
	changeStateEvent.OnClientEvent:Connect(changeState)
end

--// Return
return StatesManagerClient

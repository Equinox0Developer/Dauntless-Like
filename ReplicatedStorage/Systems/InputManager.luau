--// Module
local InputManager = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Folders
local systems = ReplicatedStorage:WaitForChild("Systems")

--// Systems
local combatManager = require(systems:WaitForChild("CombatManagerClient"))

--// Enums
local m1 = Enum.UserInputType.MouseButton1

local touch = Enum.UserInputType.Touch

local buttonX = Enum.KeyCode.ButtonX

--// Functions
local function checkInput(inputObject: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	
	local inputType = inputObject.UserInputType
	local keyCode = inputObject.KeyCode

	if inputType == m1 or inputType == touch or keyCode == buttonX then
		combatManager.attack()
	end
end

function InputManager.initialize()
	UserInputService.InputBegan:Connect(checkInput)
end

--// Return
return InputManager
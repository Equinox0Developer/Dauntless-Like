--// Module
local InputManager = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local systems = ReplicatedStorage:WaitForChild("Systems")
local inputs = ReplicatedStorage:WaitForChild("Inputs")

--// Systems
local combatManager = require(systems:WaitForChild("CombatManagerClient"))

--// Contexts
local generalContext = inputs:WaitForChild("General")
local battleContext = inputs:WaitForChild("Battle")

--// Actions
local moveAction = generalContext:WaitForChild("Move")
local attackAction = generalContext:WaitForChild("Attack")
local dashAction = battleContext:WaitForChild("Dash")

--// Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local lastMoveVector = Vector2.yAxis

--// Functions
local function isInputValid(pressed: boolean)
	return pressed and rootPart ~= nil
end

local function getMovingDirection()
	if math.abs(lastMoveVector.Y) > math.abs(lastMoveVector.X) then
		return lastMoveVector.Y > 0 and "Forward" or "Backward"
	else
		return lastMoveVector.X > 0 and "Right" or "Left"
	end
end

local function move(vector: Vector2)
	if vector.Magnitude > 0 then
		lastMoveVector = vector.Unit
	end
end

local function attack(pressed: boolean)
	if not isInputValid(pressed) then
		return
	end

	combatManager.attack()
end

local function dash(pressed: boolean)
	if not isInputValid(pressed) then
		return
	end

	print(getMovingDirection())
end

function InputManager.characterAdded(model: Model)
	character = model
	rootPart = character:WaitForChild("HumanoidRootPart")

	lastMoveVector = Vector2.yAxis
end

function InputManager.characterRemoving()
	character = nil
	rootPart = nil

	lastMoveVector = Vector2.yAxis
end

function InputManager.initialize()
	moveAction.StateChanged:Connect(move)
	attackAction.StateChanged:Connect(attack)
	dashAction.StateChanged:Connect(dash)
end

return InputManager

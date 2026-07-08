--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local systems = ReplicatedStorage:WaitForChild("Systems")
local menus = ReplicatedStorage:WaitForChild("UI"):WaitForChild("Menus")

--// Variables
local player = Players.LocalPlayer

--// Tables
local modules = {
	systems:WaitForChild("AnimationsManager"),
	systems:WaitForChild("PoolsManager"),
	systems:WaitForChild("EffectsManager"),
	systems:WaitForChild("ReplicationManagerClient"),
	systems:WaitForChild("StatesManagerClient"),
	systems:WaitForChild("CombatManagerClient"),
	systems:WaitForChild("InputManager"),
	menus:WaitForChild("Notifications"),
}

--// Functions
local function setup(module: ModuleScript)
	local requiredModule = require(module)

	if not requiredModule then
		return
	end

	if requiredModule.initialize then
		requiredModule.initialize()
	end

	if requiredModule.characterAdded then
		local character = player.Character

		if character then
			requiredModule.characterAdded(character)
		end

		player.CharacterAdded:Connect(requiredModule.characterAdded)
	end

	if requiredModule.characterRemoving then
		player.CharacterRemoving:Connect(requiredModule.characterRemoving)
	end
end

--// Execution
repeat
	task.wait(0.5)
until player:GetAttribute("Loaded") == true

for i, module in modules do
	setup(module)
end

--// Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local serverSystems = ServerScriptService:WaitForChild("Systems")
local clientSystems = ReplicatedStorage:WaitForChild("Systems")

--// Tables
local modules = {
	serverSystems:WaitForChild("ProfilesManager"),
	serverSystems:WaitForChild("ProfilesManager"):WaitForChild("Ranking"),
	serverSystems:WaitForChild("ProfilesManager"):WaitForChild("Marketplace"),
	serverSystems:WaitForChild("ProfilesManager"):WaitForChild("Leaderstats"),
	clientSystems:WaitForChild("PoolsManager"),
	serverSystems:WaitForChild("ReplicationManagerServer"),
	serverSystems:WaitForChild("CharactersManager"),
	serverSystems:WaitForChild("CodesManager"),
	serverSystems:WaitForChild("MarketplaceManager"),
	serverSystems:WaitForChild("StatesManagerServer"),
	serverSystems:WaitForChild("CombatManagerServer"),
	serverSystems:WaitForChild("BotsManager"),
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

	if requiredModule.playerAdded then
		for i, player in Players:GetPlayers() do
			requiredModule.playerAdded(player)
		end

		Players.PlayerAdded:Connect(requiredModule.playerAdded)
	end

	if requiredModule.playerRemoving then
		Players.PlayerRemoving:Connect(requiredModule.playerRemoving)
	end
end

--// Execution
for i, module in modules do
	setup(module)
end

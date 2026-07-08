--// Module
local BotsPool = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local assets = ReplicatedStorage:WaitForChild("Assets")

--// Assets
local botsAssets = assets:WaitForChild("Bots")

--// Variables
local poolsManager = require(script.Parent.Parent)

--// Functions
function BotsPool.initialize()
	for i, botModel in botsAssets:GetChildren() do
		local function createFunction(): Instance
			local unit = botModel:Clone()

			return unit
		end

		local function resetFunction(unit: Instance)
			unit.Parent = nil
		end

		poolsManager.createPool(`{botModel.Name}`, createFunction, resetFunction, 1)
	end
end

--// Return
return BotsPool
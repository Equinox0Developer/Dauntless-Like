--// Module
local Leaderstats = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Folders
local systems = ServerScriptService:WaitForChild("Systems")
local utils = ReplicatedStorage:WaitForChild("Utils")

--// Systems
local ProfilesManager = require(systems:WaitForChild("ProfilesManager"))

--// Utils
local abbreviator = require(utils:WaitForChild("Abbreviator"))

--// Tables
local leaderstats = {
	Core = {
		"Currency",
	},
}

local leaderstatConnections = {}

--// Functions
function Leaderstats.playerAdded(player)
	task.defer(function()
		repeat
			task.wait()
		until player:GetAttribute("Loaded")

		local playerData = ProfilesManager.localProfiles[player].Data

		local leaderstatsfolder = Instance.new("Folder", player)
		leaderstatsfolder.Name = "leaderstats"

		leaderstatConnections[player] = {}

		for domain, fields in leaderstats do
			for i, field in fields do
				local value = playerData[domain][field]

				local holder = Instance.new("StringValue", leaderstatsfolder)
				holder.Value = typeof(value) == "number" and abbreviator(value) or value
				holder.Name = field

				if not leaderstatConnections[player][field] then
					leaderstatConnections[player][field] = player:GetAttributeChangedSignal(field):Connect(function()
						local newValue = player:GetAttribute(field)

						if leaderstatsfolder and leaderstatsfolder.Parent then
							leaderstatsfolder[field].Value = typeof(newValue) == "number" and abbreviator(newValue) or tostring(newValue)
						end
					end)
				end
			end
		end
	end)
end

function Leaderstats.playerRemoving(player)
	if leaderstatConnections[player] then
		for _, connection in leaderstatConnections[player] do
			connection:Disconnect()
		end

		leaderstatConnections[player] = nil
	end
end

--// Return
return Leaderstats
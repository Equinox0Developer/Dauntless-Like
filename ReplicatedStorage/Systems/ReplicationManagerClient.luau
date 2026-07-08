--// Module
local ReplicationManagerClient = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local core = ReplicatedStorage:WaitForChild("Core")
local systems = ReplicatedStorage:WaitForChild("Systems")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Systems
local effectsManager = require(systems:WaitForChild("EffectsManager"))

--// Events
local replicateEvent = packet("Replicate", packet.Instance, packet.String, packet.Any)

--// Variables
local player = Players.LocalPlayer

--// Functions
local function replicate(casterPlayer: Player, effectType: string, effectData: {})
	local casterCharacter = casterPlayer.Character

	if not casterCharacter then
		return
	end

	task.spawn(function()
		local effectFunctions = effectsManager[`{effectType}_{casterPlayer:GetAttribute("Weapon")}`]
		effectFunctions.replicate(player, casterCharacter, effectData)
	end)
end

function ReplicationManagerClient.initialize()
	replicateEvent.OnClientEvent:Connect(replicate)
end

--// Return
return ReplicationManagerClient

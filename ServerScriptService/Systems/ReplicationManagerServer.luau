--// Module
local ReplicationManagerServer = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--// Folders
local core = ReplicatedStorage:WaitForChild("Core")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Events
local replicateEvent = packet("Replicate", packet.Instance, packet.String, packet.Any)

--// Variables
local taggedParts = CollectionService:GetTagged("Player")

--// Functions
local function searchNearby(character: Model, replicationRadius: number): {}
	local primaryPart = character.PrimaryPart

	if not primaryPart then
		return {}
	end

	local nearbyCharacters = {}

	local localOverlap = OverlapParams.new()
	localOverlap.FilterType = Enum.RaycastFilterType.Include
	localOverlap.FilterDescendantsInstances = taggedParts

	local results = workspace:GetPartBoundsInRadius(primaryPart.Position, replicationRadius, localOverlap)

	for i, part in results do
		local nearbyCharacter = part.Parent

		if table.find(nearbyCharacters, nearbyCharacter) or not nearbyCharacter:FindFirstChild("Humanoid") then
			continue
		end

		nearbyCharacters[nearbyCharacter] = (nearbyCharacter.PrimaryPart.Position - primaryPart.Position).Magnitude
	end

	return nearbyCharacters
end

function ReplicationManagerServer.replicate(player: Player, replicationRadius: number, effectType: string, effectData: {})
	task.defer(function()
		local character = player.Character

		if not character then
			return
		end

		local nearbyCharacters = searchNearby(character, replicationRadius)

		for nearbyCharacter, distance in nearbyCharacters do
			local nearbyPlayer = Players:GetPlayerFromCharacter(nearbyCharacter)

			if nearbyPlayer then
				replicateEvent:FireClient(nearbyPlayer, player, effectType, effectData)
			end
		end
	end)
end

function ReplicationManagerServer.initialize()
	CollectionService:GetInstanceAddedSignal("Player"):Connect(function(part)
		table.insert(taggedParts, part)
	end)

	CollectionService:GetInstanceRemovedSignal("Player"):Connect(function(part)
		local index = table.find(taggedParts, part)

		if index then
			table.remove(taggedParts, index)
		end
	end)
end

return ReplicationManagerServer

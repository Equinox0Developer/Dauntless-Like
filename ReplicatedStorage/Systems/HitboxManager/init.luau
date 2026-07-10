--// Module
local HitboxManager = {}

--// Services
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// Folders
-- local core = ReplicatedStorage:WaitForChild("Core")

--// Core
-- local signal = require(core:WaitForChild("Signal"))

--// Variables
local taggedParts = CollectionService:GetTagged("Player")

local overlapParameters = OverlapParams.new()
overlapParameters.FilterType = Enum.RaycastFilterType.Include
overlapParameters.FilterDescendantsInstances = taggedParts

--// Constants
local GRAVITY = workspace.Gravity
local VELOCITY_SAMPLES = 5

--// Tables
local velocityHistory: { [Model]: { Vector3 } } = {}

--// Types
local types = require(script.Types)

export type Parameters = types.Parameters
export type Hitbox = types.Hitbox

--// Execution
RunService.Heartbeat:Connect(function()
	GRAVITY = workspace.Gravity

	for character, samples in velocityHistory do
		local root = character:FindFirstChild("HumanoidRootPart")

		if not root then
			velocityHistory[character] = nil
			continue
		end

		table.insert(samples, root.AssemblyLinearVelocity)

		if #samples > VELOCITY_SAMPLES then
			table.remove(samples, 1)
		end
	end
end)

CollectionService:GetInstanceAddedSignal("Player"):Connect(function(part)
	table.insert(taggedParts, part)

	overlapParameters.FilterDescendantsInstances = taggedParts
end)

CollectionService:GetInstanceRemovedSignal("Player"):Connect(function(part)
	local index = table.find(taggedParts, part)

	if index then
		table.remove(taggedParts, index)
	end

	overlapParameters.FilterDescendantsInstances = taggedParts
end)

--// Functions
local function characterFiltering(ownerCharacter: Model, results: {}): {}
	local charactersFound = {}

	for i, part in results do
		local model = part:FindFirstAncestorOfClass("Model")

		if not model:FindFirstChild("Humanoid") or model == ownerCharacter or table.find(charactersFound, model) then
			continue
		end

		table.insert(charactersFound, model)
	end

	return charactersFound
end

local function getPartsInBox(creatorCharacter: Model, cframe: CFrame, size: Vector3)
	local results = workspace:GetPartBoundsInBox(cframe, size, overlapParameters)
	return characterFiltering(creatorCharacter, results)
end

local function getPartsInRadius(creatorCharacter: Model, position: Vector3, radius: number)
	local results = workspace:GetPartBoundsInRadius(position, radius, overlapParameters)
	return characterFiltering(creatorCharacter, results)
end

local function getSmoothedVelocity(creatorCharacter: Model): Vector3
	if not velocityHistory[creatorCharacter] then
		velocityHistory[creatorCharacter] = {}
		local root = creatorCharacter:FindFirstChild("HumanoidRootPart")
		if root then
			for _ = 1, VELOCITY_SAMPLES do
				table.insert(velocityHistory[creatorCharacter], root.AssemblyLinearVelocity)
			end
		end
	end

	local samples = velocityHistory[creatorCharacter]

	if not samples or #samples == 0 then
		return Vector3.zero
	end

	local sum = Vector3.zero

	for _, v in samples do
		sum += v
	end

	return sum / #samples
end

local function getPredictionTime(creatorCharacter: Model, fallback: number): number
	local player = Players:GetPlayerFromCharacter(creatorCharacter)

	if player then
		local ping = player:GetNetworkPing()

		if ping and ping == ping and ping >= 0 then
			return ping
		end
	end

	return fallback
end

local function predictVelocity(creatorCharacter: Model, predictionTime: number, cframe: CFrame)
	local root = creatorCharacter:FindFirstChild("HumanoidRootPart")

	if not root then
		return cframe
	end

	local t = getPredictionTime(creatorCharacter, predictionTime)
	local velocity = getSmoothedVelocity(creatorCharacter)

	local gravityOffset = Vector3.new(0, -0.5 * GRAVITY * t * t, 0)
	local predictedPosition = cframe.Position + velocity * t + gravityOffset

	local predictedCframe = CFrame.new(predictedPosition) * CFrame.fromMatrix(Vector3.zero, cframe.XVector, cframe.YVector, cframe.ZVector)

	return predictedCframe
end

local function showDebug(cframe: CFrame, size: number | Vector3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.BrickColor = BrickColor.new("Really red")
	part.Transparency = 0.75
	part.Material = Enum.Material.SmoothPlastic
	part.CFrame = cframe

	if typeof(size) == "number" then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(size * 2, size * 2, size * 2)
	else
		part.Shape = Enum.PartType.Block
		part.Size = size
	end

	part.Parent = workspace

	Debris:AddItem(part, 1)
end

function HitboxManager.new(creatorCharacter: Model, parameters: Parameters): Hitbox
	local hitbox = {}

	local cframe = parameters.CFrame or CFrame.new(0, 0, 0)
	local size = parameters.Size or nil

	local velocityPrediction = parameters.VelocityPrediction or false
	local predictionTime = parameters.PredictionTime or 0.1
	local willDebug = parameters.WillDebug or false

	local newCframe = cframe

	if velocityPrediction then
		newCframe = predictVelocity(creatorCharacter, predictionTime, cframe)
	end

	hitbox.CFrame = newCframe

	if typeof(size) == "number" then
		hitbox.Results = getPartsInRadius(creatorCharacter, newCframe.Position, size)
	else
		hitbox.Results = getPartsInBox(creatorCharacter, newCframe, size)
	end

	if willDebug then
		task.defer(showDebug, newCframe, size)
	end

	return hitbox
end

--// Return
return HitboxManager

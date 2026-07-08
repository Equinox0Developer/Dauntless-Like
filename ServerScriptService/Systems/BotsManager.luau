--// Module
local BotsManager = {}
BotsManager.__index = BotsManager

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Folders
local serverSystems = ServerScriptService:WaitForChild("Systems")
local clientSystems = ReplicatedStorage:WaitForChild("Systems")
local data = ReplicatedStorage:WaitForChild("Data")

--// Systems
local replicationManager = require(serverSystems:WaitForChild("ReplicationManagerServer"))
local poolManager = require(clientSystems:WaitForChild("PoolsManager"))

--// Data
local botsData = require(data:WaitForChild("Bots"))

--// Variables
local charactersFolder = workspace:WaitForChild("Players")
local botsFolder = workspace:WaitForChild("Bots")
local spawnsFolder = workspace:WaitForChild("Spawns")

local seed = math.random(1, 56565656)
local randomGenerator = Random.new(seed)

--// Tables
local bots = {}

--// Constants
local THINK_RATE = 1 / 10

local CLOSE_DISTANCE = 10

local ATTACK_CHANCES = {
	Light = 60,
	Medium = 30,
	Heavy = 10,
}

local BODY_PARTS = {
	Head = "Head",
	HumanoidRootPart = "Torso",
	UpperTorso = "Torso",
	LowerTorso = "Torso",
	RightUpperArm = "RightArm",
	RightLowerArm = "RightArm",
	RightHand = "RightArm",
	LeftUpperArm = "LeftArm",
	LeftLowerArm = "LeftArm",
	LeftHand = "LeftArm",
	RightUpperLeg = "RightLeg",
	RightLowerLeg = "RightLeg",
	RightFoot = "RightLeg",
	LeftUpperLeg = "LeftLeg",
	LeftLowerLeg = "LeftLeg",
	LeftFoot = "LeftLeg",
}

--// Functions
function BotsManager.getBot(botModel: Model)
	return bots[botModel]
end

function BotsManager.createBot(botName: string)
	local botData = table.clone(botsData[botName])

	local botPool = poolManager.getPool(botName)

	if not botData or not botPool then
		return
	end

	local bot = {
		Name = botName,
		State = "Idle",
		Active = false,
		AttackCooldown = 0,
		Model = nil,
		Humanoid = nil,
		RootPart = nil,
		Target = nil,
		SpawnPart = nil,
		SpawnPosition = nil,
		ChaseRadius = nil,
		Pool = botPool,
		ActualHealth = botData.Health,
		TotalHealth = botData.Health,
		Toughness = botData.Toughness,
		Speed = botData.Speed,
		DamageToStun = (botData.Health * 0.1) * (botData.Stability / 100),
		StunDamage = 0,
		BodyParts = {
			Head = {
				TotalHealth = botData.BreakableParts.Head,
				ActualHealth = botData.BreakableParts.Head,
				StunMultiplier = botData.StunnableParts.Head,
			},
			Torso = {
				TotalHealth = botData.BreakableParts.Head,
				ActualHealth = botData.BreakableParts.Torso,
				StunMultiplier = botData.StunnableParts.Torso,
			},
			RightArm = {
				TotalHealth = botData.BreakableParts.Head,
				ActualHealth = botData.BreakableParts.RightArm,
				StunMultiplier = botData.StunnableParts.RightArm,
			},
			LeftArm = {
				TotalHealth = botData.BreakableParts.Head,
				ActualHealth = botData.BreakableParts.LeftArm,
				StunMultiplier = botData.StunnableParts.LeftArm,
			},
			RightLeg = {
				TotalHealth = botData.BreakableParts.Head,
				ActualHealth = botData.BreakableParts.RightLeg,
				StunMultiplier = botData.StunnableParts.RightLeg,
			},
			LeftLeg = {
				TotalHealth = botData.BreakableParts.Head,
				ActualHealth = botData.BreakableParts.LeftLeg,
				StunMultiplier = botData.StunnableParts.LeftLeg,
			},
		},
		BrokenParts = {},
		Attacks = botData.Attacks,
	}

	setmetatable(bot, BotsManager)

	return bot
end

function BotsManager:spawnBot(spawnPart: BasePart)
	local botModel = self.Pool:getUnit()
	botModel.Humanoid.WalkSpeed = self.Speed

	local _, botSize = botModel:GetBoundingBox()
	local groundHeight = spawnPart.Position.Y + spawnPart.Size.Y / 2
	local Position = Vector3.new(spawnPart.Position.X, groundHeight + botSize.Y / 2, spawnPart.Position.Z)
	botModel:PivotTo(CFrame.new(Position))
	botModel.Parent = botsFolder

	self.Model = botModel
	self.Humanoid = botModel:WaitForChild("Humanoid")
	self.RootPart = botModel:WaitForChild("HumanoidRootPart")
	self.SpawnPart = spawnPart
	self.SpawnPosition = spawnPart.Position
	self.ChaseRadius = spawnPart:GetAttribute("Radius")

	bots[botModel] = self

	self:activate()
end

function BotsManager:despawnBot()
	self.Active = false

	local botModel = self.Model
	bots[botModel] = nil

	self.State = "Idle"
	self.ActualHealth = self.TotalHealth
	self.StunDamage = 0

	for _, values in self.BodyParts do
		values.ActualHealth = values.TotalHealth
	end

	table.clear(self.BrokenParts)

	self.Pool:releaseUnit(botModel)

	print(self.Name .. " released")
end

function BotsManager:takeDamage(player: Player, damage: number, partName: string)
	if self.State == "Idle" or self.State == "Returning" then
		self.State = "Searching"
	end

	self.ActualHealth -= damage / (self.Toughness / 100)

	local bodyPartName = BODY_PARTS[partName]
	local bodyPartValues = self.BodyParts[bodyPartName]

	if bodyPartValues.ActualHealth and bodyPartValues.ActualHealth > 0 then
		bodyPartValues.ActualHealth -= damage

		print(`{bodyPartName}'s health: {bodyPartValues.ActualHealth}`)
		replicationManager.replicate(player, 50, "Weapons", { botModel = self.Model, partName = partName, bodyPart = bodyPartName })

		if bodyPartValues.ActualHealth <= 0 then
			self:breakPart(bodyPartName)
		end
	end

	if bodyPartValues.StunMultiplier then
		self.StunDamage += damage * (bodyPartValues.StunMultiplier / 100)
	end

	print(`{self.Name}'s health: {self.ActualHealth}`)

	if self.State ~= "Stunned" and self.StunDamage >= self.DamageToStun then
		self:stunBot(5)
	end

	if self.ActualHealth <= 0 then
		self:despawnBot()
	end
end

function BotsManager:breakPart(bodyPartName: string)
	self.BodyParts[bodyPartName].health = 0

	local botModel = self.Model

	self.State = "Broke"

	task.delay(2.5, function()
		self.State = "Searching"

		print(botModel.Name .. " lift up from broke")
	end)

	print(botModel.Name .. " broke")

	table.insert(self.BrokenParts, bodyPartName)
end

function BotsManager:stunBot(duration: number)
	local botModel = self.Model

	self.State = "Stunned"

	task.delay(duration, function()
		self.StunDamage = 0
		self.State = "Searching"

		print(botModel.Name .. " woke up from stunned")
	end)

	print(botModel.Name .. " stunned")
end

function BotsManager:isTargetInRange()
	return (self.Target.PrimaryPart.Position - self.SpawnPosition).Magnitude < self.ChaseRadius
end

function BotsManager:isTargetClose()
	return (self.Target.PrimaryPart.Position - self.RootPart.Position).Magnitude < CLOSE_DISTANCE + 1
end

function BotsManager:updateSearch()
	local distanceLimit = self.ChaseRadius
	local closeCharacters = {}

	for _, character in charactersFolder:GetChildren() do
		local distance = (character.PrimaryPart.Position - self.SpawnPosition).Magnitude
		if distance < distanceLimit then
			table.insert(closeCharacters, character)
		end
	end

	if #closeCharacters > 0 then
		local chooseCharacter = closeCharacters[math.random(1, #closeCharacters)]
		self.Target = chooseCharacter
		self.State = "Chasing"
	else
		self.Target = nil
		self.State = "Returning"
	end
end

function BotsManager:updateChase()
	local target = self.Target

	if not target then
		return
	end

	local isTargetClose = self:isTargetClose()
	local isTargetInRange = self:isTargetInRange()

	if isTargetInRange and not isTargetClose then
		local botPosition = self.RootPart.Position
		local targetPosition = target.PrimaryPart.Position
		local direction = (targetPosition - botPosition).Unit
		local stopDistance = CLOSE_DISTANCE - 1
		local movePosition = targetPosition - (direction * stopDistance)

		self.Humanoid:MoveTo(movePosition)
	elseif isTargetInRange and isTargetClose then
		self.State = "Attacking"
	else
		self.Target = nil
		self.State = "Searching"
	end
end

function BotsManager:updateAttack()
	if not self:isTargetInRange() then
		self.Target = nil
		self.State = "Searching"
		return
	elseif not self:isTargetClose() then
		self.State = "Chasing"
		return
	end

	self.AttackCooldown -= THINK_RATE

	if self.AttackCooldown > 0 then
		return
	end

	local randomNumber = randomGenerator:NextInteger(1, 100)
	local attackType = nil

	if randomNumber <= ATTACK_CHANCES.Heavy then
		attackType = "Heavy"
	elseif randomNumber <= ATTACK_CHANCES.Medium then
		attackType = "Medium"
	else
		attackType = "Light"
	end

	local attacks = self.Attacks[attackType]
	randomNumber = randomGenerator:NextInteger(1, #attacks)
	local randomAttack = attacks[randomNumber]

	self.AttackCooldown = randomAttack.Cooldown

	print(`{self.Name} attacked with: {randomAttack.Name}!`)
end

function BotsManager:updateReturn()
	self.Humanoid:MoveTo(self.SpawnPosition)
end

function BotsManager:think()
	local state = self.State

	if state == "Idle" or state == "Broke" or state == "Stunned" then
		return
	elseif state == "Searching" then
		self:updateSearch()
	elseif state == "Chasing" then
		self:updateChase()
	elseif state == "Attacking" then
		self:updateAttack()
	elseif state == "Returning" then
		self:updateReturn()
	end
end

function BotsManager:activate()
	self.Active = true

	task.defer(function()
		while self.Active and task.wait(THINK_RATE) do
			self:think()
		end
	end)
end

function BotsManager.initialize()
	for _, spawnPart in spawnsFolder:GetChildren() do
		local botName = spawnPart:GetAttribute("Bot")
		local bot = BotsManager.createBot(botName)
		bot:spawnBot(spawnPart)
	end
end

--// Return
return BotsManager

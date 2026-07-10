--// Module
local BotsManager = {}
BotsManager.__index = BotsManager

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Folders
local assets = ReplicatedStorage:WaitForChild("Assets")
local core = ReplicatedStorage:WaitForChild("Core")
local systems = ServerScriptService:WaitForChild("Systems")
local data = ReplicatedStorage:WaitForChild("Data")

--// Assets
local botsAssets = assets:WaitForChild("Bots")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Systems
local replicationManager = require(systems:WaitForChild("ReplicationManagerServer"))

--// Data
local botsData = require(data:WaitForChild("Bots"))

--// Events
local updateBattleEvent = packet("UpdateBattle", packet.Any)
local enteredBattleEvent = packet("EnteredBattle", packet.Any)
local leftBattleEvent = packet("LeftBattle", packet.Any)

--// Variables
local charactersFolder = workspace:WaitForChild("Players")
local botsFolder = workspace:WaitForChild("Bots")
local spawnsFolder = workspace:WaitForChild("Spawns")

local seed = math.random(1, 56565656)
local randomGenerator = Random.new(seed)

local animationsFolder = script.Animations
local attacksFolder = script.Attacks

--// Tables
local botsTables = {}

local botsAttacks = {}

--// Constants
local THINK_RATE = 1 / 10

local BROKE_DURATION = 5
local STUNNED_DURATION = 10

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
	Torso = "Torso",
	RightUpperArm = "RightArm",
	RightLowerArm = "RightArm",
	RightHand = "RightArm",
	RightArm = "RightArm",
	LeftUpperArm = "LeftArm",
	LeftLowerArm = "LeftArm",
	LeftHand = "LeftArm",
	LeftArm = "LeftArm",
	RightUpperLeg = "RightLeg",
	RightLowerLeg = "RightLeg",
	RightFoot = "RightLeg",
	RightLeg = "RightLeg",
	LeftUpperLeg = "LeftLeg",
	LeftLowerLeg = "LeftLeg",
	LeftFoot = "LeftLeg",
	LeftLeg = "LeftLeg",
}

local ANIMATIONS = {
	Broke = {
		Fall = 130483794867730,
		Idle = 71884332622779,
		Wake = 108963992339191,
	},
	Stunned = {
		Fall = 130483794867730,
		Idle = 71884332622779,
		Wake = 108963992339191,
	},
}

--// Types
local types = require(script.Types)
export type Bot = typeof(setmetatable({} :: types.Bot, BotsManager))

--// Functions
function BotsManager.getBot(botModel: Model)
	return botsTables[botModel]
end

function BotsManager.createBot(botName: string)
	local botData = table.clone(botsData[botName])

	if not botData then
		return
	end

	local bot = {
		Name = botName,
		State = "Idle",
		Active = false,
		AttackCooldown = 0,
		Model = nil,
		Tracks = {},
		Connections = {},
		Humanoid = nil,
		RootPart = nil,
		Target = nil,
		SpawnPart = nil,
		SpawnPosition = nil,
		ChaseRadius = nil,
		ActualHealth = botData.Health,
		TotalHealth = botData.Health,
		Toughness = botData.Toughness,
		Speed = botData.Speed,
		DamageToStun = (botData.Health * 0.05) * (botData.Stability / 100),
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
		CharactersInBattle = {},
	}

	setmetatable(bot, BotsManager)

	return bot
end

function BotsManager:spawnBot(spawnPart: BasePart)
	local botModel = botsAssets:WaitForChild(self.Name):Clone()
	local humanoid = botModel:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator") or Instance.new("Animator", humanoid)

	humanoid.WalkSpeed = self.Speed

	local _, botSize = botModel:GetBoundingBox()
	local groundHeight = spawnPart.Position.Y + spawnPart.Size.Y / 2
	local Position = Vector3.new(spawnPart.Position.X, groundHeight + botSize.Y / 2, spawnPart.Position.Z)
	botModel:PivotTo(CFrame.new(Position))

	for _, animationInstance in animationsFolder:GetChildren() do
		self.Tracks[animationInstance.Name] = animator:LoadAnimation(animationInstance)
	end

	for _, track in self.Tracks do
		track:Play()
		track:Stop()
	end

	self.Model = botModel
	self.Humanoid = botModel:WaitForChild("Humanoid")
	self.RootPart = botModel:WaitForChild("HumanoidRootPart")
	self.SpawnPart = spawnPart
	self.SpawnPosition = spawnPart.Position
	self.ChaseRadius = spawnPart:GetAttribute("Radius")

	botsTables[botModel] = self

	botModel.Parent = botsFolder

	self:activate()
end

function BotsManager:despawnBot()
	self.Active = false

	local botModel = self.Model
	botsTables[botModel] = nil

	self.State = "Idle"
	self.ActualHealth = self.TotalHealth
	self.StunDamage = 0

	for _, values in self.BodyParts do
		values.ActualHealth = values.TotalHealth
	end

	for _, connection in self.Connections do
		connection:Disconnect()
	end

	table.clear(self.Tracks)
	table.clear(self.Connections)
	table.clear(self.BrokenParts)

	botModel:Destroy()
end

function BotsManager:animateState()
	local state = self.State
	local tracks = self.Tracks

	local fallTrack = tracks[`{state}_Fall`]
	local idleTrack = tracks[`{state}_Idle`]
	local wakeTrack = tracks[`{state}_Wake`]

	self.Connections["Fall"] = fallTrack:GetMarkerReachedSignal("Next"):Connect(function()
		idleTrack:Play(0.2)
		fallTrack:Stop(0.2)

		repeat
			task.wait(0.05)
		until self.State == "Waiting"

		wakeTrack:Play(0.2)
		idleTrack:Stop(0.2)
	end)

	self.Connections["Wake"] = wakeTrack:GetMarkerReachedSignal("Next"):Connect(function()
		wakeTrack:Stop()

		task.wait(0.15)

		self.State = "Searching"
	end)

	fallTrack:Play()
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

		-- print(`{bodyPartName}'s health: {bodyPartValues.ActualHealth}`)

		if bodyPartValues.ActualHealth <= 0 then
			self:breakPart(bodyPartName)
		end
	end

	if bodyPartValues.StunMultiplier then
		self.StunDamage += damage * (bodyPartValues.StunMultiplier / 100)
	end

	replicationManager.replicate(player, 50, "Weapons", { botModel = self.Model, bodyPartName = bodyPartName })

	-- print(`{self.Name}'s health: {self.ActualHealth}`)

	if self.State ~= "Stunned" and self.State ~= "Waiting" and self.StunDamage >= self.DamageToStun then
		self:stunBot()
	end

	if self.ActualHealth <= 0 then
		self:despawnBot()
	end

	for character, _ in self.CharactersInBattle do
		local actualPlayer = Players:GetPlayerFromCharacter(character)

		if not actualPlayer then
			continue
		end

		updateBattleEvent:FireClient(actualPlayer, {
			Name = self.Name,
			ActualHealth = self.ActualHealth,
			TotalHealth = self.TotalHealth,
		})
	end
end

function BotsManager:breakPart(bodyPartName: string)
	self.BodyParts[bodyPartName].health = 0

	self.State = "Broke"
	self:animateState()

	task.delay(BROKE_DURATION, function()
		self.State = "Waiting"
	end)

	self.BrokenParts[bodyPartName] = true
end

function BotsManager:stunBot()
	self.State = "Stunned"
	self:animateState()

	task.delay(STUNNED_DURATION, function()
		self.StunDamage = 0
		self.State = "Waiting"
	end)
end

function BotsManager:isTargetInRange()
	return (self.Target.PrimaryPart.Position - self.SpawnPosition).Magnitude < self.ChaseRadius
end

function BotsManager:isTargetClose()
	return (self.Target.PrimaryPart.Position - self.RootPart.Position).Magnitude < CLOSE_DISTANCE + 1
end

function BotsManager:checkPlayersInBattle()
	local distanceLimit = self.ChaseRadius
	local charactersInBattle = self.CharactersInBattle
	local closeCharacters = {}

	for _, character in charactersFolder:GetChildren() do
		local distance = (character.PrimaryPart.Position - self.SpawnPosition).Magnitude
		if distance < distanceLimit then
			closeCharacters[character] = true
		end
	end

	for character, _ in closeCharacters do
		if not charactersInBattle[character] then
			local player = Players:GetPlayerFromCharacter(character)

			if not player then
				return
			end

			enteredBattleEvent:FireClient(player, {
				Name = self.Name,
				ActualHealth = self.ActualHealth,
				TotalHealth = self.TotalHealth,
			})
		end
	end

	for character, _ in charactersInBattle do
		if not closeCharacters[character] then
			local player = Players:GetPlayerFromCharacter(character)

			if not player then
				return
			end

			leftBattleEvent:FireClient(player, {
				Name = self.Name,
				ActualHealth = self.ActualHealth,
				TotalHealth = self.TotalHealth,
			})
		end
	end

	self.CharactersInBattle = closeCharacters
end

function BotsManager:updateSearch()
	local charactersInBattle = {}

	for character, _ in self.CharactersInBattle do
		table.insert(charactersInBattle, character)
	end

	if #charactersInBattle > 0 then
		local chooseCharacter = charactersInBattle[math.random(1, #charactersInBattle)]
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

	if randomNumber <= ATTACK_CHANCES.Heavy and self.Attacks["Heavy"] then
		attackType = "Heavy"
	elseif randomNumber <= ATTACK_CHANCES.Medium and self.Attacks["Medium"] then
		attackType = "Medium"
	elseif self.Attacks["Light"] then
		attackType = "Light"
	else
		return
	end

	local attacks = self.Attacks[attackType]
	randomNumber = randomGenerator:NextInteger(1, #attacks)
	local randomAttack = attacks[randomNumber]

	self.AttackCooldown = randomAttack.Cooldown
	botsAttacks[self.Name].attack(self, randomAttack.Name)
end

function BotsManager:updateReturn()
	self.Humanoid:MoveTo(self.SpawnPosition)
end

function BotsManager:think()
	self:checkPlayersInBattle()

	local state = self.State

	if state == "Idle" or state == "Broke" or state == "Stunned" or state == "Waiting" then
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
		while task.wait(THINK_RATE) and self.Active do
			self:think()
		end
	end)
end

function BotsManager.initialize()
	for animationType, animationsTable in ANIMATIONS do
		for animationName, animationId in animationsTable do
			local animationInstance = Instance.new("Animation")
			animationInstance.Name = `{animationType}_{animationName}`
			animationInstance.AnimationId = `rbxassetid://{animationId}`
			animationInstance.Parent = animationsFolder
		end
	end

	for _, attackModule in attacksFolder:GetChildren() do
		botsAttacks[attackModule.Name] = require(attackModule)
	end

	for _, spawnPart in spawnsFolder:GetChildren() do
		local botName = spawnPart:GetAttribute("Bot")
		local bot = BotsManager.createBot(botName)
		bot:spawnBot(spawnPart)
	end
end

--// Return
return BotsManager

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

local animationsCache = {}

--// Constants
local THINK_RATE = 1 / 10

local BROKE_DURATION = 5
local STUNNED_DURATION = 10

local CLOSE_DISTANCE = 10

local TURN_SMOOTHNESS = 0.6
local TURN_TOLERANCE = 0.99

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

local CORE_ANIMATIONS_IDS = {
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
		DamageToStun = (botData.Health * 0.2) * (botData.Stability / 100),
		StunDamage = 0,
		BodyParts = {
			Head = {
				TotalHealth = botData.BodyParts.Head.Health,
				ActualHealth = botData.BodyParts.Head.Health,
				StunMultiplier = botData.BodyParts.Head.StunMultiplier,
			},
			Torso = {
				TotalHealth = botData.BodyParts.Torso.Health,
				ActualHealth = botData.BodyParts.Torso.Health,
				StunMultiplier = botData.BodyParts.Torso.StunMultiplier,
			},
			RightArm = {
				TotalHealth = botData.BodyParts.RightArm.Health,
				ActualHealth = botData.BodyParts.RightArm.Health,
				StunMultiplier = botData.BodyParts.RightArm.StunMultiplier,
			},
			LeftArm = {
				TotalHealth = botData.BodyParts.LeftArm.Health,
				ActualHealth = botData.BodyParts.LeftArm.Health,
				StunMultiplier = botData.BodyParts.LeftArm.StunMultiplier,
			},
			RightLeg = {
				TotalHealth = botData.BodyParts.RightLeg.Health,
				ActualHealth = botData.BodyParts.RightLeg.Health,
				StunMultiplier = botData.BodyParts.RightLeg.StunMultiplier,
			},
			LeftLeg = {
				TotalHealth = botData.BodyParts.LeftLeg.Health,
				ActualHealth = botData.BodyParts.LeftLeg.Health,
				StunMultiplier = botData.BodyParts.LeftLeg.StunMultiplier,
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

	for attackName, animationInstance in animationsCache[self.Name] do
		local track = animator:LoadAnimation(animationInstance)
		self.Tracks[attackName] = track

		track:GetMarkerReachedSignal("Hit"):Connect(function()
			botsAttacks[self.Name].attack(self, attackName)
		end)
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

function BotsManager:takeDamage(player: Player, attackData: { CoreDamage: number, BreakMultiplier: number, StunMultiplier: number, WoundMultiplier: number }, critical: boolean, partName: string)
	if self.State == "Idle" or self.State == "Returning" then
		self.State = "Searching"
	end

	local criticalMultiplier = critical and 2 or 1

	local bodyPartName = BODY_PARTS[partName]
	local bodyPartValues = self.BodyParts[bodyPartName]

	local damageReduction = (self.Toughness / 100)
	local coreDamage = (attackData.CoreDamage * criticalMultiplier) / damageReduction
	local breakDamage = coreDamage * attackData.BreakMultiplier
	local stunDamage = coreDamage * attackData.StunMultiplier * bodyPartValues.StunMultiplier
	--local woundDamage = coreDamage * attackData.WoundMultiplier

	self.ActualHealth -= coreDamage
	--print(`{self.Name} health is now: {self.ActualHealth}.`)

	if not self.BrokenParts[bodyPartName] then
		bodyPartValues.ActualHealth -= breakDamage
		--print(`{bodyPartName} health is now: {bodyPartValues.ActualHealth}.`)
		if bodyPartValues.ActualHealth <= 0 then
			self:breakPart(bodyPartName)
			print(`{bodyPartName} broke!`)
		end
	end

	self.StunDamage += stunDamage
	--print(`{self.Name} stun damage is now: {self.StunDamage}.`)

	if self.State ~= "Stunned" and self.State ~= "Waiting" and self.StunDamage >= self.DamageToStun then
		self:stunBot()
		print(`{self.Name} stunned!`)
	end

	if self.ActualHealth <= 0 then
		self:despawnBot()
	end

	task.defer(function()
		replicationManager.replicate(player, 50, "Weapons", {
			BotModel = self.Model,
			BodyPartName = bodyPartName,
			Critical = critical,
			CoreDamage = coreDamage,
			BreakDamage = breakDamage,
			StunDamage = stunDamage --[[, WoundDamage = woundDamage]],
		})

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
	end)
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

function BotsManager:faceTarget()
	local target = self.Target

	if not target or not target.PrimaryPart then
		return
	end

	local botPosition = self.RootPart.Position
	local targetPosition = target.PrimaryPart.Position
	local direction = Vector3.new(targetPosition.X - botPosition.X, 0, targetPosition.Z - botPosition.Z)

	if direction.Magnitude > 0.01 then
		local goalCFrame = CFrame.new(botPosition, botPosition + direction)
		self.RootPart.CFrame = self.RootPart.CFrame:Lerp(goalCFrame, TURN_SMOOTHNESS)
	end
end

function BotsManager:isFacingTarget()
	local target = self.Target

	if not target or not target.PrimaryPart then
		return false
	end

	local botPosition = self.RootPart.Position
	local targetPosition = target.PrimaryPart.Position
	local direction = Vector3.new(targetPosition.X - botPosition.X, 0, targetPosition.Z - botPosition.Z)

	if direction.Magnitude < 0.01 then
		return true
	end

	local lookVector = self.RootPart.CFrame.LookVector
	local dot = lookVector.Unit:Dot(direction.Unit)

	return dot >= TURN_TOLERANCE
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

	self:faceTarget()

	if not self:isFacingTarget() then
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
	self.Tracks[randomAttack.Name]:Play()
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

local function createCoreAnimations()
	for animationType, animationsTable in CORE_ANIMATIONS_IDS do
		for animationName, animationId in animationsTable do
			local animationInstance = Instance.new("Animation")
			animationInstance.Name = `{animationType}_{animationName}`
			animationInstance.AnimationId = `rbxassetid://{animationId}`
			animationInstance.Parent = animationsFolder
		end
	end
end

local function createAttackAnimations()
	for botName, botTable in botsData do
		animationsCache[botName] = {}
		for attackType, attacksTable in botTable.Attacks do
			for _, attackTable in attacksTable do
				local animationInstance = Instance.new("Animation")
				animationInstance.Name = attackTable.Name
				animationInstance.AnimationId = `rbxassetid://{attackTable.AnimationId}`
				animationInstance.Parent = animationsFolder

				animationsCache[botName][attackTable.Name] = animationInstance
			end
		end
	end
end

local function requireAttackModules()
	for _, attackModule in attacksFolder:GetChildren() do
		botsAttacks[attackModule.Name] = require(attackModule)
	end
end

local function setupBots()
	for _, spawnPart in spawnsFolder:GetChildren() do
		local botName = spawnPart:GetAttribute("Bot")
		local bot = BotsManager.createBot(botName)
		bot:spawnBot(spawnPart)
	end
end

function BotsManager.initialize()
	createCoreAnimations()
	createAttackAnimations()
	requireAttackModules()

	setupBots()
end

--// Return
return BotsManager

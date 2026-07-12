--// Module
local CombatManagerServer = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Folders
local core = ReplicatedStorage:WaitForChild("Core")
local systems = ServerScriptService:WaitForChild("Systems")
local data = ReplicatedStorage:WaitForChild("Data")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Systems
local botsManager = require(systems:WaitForChild("BotsManager"))
local stateManager = require(systems:WaitForChild("StatesManagerServer"))

--// Data
local weaponsData = require(data:WaitForChild("Weapons"))

--// Events
local attackEvent = packet("Attack", packet.NumberU8)
local hitEvent = packet("Hit", packet.Instance, packet.String, packet.NumberU8)

--// Variables
local seed = 56565656
local randomGenerator = Random.new(seed)

--// Tables
local violationCounts = {}
local slonessHistory = {}

--// Constants
local VIOLATION_TOLERANCE = 1.5
local MAX_VIOLATIONS = 3

--// Functions
local function checkSpeedViolation(player: Player, character: Model, allowedSpeed: number, checkDuration: number, myGen: number)
	local rootPart = character.PrimaryPart

	if not rootPart then
		return
	end

	local startPosition = rootPart.Position

	task.delay(checkDuration, function()
		if not character.Parent or not player.Parent then
			return
		end

		if slonessHistory[player] ~= myGen then
			return
		end

		local displacement = rootPart.Position - startPosition
		local horizontalDistance = Vector3.new(displacement.X, 0, displacement.Z).Magnitude
		local maxAllowed = (allowedSpeed * checkDuration) * VIOLATION_TOLERANCE

		if horizontalDistance > maxAllowed then
			violationCounts[player] = (violationCounts[player] or 0) + 1

			if violationCounts[player] >= MAX_VIOLATIONS then
				player:Kick("Are you cheating?")
			end
		end
	end)
end

local function applySlowness(player: Player, character: Model, humanoid: Humanoid, slowness: number, duration: number)
	if slowness <= 0 then
		return
	end

	if not player:GetAttribute("BaseWalkSpeed") then
		player:SetAttribute("BaseWalkSpeed", humanoid.WalkSpeed)
		player:SetAttribute("BaseJumpPower", humanoid.JumpPower)
	end

	local baseWalkSpeed = player:GetAttribute("BaseWalkSpeed")
	local baseJumpPower = player:GetAttribute("BaseJumpPower")

	local allowedSpeed = baseWalkSpeed * (1 - slowness / 100)

	humanoid.WalkSpeed = allowedSpeed
	humanoid.JumpPower = 0

	local actualSlow = (slonessHistory[player] or 0) + 1
	slonessHistory[player] = actualSlow

	checkSpeedViolation(player, character, allowedSpeed, duration, actualSlow)

	task.delay(duration, function()
		if not character.Parent then
			return
		end

		-- Só restaura se for a slowness mais recente
		if slonessHistory[player] ~= actualSlow then
			return
		end

		humanoid.WalkSpeed = baseWalkSpeed
		humanoid.JumpPower = baseJumpPower

		player:SetAttribute("BaseWalkSpeed", nil)
		player:SetAttribute("BaseJumpPower", nil)
	end)
end

local function attack(player: Player, actualAttack: number)
	local character = player.Character

	if not character then
		return
	end

	local humanoid = character:WaitForChild("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local weaponData = weaponsData[player:GetAttribute("Weapon")]
	local attackData = weaponData.Hits[actualAttack]
	local attackCooldown = attackData.Cooldown
	local stateName = `Attack{actualAttack}`

	if stateManager.canPerformAction(character, "Attack") and not stateManager.getState(character, stateName) then
		stateManager.changeState(player, character, "Attacking", true, attackCooldown - 0.1)
		stateManager.changeState(player, character, stateName, true, attackCooldown)

		applySlowness(player, character, humanoid, attackData.Slowness, attackCooldown + 0.2)
	end
end

local function hit(player: Player, botModel: Model, partName: string, actualAttack: number)
	local character = player.Character

	if not character then
		return
	end

	local humanoid = character:WaitForChild("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local stateName = `Attack{actualAttack}`

	if stateManager.getState(character, stateName) then
		stateManager.changeState(player, character, stateName, false)

		local bot = botsManager.getBot(botModel)

		local weaponData = weaponsData[player:GetAttribute("Weapon")]

		if not bot or not botModel.PrimaryPart or not weaponData then
			return
		end

		local inRange = (character.PrimaryPart.Position - botModel.PrimaryPart.Position).Magnitude < weaponData.Range

		if not inRange then
			return
		end

		local attackData = weaponData.Hits[actualAttack]

		local randomNumber = randomGenerator:NextInteger(1, 100)
		local critical = false

		if randomNumber <= attackData.CriticalChance then
			critical = true
		end

		bot:takeDamage(player, attackData, critical, partName)
	end
end

function CombatManagerServer.playerRemoving(player: Player)
	violationCounts[player] = nil
end

function CombatManagerServer.initialize()
	attackEvent.OnServerEvent:Connect(attack)
	hitEvent.OnServerEvent:Connect(hit)
	Players.PlayerRemoving:Connect(CombatManagerServer.playerRemoving)
end

--// Return
return CombatManagerServer

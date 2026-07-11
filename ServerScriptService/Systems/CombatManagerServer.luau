--// Module
local CombatManagerServer = {}

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
local movementLocks = {}

--// Constants
local MAX_HORIZONTAL_FORCE = 1e6

--// Functions
local function clearMovementLock(player: Player)
	local lock = movementLocks[player]

	if lock then
		lock.connection:Disconnect()

		if lock.constraint then
			lock.constraint:Destroy()
		end

		if lock.attachment then
			lock.attachment:Destroy()
		end

		movementLocks[player] = nil
	end
end

local function applySlowness(player: Player, character: Model, humanoid: Humanoid, slowness: number, duration: number)
	if slowness <= 0 then
		return
	end

	local rootPart = character.PrimaryPart

	if not rootPart then
		return
	end

	if not player:GetAttribute("BaseWalkSpeed") then
		player:SetAttribute("BaseWalkSpeed", humanoid.WalkSpeed)
		player:SetAttribute("BaseJumpPower", humanoid.JumpPower)
	end

	local baseWalkSpeed = player:GetAttribute("BaseWalkSpeed")
	local baseJumpPower = player:GetAttribute("BaseJumpPower")

	clearMovementLock(player)

	local allowedSpeed = baseWalkSpeed * (1 - slowness / 100)

	humanoid.WalkSpeed = allowedSpeed
	humanoid.JumpPower = 0

	local attachment = Instance.new("Attachment")
	attachment.Name = "MovementLockAttachment"
	attachment.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "MovementLock"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVelocity.MaxAxesForce = Vector3.new(MAX_HORIZONTAL_FORCE, 0, MAX_HORIZONTAL_FORCE)
	linearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
	linearVelocity.Parent = rootPart

	local elapsed = 0

	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime

		if elapsed >= duration or not character.Parent or humanoid.Health <= 0 then
			humanoid.WalkSpeed = baseWalkSpeed
			humanoid.JumpPower = baseJumpPower

			player:SetAttribute("BaseWalkSpeed", nil)
			player:SetAttribute("BaseJumpPower", nil)

			clearMovementLock(player)
			return
		end

		local moveDirection = humanoid.MoveDirection

		if moveDirection.Magnitude > 0.05 then
			linearVelocity.VectorVelocity = moveDirection.Unit * allowedSpeed
		else
			linearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
		end
	end)

	movementLocks[player] = { connection = connection, attachment = attachment, constraint = linearVelocity }
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
	clearMovementLock(player)
end

function CombatManagerServer.initialize()
	attackEvent.OnServerEvent:Connect(attack)
	hitEvent.OnServerEvent:Connect(hit)
end

--// Return
return CombatManagerServer

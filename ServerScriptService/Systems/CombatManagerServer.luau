--// Module
local CombatManagerServer = {}

--// Services
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

--// Functions
local function attack(player: Player, actualAttack: number)
	local character = player.Character

	if not character then
		return
	end

	local weaponData = weaponsData[player:GetAttribute("Weapon")]
	local attackCooldown = weaponData.Cooldown[actualAttack]
	local stateName = `Attack{actualAttack}`

	if stateManager.canPerformAction(character, "Attack") and not stateManager.getState(character, stateName) then
		stateManager.changeState(player, character, "Attacking", true, attackCooldown - 0.1)
		stateManager.changeState(player, character, stateName, true, attackCooldown)
	end
end

local function hit(player: Player, botModel: Model, partName: string, actualAttack: number)
	local character = player.Character

	if not character then
		return
	end

	local stateName = `Attack{actualAttack}`

	if stateManager.getState(character, stateName) then
		stateManager.changeState(player, character, stateName, false)

		local bot = botsManager.getBot(botModel)

		if not bot then
			return
		end

		local damage = weaponsData[player:GetAttribute("Weapon")].Damage[actualAttack]

		bot:takeDamage(player, damage, partName)
	end
end

function CombatManagerServer.initialize()
	attackEvent.OnServerEvent:Connect(attack)
	hitEvent.OnServerEvent:Connect(hit)
end

--// Return
return CombatManagerServer

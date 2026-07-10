--// Module
local Bot = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Folder
local serverSystems = ServerScriptService:WaitForChild("Systems")
local clientSystems = ReplicatedStorage:WaitForChild("Systems")

--// Systems
local playersManager = require(serverSystems:WaitForChild("PlayersManager"))
local hitboxManager = require(clientSystems:WaitForChild("HitboxManager"))

--// Functions
local botTypes = require(serverSystems:WaitForChild("BotsManager").Types)
export type Bot = botTypes.Bot

local hitboxTypes = require(clientSystems:WaitForChild("HitboxManager").Types)
export type Parameters = hitboxTypes.Parameters
export type Hitbox = hitboxTypes.Hitbox

--// Functions
Bot.Slap = function(bot: Bot)
	local botModel = bot.Model

	local parameters: Parameters = {
		CFrame = botModel.PrimaryPart.CFrame * CFrame.new(0, -2, -4),
		Size = Vector3.new(8, 8, 8),
		WillDebug = true,
	}

	local hitbox: Hitbox = hitboxManager.new(bot.Model, parameters)
	local results = hitbox.Results

	if not results then
		return
	end

	for _, character in results do
		local playerTable = playersManager.getPlayerTable(Players:GetPlayerFromCharacter(character))

		if not playerTable then
			return
		end

		playerTable:takeDamage(20)
	end
end

Bot.Spin = function() end
Bot.Throw = function() end

function Bot.attack(bot: Bot, attackName: string)
	Bot[attackName](bot)
end

--// Return
return Bot

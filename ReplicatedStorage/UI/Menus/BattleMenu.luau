--// Module
local BattleMenu = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local core = ReplicatedStorage:WaitForChild("Core")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Events
local enteredBattleEvent = packet("EnteredBattle", packet.Any)
local leftBattleEvent = packet("LeftBattle", packet.Any)

--// Functions
local function enteredBattle(bot)
	print(bot.ActualHealth)
end

local function leftBattle(bot)
	print(bot.ActualHealth)
end

function BattleMenu.initialize()
	enteredBattleEvent.OnClientEvent:Connect(enteredBattle)
	leftBattleEvent.OnClientEvent:Connect(leftBattle)
end

--// Return
return BattleMenu

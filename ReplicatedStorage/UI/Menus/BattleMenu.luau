--// Module
local BattleMenu = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local assets = ReplicatedStorage:WaitForChild("Assets")
local core = ReplicatedStorage:WaitForChild("Core")
local ui = ReplicatedStorage:WaitForChild("UI")

--// Assets
local menusAssets = assets:WaitForChild("Menus")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Utils
local effects = ui:WaitForChild("Effects")

--// Effects
local spring = require(effects:WaitForChild("Spring"))

--// Events
local updateBattleEvent = packet("UpdateBattle", packet.Any)
local enteredBattleEvent = packet("EnteredBattle", packet.Any)
local leftBattleEvent = packet("LeftBattle", packet.Any)

--// Variables
local player = Players.LocalPlayer

local playerGui = player.PlayerGui
local menu = menusAssets:WaitForChild("Battle")

local background = menu.Background

local healthBackground = background.Health
local healthFill = healthBackground.Fill
local healthNumber = healthBackground.Number

local lastHealth = 0

--// Constants
local DAMPING_RATIO = 1

--// Functions
local function updateBattle(bot)
	local actualHealth = bot.ActualHealth
	local totalHealth = bot.TotalHealth
	local scaledSize = actualHealth / totalHealth

	local difference = (actualHealth - lastHealth)
	local frequency = difference > 0 and 3 or 6

	healthNumber.Text = `{math.round(actualHealth)}/{math.round(totalHealth)}`

	spring.target(healthFill, DAMPING_RATIO, frequency, { Size = UDim2.fromScale(scaledSize, 1) })

	lastHealth = actualHealth
end

local function enteredBattle(bot)
	menu.Enabled = true

	updateBattle(bot)
end

local function leftBattle()
	menu.Enabled = false
end

function BattleMenu.initialize()
	updateBattleEvent.OnClientEvent:Connect(updateBattle)
	enteredBattleEvent.OnClientEvent:Connect(enteredBattle)
	leftBattleEvent.OnClientEvent:Connect(leftBattle)

	menu.Enabled = false
	menu.Parent = playerGui
end

--// Return
return BattleMenu

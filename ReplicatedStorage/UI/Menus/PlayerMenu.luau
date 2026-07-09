--// Module
local PlayerMenu = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local assets = ReplicatedStorage:WaitForChild("Assets")
local ui = ReplicatedStorage:WaitForChild("UI")

--// Assets
local menusAssets = assets:WaitForChild("Menus")

--// Utils
local effects = ui:WaitForChild("Effects")

--// Effects
local spring = require(effects:WaitForChild("Spring"))

--// Variables
local player = Players.LocalPlayer

local playerGui = player.PlayerGui
local menu = menusAssets:WaitForChild("Player"):Clone()

local background = menu.Background

local healthBackground = background.Health
local healthFill = healthBackground.Fill

local staminaBackground = background.Stamina
local staminaFill = staminaBackground.Fill

local lastHealth = player:GetAttribute("MaxHealth")
local lastStamina = player:GetAttribute("MaxStamina")

--// Constants
local DAMPING_RATIO = 1

--// Functions
function updateHealthBar()
	local actualHealth = player:GetAttribute("ActualHealth")
	local totalHealth = player:GetAttribute("MaxHealth")
	local scaledSize = actualHealth / totalHealth

	local difference = (actualHealth - lastHealth)
	local frequency = difference > 0 and 3 or 6

	spring.target(healthFill, DAMPING_RATIO, frequency, { size = scaledSize })
end

function updateStaminaBar()
	local actualStamina = player:GetAttribute("ActualStamina")
	local totalStamina = player:GetAttribute("MaxStamina")
	local scaledSize = actualStamina / totalStamina

	local difference = (actualStamina - lastStamina)
	local frequency = difference > 0 and 3 or 6

	spring.target(staminaFill, DAMPING_RATIO, frequency, { size = scaledSize })

	lastStamina = actualStamina
end

function PlayerMenu.initialize()
	updateHealthBar()
	updateStaminaBar()

	player:GetAttributeChangedSignal("ActualHealth"):Connect(updateHealthBar)
	player:GetAttributeChangedSignal("TotalHealth"):Connect(updateHealthBar)
	player:GetAttributeChangedSignal("ActualStamina"):Connect(updateStaminaBar)
	player:GetAttributeChangedSignal("TotalStamina"):Connect(updateStaminaBar)

	menu.Enabled = true
	menu.Parent = playerGui
end

--// Return
return PlayerMenu

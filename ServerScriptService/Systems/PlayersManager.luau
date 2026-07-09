--// Module
local PlayersManager = {}
PlayersManager.__index = PlayersManager

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--// Folders
local assets = ReplicatedStorage:WaitForChild("Assets")

--// Assets
local weaponsAssets = assets:WaitForChild("Weapons")

--// Variables
local charactersFolder = workspace:WaitForChild("Players")

--// Tables
local playersTables = {}

--// Constants
local UPDATE_RATE = 1 / 2

local HEALTH_REGENERATION_FACTOR = UPDATE_RATE / 250
local STAMINA_REGENERATION_FACTOR = UPDATE_RATE / 50

--// Types
export type playerTable = typeof(setmetatable(
	{} :: {
		Player: Player,
		Name: string,
		Character: Model?,
		Active: boolean,
		TotalHealth: number,
		ActualHealth: number,
		TotalStamina: number,
		ActualStamina: number,
	},
	PlayersManager
))

--// Functions
function PlayersManager:takeDamage(damage: number)
	local character = self.Character

	if not character then
		return
	end

	local newHealth = math.clamp(self.ActualHealth - damage, 0, self.TotalHealth)
	self.ActualHealth = newHealth
	self.Player:SetAttribute("ActualHealth", self.ActualHealth)

	if newHealth <= 0 then
		self.Active = false
		character.Humanoid.Health = 0
	end
end

function PlayersManager:regenerateHealth()
	local actualHealth = self.ActualHealth
	local totalHealth = self.TotalHealth

	if actualHealth < totalHealth then
		local newHealth = math.clamp(actualHealth + (totalHealth * HEALTH_REGENERATION_FACTOR), 0, totalHealth)
		self.ActualHealth = newHealth
		self.Player:SetAttribute("ActualHealth", newHealth)
	end
end

function PlayersManager:regenerateStamina()
	local actualStamina = self.ActualStamina
	local totalStamina = self.TotalStamina

	if actualStamina < totalStamina then
		local newStamina = math.clamp(actualStamina + (totalStamina * STAMINA_REGENERATION_FACTOR), 0, totalStamina)
		self.ActualStamina = newStamina
		self.Player:SetAttribute("ActualStamina", newStamina)
	end
end

function PlayersManager:update()
	self:regenerateHealth()
	self:regenerateStamina()
end

function PlayersManager:activate()
	self.Active = true

	task.defer(function()
		while task.wait(UPDATE_RATE) and self.Active do
			self:update()
		end
	end)
end

function PlayersManager:updateAttributes()
	local player = self.Player
	player:SetAttribute("TotalHealth", self.TotalHealth)
	player:SetAttribute("ActualHealth", self.ActualHealth)
	player:SetAttribute("TotalStamina", self.TotalStamina)
	player:SetAttribute("ActualStamina", self.ActualStamina)
end

function PlayersManager.setupModels(player: Player, character: Model)
	character.Parent = charactersFolder

	for _, child in character:GetChildren() do
		if child:IsA("BasePart") then
			CollectionService:AddTag(child, "Player")
		end
	end

	local weaponName

	repeat
		weaponName = player:GetAttribute("Weapon")
		task.wait(0.05)
	until weaponName

	local weaponModel = weaponsAssets:FindFirstChild(weaponName):Clone()
	weaponModel.Handle.Main.Part0 = character:WaitForChild("RightHand")
	weaponModel:PivotTo(character:WaitForChild("RightHand").CFrame)
	weaponModel.Parent = character
end

function PlayersManager.characterAdded(playerTable: playerTable, model: Model)
	playerTable.ActualHealth = playerTable.TotalHealth
	playerTable.ActualStamina = playerTable.TotalStamina
	playerTable.Character = model

	playerTable:updateAttributes()
	PlayersManager.setupModels(playerTable.Player, model)

	playerTable:activate()
end

function PlayersManager.characterRemoving(playerTable: playerTable)
	playerTable.Active = false
	playerTable.Character = nil
end

function PlayersManager.getPlayerTable(player: Player)
	return playersTables[player]
end

function PlayersManager.createPlayer(player: Player)
	local playerTable = {
		Player = player,
		Name = player.Name,
		Character = nil,
		Active = false,
		TotalHealth = 100,
		ActualHealth = 80,
		TotalStamina = 100,
		ActualStamina = 80,
	}

	setmetatable(playerTable, PlayersManager)

	playerTable:updateAttributes()

	playersTables[player] = playerTable

	if player.Character then
		PlayersManager.characterAdded(playerTable, player.Character)
	end

	player.CharacterAdded:Connect(function(model: Model)
		PlayersManager.characterAdded(playerTable, model)
	end)

	player.CharacterRemoving:Connect(function(model: Model)
		PlayersManager.characterRemoving(playerTable)
	end)

	player:SetAttribute("Table", true)

	return playerTable
end

function PlayersManager.playerAdded(player: Player)
	PlayersManager.createPlayer(player)
end

function PlayersManager.playerRemoving(player: Player)
	playersTables[player] = nil
end

--// Return
return PlayersManager

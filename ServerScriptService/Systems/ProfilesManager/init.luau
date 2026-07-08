--// Module
local ProfilesManager = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

--// Folders
local core = ServerScriptService:WaitForChild("Core")
local data = ReplicatedStorage:WaitForChild("Data")

--// Core
local profileStore = require(core:WaitForChild("ProfileStore"))

--// Data
local playersData = require(data:WaitForChild("Player"))

--// Variables
local liveVersion = 1
local testVersion = 1

local gameVersion = "0.0.0"

local runningSide = RunService:IsStudio() and `Test #{testVersion}` or `Live #{liveVersion}`

local globalProfile = profileStore.New(`PlayersDataStore {runningSide}`, playersData)

--// Constants
local DELAY_TIME = 1

--// Execution
ProfilesManager.liveVersion = liveVersion
ProfilesManager.testVersion = testVersion
ProfilesManager.gameVersion = gameVersion
ProfilesManager.runningSide = runningSide
ProfilesManager.localProfiles = {}

--// Functions
function ProfilesManager.changeValue(player: Player, domain: string, field: string, value: any, operation: string)
	local playerData = ProfilesManager.localProfiles[player].Data
	local dataDomain = playerData[domain]

	if not dataDomain then
		return
	end

	if operation == "=" then
		dataDomain[field] = value
	elseif operation == "+" then
		dataDomain[field] += value
	elseif operation == "-" then
		dataDomain[field] -= value
	end

	local newValue = dataDomain[field]
	player:SetAttribute(field, newValue)
end

function ProfilesManager.getData(player: Player, domain: string): {}
	local playerData = ProfilesManager.localProfiles[player]
	return playerData.Data[domain]
end

function ProfilesManager.playerAdded(player: Player)
	local userId = player.UserId

	local playerProfile = globalProfile:StartSessionAsync(`Player_{userId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not playerProfile then
		player:Kick("An error ocurred. Please rejoin.")
		return
	end

	playerProfile:AddUserId(userId)
	playerProfile:Reconcile()

	playerProfile.OnSessionEnd:Connect(function()
		ProfilesManager.localProfiles[player] = nil
		player:Kick("An error ocurred. Please rejoin.")
	end)

	if player.Parent ~= Players then
		playerProfile:EndSession()
		return
	end

	ProfilesManager.localProfiles[player] = playerProfile

	ProfilesManager.updateAttributes(player)

	local playerData = playerProfile.Data

	task.defer(function()
		while player and ProfilesManager.localProfiles[player] do
			task.wait(DELAY_TIME)

			if not ProfilesManager.localProfiles[player] then
				break
			end

			playerData.Total.TimePlayed += DELAY_TIME
			player:SetAttribute("TimePlayed", playerData.Total.TimePlayed)
		end
	end)

	player:SetAttribute("Loaded", true)
end

function ProfilesManager.playerRemoving(player: Player)
	local playerProfile = ProfilesManager.localProfiles[player]

	if not playerProfile then
		return
	end

	playerProfile:EndSession()
	ProfilesManager.localProfiles[player] = nil
end

function ProfilesManager.updateAttributes(player: Player)
	local playerData = ProfilesManager.localProfiles[player].Data

	for domain, fields in playerData do
		for field, value in fields do
			if type(value) ~= "table" then
				player:SetAttribute(field, value)
			end
		end
	end
end

function ProfilesManager.initialize()
	ReplicatedStorage:SetAttribute("GameVersion", gameVersion)
end

--// Return
return ProfilesManager
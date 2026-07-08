--// Module
local Marketplace = {}

--// Services
local ServerScriptService = game:GetService("ServerScriptService")

--// Folders
local systems = ServerScriptService:WaitForChild("Systems")

--// Systems
local ProfilesManager = require(systems:WaitForChild("ProfilesManager"))

--// Functions
function Marketplace.setPass(player: Player, passName: string)
	local passesData = ProfilesManager.localProfiles[player].Data.Passes
	passesData[passName] = true
	player:SetAttribute(passName, true)
end

function Marketplace.setPack(player: Player, packName: string)
	local packsData = ProfilesManager.localProfiles[player].Data.Packs
	packsData[packName] = true
	player:SetAttribute(packName, true)
end

function Marketplace.setBoost(player: Player, boostName: string, boostTime: number)
	local boostsData = ProfilesManager.localProfiles[player].Data.Boosts
	boostsData[boostName] = boostTime
	player:SetAttribute(boostName, boostTime)
end

function Marketplace.spentRobux(player: Player, amount: number)
	local totalData = ProfilesManager.localProfiles[player].Data.Total
	totalData.RobuxSpent += amount
end

--// Return
return Marketplace

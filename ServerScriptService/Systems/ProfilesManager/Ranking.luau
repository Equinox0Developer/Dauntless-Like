--// Module
local Ranking = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

--// Folders
local utils = ReplicatedStorage:WaitForChild("Utils")
local systems = ServerScriptService:WaitForChild("Systems")

--// Systems
local ProfilesManager = require(systems:WaitForChild("ProfilesManager"))

--// Utils
local abbreviator = require(utils:WaitForChild("Abbreviator"))
local timeFormatter = require(utils:WaitForChild("TimeFormatter"))

--// Variables
--local rankingsFolder = workspace:WaitForChild("Rankings")

--// DataStores
--local timePlayedRanking = DataStoreService:GetOrderedDataStore(`TimePlayedRanking{runningSide}`)

--// Tables
local colors = {
	Color3.fromRGB(255, 210, 20),
	Color3.fromRGB(155, 155, 155),
	Color3.fromRGB(120, 60, 0),
}

local prefix = {
	"st",
	"nd",
	"rd",
}

--// Functions
--[[local function getAllLeaderboards()
	local function getTop50(rankingStore)
		local success, pages = pcall(function()
			return rankingStore:GetSortedAsync(false, 100)
		end)

		if not success then
			return {}
		end

		local page = pages:GetCurrentPage()
		local leaderboard = {}

		for index, entry in page do
			leaderboard[index] = {
				UserId = tonumber(entry.key),
				Value = entry.value,
			}
		end

		return leaderboard
	end

	return {
		TimePlayed = getTop50(timePlayedRanking),
	}
end

local function loadAllLeaderboards()
	local leaderboards = getAllLeaderboards()

	for i, ranking in rankingsFolder:GetChildren() do
		local list = ranking.List.Surface.Frame

		for i, child in list:GetChildren() do
			if child.Name ~= "Template" and child.Name ~= "Layout" then
				child:Destroy()
			end
		end

		local template = list.Template
		template.Visible = false

		local leaderboard = leaderboards[ranking.Name]

		if not leaderboard then
			continue
		end

		for position, information in leaderboard do
			if information.UserId <= 0 then
				continue
			end

			local success, resolvedName = pcall(function()
				return Players:GetNameFromUserIdAsync(information.UserId)
			end)
			
			local playerName = success and resolvedName or tostring(information.UserId)

			local value = information.Value

			local holder = template:Clone()
			
			if ranking.Name == "TimePlayed" then
				holder.Value.Number.Text = `{timeFormatter.format(value, "hh:mm")}`
			else
				holder.Value.Number.Text = abbreviator(value)
			end
			
			holder.Order.Number.Text = `<font size="70">{position}</font><font size="50">{prefix[position] or "th"}</font>`
			holder.Title.Text = playerName
			holder.BackgroundColor3 = colors[position] or Color3.fromRGB(255, 255, 255)
			holder.Name = playerName
			holder.Parent = list
			holder.LayoutOrder = position
			holder.Visible = true

			task.wait(0.1)
		end

		task.wait(30)
	end
end

function Ranking.saveAllRankings(player: Player)
	local totalData = ProfileManager.getData(player, "Total")

	if not totalData then
		return
	end

	local userId = player.UserId

	task.spawn(function()
		local rankingUpdates = {
			{store = timePlayedRanking, value = math.round(totalData.TimePlayed), name = "TimePlayed"},
		}

		for _, update in rankingUpdates do
			local ok, error = pcall(function()
				update.store:SetAsync(userId, update.value)
			end)

			if not ok then
				warn(`Failed to save ranking {update.name} for user {userId}: {error}`)
			end
		end
	end)
end

function Ranking.loadAllLeaderboards()
	loadAllLeaderboards()
end]]

--// Return
return Ranking

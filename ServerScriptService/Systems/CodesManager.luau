--// Module
local CodesManager = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Folders
local systems = ServerScriptService:WaitForChild("Systems")
local core = ReplicatedStorage:WaitForChild("Core")
local data = ReplicatedStorage:WaitForChild("Data")
local menus = ReplicatedStorage:WaitForChild("UI"):WaitForChild("Menus")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Systems
local profilesManager = require(systems:WaitForChild("ProfilesManager"))

--// Data
local codesData = require(data:WaitForChild("Codes"))

--// Menus
local notificationsMenu = require(menus:WaitForChild("Notifications"))

--// Events
--local redeemCodeEvent = packet("RedeemCode", packet.String)

--// Constants
local GROUP_ID = 0

--// Functions
local function redeemCode(player: Player, code: string)
	if type(code) ~= "string" then
		return
	end

	code = code:upper():match("^%s*(.-)%s*$")

	local codeData = codesConfigs[code]

	if not codeData then
		--redeemCodeEvent:FireClient(player, "INVALID")
		return
	end

	if codeData.Expired == true then
		--redeemCodeEvent:FireClient(player, "EXPIRED")
		return
	end

		local inGroup = false

		local success = pcall(function()
			inGroup = player:IsInGroupAsync(GROUP_ID)
		end)

		if not success or not inGroup then
			--redeemCodeEvent:FireClient(player, "NOT_IN_GROUP")
			return
		end

	local codesData = profilesManager.getData(player, "Codes")

	if codesData[code] ~= nil then
		--redeemCodeEvent:FireClient(player, "ALREADY_USED")
		return
	end

	codesData[code] = os.time()

	local rewardType = codeData.Type

	if rewardType == "Currency" then
		profilesManager.changeValue(player, "Core", "Currency", codeData.Quantity, "+")
		notificationsMenu.PopSelectedPlayers({player}, `+{codeData.Quantity} Currency!`, "Reward")
	elseif rewardType == "Boost" then
		profilesManager.changeValue(player, "Boosts", codeData.Boost, codeData.Time, "+")
		notificationsMenu.PopSelectedPlayers({player}, `+{codeData.Time / 60}min of {codeData.Boost}!`, "Reward")
	end

	--redeemCodeEvent:FireClient(player, "SUCCESS")
end

function CodesManager.initialize()
	--redeemCodeEvent.OnServerEvent:Connect(redeemCode)
end

--// Return
return CodesManager
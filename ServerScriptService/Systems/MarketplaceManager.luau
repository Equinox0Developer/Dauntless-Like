--// Module
local MarketplaceManager = {
	Gamepasses = {},
	Products = {},
}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

--// Folders
local core = ReplicatedStorage:WaitForChild("Core")
local systems = ServerScriptService:WaitForChild("Systems")
local data = ReplicatedStorage:WaitForChild("Data")

--// Core
local packet = require(core:WaitForChild("Packet"))

--// Systems
local profilesMarketplace = require(systems.ProfilesManager:WaitForChild("Marketplace"))

--// Data
local marketplaceData = require(data:WaitForChild("Marketplace"))

--// Events
--local itemPurchaseResultEvent = packet("ItemPurchaseResult", packet.Boolean8, packet.String)

--// Constants
local GROUP_ID = 0

--// Tables
local functions = {
	--[[NameBoost = function(player: Player)
		profileManager.changeValue(player, "Boosts", "NameBoost", 3600, "+")
	end,
	Currency100 = function(player: Player)
		profileManager.changeValue(player, "Core", "Currrency", 100, "+")
	end,
	PackName = function(player: Player)
		if player:GetAttribute("PackName") then
			return
		end

		profileMarketplace.setPack(player, "PackName")
		profileManager.changeValue(player, "Core", "Stars", 10000, "+")
	end,]]
}

--// Execution
for marketplaceType, values in marketplaceData do
	for name, id in values do
		MarketplaceManager[marketplaceType][id] = functions[name] or name
	end
end

--// Functions
local function getPrice(id: number): number
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.GamePass)
	end)

	if not ok or not info or not info.PriceInRobux then
		ok, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.Product)
		end)
	end

	return (ok and info and info.PriceInRobux) or 0
end

local function ownsGamePassSafe(player: Player, gamepassId: number): boolean
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	return ok and result == true
end

local function purchaseProduct(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profileLoaded = player:GetAttribute("Loaded")

	if not profileLoaded then
		local deadline = os.clock() + 10

		repeat
			task.wait(0.5)
			profileLoaded = player:GetAttribute("Loaded")
		until profileLoaded or os.clock() >= deadline or player.Parent == nil
	end

	if not profileLoaded or player.Parent == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId

	local product = MarketplaceManager.Products[productId]

	if not product then
		warn("Unknown product:", productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, error = pcall(product, player)

	if not ok then
		warn("Product delivery failed:", error)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print(player.Name, "purchased product", productId)

	profilesMarketplace.spentRobux(player, getPrice(productId))

	--itemPurchaseResultEvent:FireClient(player, player, productId, true)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function purchaseGamepass(player: Player, gamepassId: number, hasPurchased: boolean)
	if not hasPurchased then
		return
	end

	local gamepassName = MarketplaceManager.Gamepasses[gamepassId]

	if not gamepassName then
		warn("Gamepass not found:", gamepassId)
		return
	end

	player:SetAttribute(gamepassName, true)

	print(`{player.Name} purchased: {gamepassName}`)

	profilesMarketplace.setPass(player, gamepassName)
	profilesMarketplace.spentRobux(player, getPrice(gamepassId))

	--itemPurchaseResultEvent:FireClient(player, player, gamepassId, true)
end

function MarketplaceManager.playerAdded(player: Player)
	while player:GetAttribute("Loaded") ~= true do
		player:GetAttributeChangedSignal("Loaded"):Wait()
	end

	local pending = 0
	local done = Instance.new("BindableEvent")

	for gamepassId, gamepassName in MarketplaceManager.Gamepasses do
		pending += 1

		task.spawn(function()
			if ownsGamePassSafe(player, gamepassId) then
				profilesMarketplace.setPass(player, gamepassName)
			end

			pending -= 1

			if pending == 0 then
				done:Fire()
			end
		end)
	end

	if pending > 0 then
		done.Event:Wait()
	end

	done:Destroy()
end

function MarketplaceManager.initialize()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(purchaseGamepass)
	MarketplaceService.ProcessReceipt = purchaseProduct
end

--// Return
return MarketplaceManager
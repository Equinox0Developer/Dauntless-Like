--// Module
local IndicatorsPool = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local assets = ReplicatedStorage:WaitForChild("Assets")

--// Assets
local billboardsAssets = assets:WaitForChild("Billboards")

--// Variables
local poolsManager = require(script.Parent.Parent)

local indicatorBillboard = billboardsAssets:WaitForChild("Indicator")

--// Functions
function IndicatorsPool.initialize()
	local function createFunction(): Instance
		local unit = indicatorBillboard:Clone()

		return unit
	end

	local function resetFunction(unit: Instance)
		unit.Parent = nil
	end

	poolsManager.createPool("Indicators", createFunction, resetFunction, 1)
end

--// Return
return IndicatorsPool

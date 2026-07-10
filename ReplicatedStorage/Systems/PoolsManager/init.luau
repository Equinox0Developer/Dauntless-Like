--// Module
local PoolsManager = {}
PoolsManager.__index = PoolsManager

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Folders
local assets = ReplicatedStorage.Assets
local poolsFolder = assets.Pools

--// Tables
local pools = {}

--// Variables
local runningSide = RunService:IsServer() and "Server" or "Client"

--// Types
local types = require(script.Types)
export type Pool = typeof(setmetatable({} :: types.Pool, PoolsManager))

--// Functions
function PoolsManager.initialize()
	for i, pool in script[runningSide]:GetChildren() do
		local requiredPool = require(pool)
		requiredPool.initialize()
	end
end

function PoolsManager.createPool(poolName: string, createFunction: () -> Instance | Model, resetFunction: (Instance) -> any, initialStock: number?, minCapacity: number?, maxCapacity: number?): Pool
	local poolFolder = Instance.new("Folder", poolsFolder)
	poolFolder.Name = poolName

	local pool = {
		name = poolName,
		minCapacity = minCapacity or 0,
		maxCapacity = maxCapacity or 1000,
		createFunction = createFunction,
		resetFunction = resetFunction,
		folder = poolFolder,
		inStock = {},
		inUse = {},
	}

	pools[poolName] = pool

	setmetatable(pool, PoolsManager)

	pool:createUnit(initialStock or pool.minCapacity)

	return pool
end

function PoolsManager.getPool(poolName: string): Pool
	return pools[poolName]
end

function PoolsManager:createUnit(quantity: number): Instance?
	if (#self.inStock + #self.inUse) >= self.maxCapacity then
		return
	end

	local newUnit = nil

	for i = 1, quantity, 1 do
		newUnit = self.createFunction()
		newUnit.Parent = self.folder
		table.insert(self.inStock, newUnit)
	end

	return newUnit
end

function PoolsManager:restockUnits()
	task.defer(function()
		local needed = self.minCapacity - (#self.inStock + #self.inUse)

		if needed > 0 then
			self:createUnit(needed)
		end
	end)
end

function PoolsManager:getUnit(): Instance | Model
	local unit = self.inStock[1]

	if not unit then
		unit = self:createUnit(1)
	end

	table.remove(self.inStock, table.find(self.inStock, unit))
	table.insert(self.inUse, unit)

	self:restockUnits()

	return unit
end

function PoolsManager:releaseUnit(unit: Instance, timer: number?)
	task.delay(timer or 0, function()
		if unit:GetAttribute("Variant") then
			self:removeUnit(unit)
			return
		end

		local index = table.find(self.inUse, unit)
		if index then
			table.remove(self.inUse, index)
		end

		unit.Parent = self.folder
		self.resetFunction(unit)
		task.wait(0.25)
		table.insert(self.inStock, unit)
	end)
end

function PoolsManager:removeUnit(unit: Instance | Model)
	local position = table.find(self.inStock, unit)

	if position then
		table.remove(self.inStock, position)
	else
		position = table.find(self.inUse, unit)
		if position then
			table.remove(self.inUse, position)
		end
	end

	unit:Destroy()
end

function PoolsManager:clearPool()
	task.defer(function()
		local stockSnapshot = table.clone(self.inStock)
		local inUseSnapshot = table.clone(self.inUse)

		table.clear(self.inStock)
		table.clear(self.inUse)

		for i, unit in stockSnapshot do
			unit:Destroy()
		end

		for i, unit in inUseSnapshot do
			unit:Destroy()
		end
	end)
end

--// Return
return PoolsManager

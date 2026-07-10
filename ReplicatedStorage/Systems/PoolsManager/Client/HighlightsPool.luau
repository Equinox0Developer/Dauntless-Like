--// Module
local HighlightsPool = {}

--// Variables
local poolsManager = require(script.Parent.Parent)

--// Functions
function HighlightsPool.initialize()
	local function createFunction(): Instance
		local unit = Instance.new("Highlight")

		return unit
	end

	local function resetFunction(unit: Instance)
		unit.Parent = nil
	end

	poolsManager.createPool("Highlights", createFunction, resetFunction, 1)
end

--// Return
return HighlightsPool

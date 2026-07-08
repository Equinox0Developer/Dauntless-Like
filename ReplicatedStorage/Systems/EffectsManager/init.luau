--// Module
local EffectsManager = {}

--// Functions
function EffectsManager.initialize()
	for _, effectType in script:GetChildren() do
		for _, moduleScript in effectType:GetChildren() do
			EffectsManager[`{effectType.Name}_{moduleScript.Name}`] = require(moduleScript)
		end
	end
end

--// Return
return EffectsManager

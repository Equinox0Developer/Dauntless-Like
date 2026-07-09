--// Module
local States = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local systems = ReplicatedStorage:WaitForChild("Systems")

--// Systems
local poolsManager = require(systems:WaitForChild("PoolsManager"))

--// Variables

type effectData = {
	botModel: Model,
}

--// Functions
function States.replicate(localPlayer: Player, casterCharacter: Model, effectData: effectData)

end

--// Return
return States
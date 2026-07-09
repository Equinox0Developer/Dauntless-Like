--// Module
local Sword = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
local systems = ReplicatedStorage:WaitForChild("Systems")

--// Systems
local poolsManager = require(systems:WaitForChild("PoolsManager"))

--// Variables
local highlightsPool = poolsManager.getPool("Highlights")

export type effectData = {
	botModel: Model,
	bodyPartName: string,
}

--// Functions
function Sword.replicate(localPlayer: Player, casterCharacter: Model, effectData: effectData)
	local bodyPart = effectData.botModel[effectData.bodyPartName]

	local highlight = highlightsPool:getUnit()
	highlight.Adornee = bodyPart
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = bodyPart

	highlightsPool:releaseUnit(highlight, 0.25)
end

--// Return
return Sword

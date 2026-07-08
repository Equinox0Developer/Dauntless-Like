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

type effectData = {
	botModel: Model,
	partName: string,
	bodyPart: string,
}

--// Functions
function Sword.replicate(localPlayer: Player, casterCharacter: Model, effectData: effectData)
	local redHighlight = highlightsPool:getUnit()
	redHighlight.FillColor = Color3.fromRGB(255, 0, 0)
	redHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	redHighlight.Parent = effectData.botModel[effectData.bodyPart]

	--[[ local greenHighlight = highlightsPool:getUnit()
	greenHighlight.FillColor = Color3.fromRGB(0, 255, 0)
	greenHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	greenHighlight.Parent = effectData.botModel[effectData.partName] ]]

	highlightsPool:releaseUnit(redHighlight, 0.5)
	--highlightsPool:releaseUnit(greenHighlight, 0.5)
end

--// Return
return Sword

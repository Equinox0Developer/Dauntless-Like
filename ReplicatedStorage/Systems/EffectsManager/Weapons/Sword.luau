--// Module
local Sword = {}

--// Services
--local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders
--local systems = ReplicatedStorage:WaitForChild("Systems")

--// Variables
local generalEffects = require(script.Parent.General)

--// Types
export type effectData = {
	botModel: Model,
	bodyPartName: string,
}

--// Functions
function Sword.replicate(localPlayer: Player, casterCharacter: Model, effectData: effectData)
	local bodyPart = effectData.botModel[effectData.bodyPartName]
	generalEffects.hit(bodyPart)
end

--// Return
return Sword

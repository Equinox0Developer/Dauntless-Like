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
	BotModel: Model,
	BodyPartName: string,
	CoreDamage: number,
	BreakDamage: number,
	StunDamage: number,
	WoundDamage: number,
}

--// Functions
function Sword.replicate(localPlayer: Player, casterCharacter: Model, effectData: effectData)
	local bodyPart = effectData.BotModel[effectData.BodyPartName]

	generalEffects.indicator(bodyPart, "Core", effectData.CoreDamage)
	generalEffects.indicator(bodyPart, "Break", effectData.BreakDamage)
	generalEffects.indicator(bodyPart, "Stun", effectData.StunDamage)
	--generalEffects.indicator(bodyPart, "Wound", effectData.WoundDamage)

	generalEffects.highlight(bodyPart)
end

--// Return
return Sword

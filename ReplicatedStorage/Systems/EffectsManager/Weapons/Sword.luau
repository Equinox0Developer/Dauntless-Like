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
	Critical: boolean,
	CoreDamage: number,
	BreakDamage: number,
	StunDamage: number,
	WoundDamage: number,
}

--// Functions
function Sword.replicate(localPlayer: Player, casterCharacter: Model, effectData: effectData)
	local bodyPart = effectData.BotModel[effectData.BodyPartName]

	local coreDamage = effectData.CoreDamage
	local breakDamage = effectData.BreakDamage
	local stunDamage = effectData.StunDamage
	--local woundDamage = effectData.WoundDamage

	if coreDamage == 0 then
		return
	end

	local critical = effectData.Critical

	generalEffects.indicator(bodyPart, "Core", coreDamage, critical)

	if breakDamage > 0 then
		generalEffects.indicator(bodyPart, "Break", breakDamage, critical)
	end
	if stunDamage > 0 then
		generalEffects.indicator(bodyPart, "Stun", stunDamage, critical)
	end
	--[[if woundDamage > 0 then
		generalEffects.indicator(bodyPart, "Wound", woundDamage, critical)
	end]]

	generalEffects.highlight(bodyPart)
end

--// Return
return Sword

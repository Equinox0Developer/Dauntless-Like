local Types = {}

export type Bot = {
	Name: string,
	State: "Idle" | "Searching" | "Chasing" | "Attacking" | "Returning" | "Broke" | "Stunned" | "Waiting",
	Active: boolean,
	AttackCooldown: number,
	Model: Model,
	Humanoid: Humanoid,
	Animator: Animator,
	RootPart: BasePart,
	Tracks: {},
	Connections: {},
	Target: Model,
	SpawnPart: BasePart,
	SpawnPosition: Vector3,
	ChaseRadius: number,
	ActualHealth: number,
	TotalHealth: number,
	Toughness: number,
	Speed: number,
	DamageToStun: number,
	StunDamage: number,
	BodyParts: {
		Head: {
			TotalHealth: number,
			ActualHealth: number,
			StunMultiplier: number,
		},
		Torso: {
			TotalHealth: number,
			ActualHealth: number,
			StunMultiplier: number,
		},
		RightArm: {
			TotalHealth: number,
			ActualHealth: number,
			StunMultiplier: number,
		},
		LeftArm: {
			TotalHealth: number,
			ActualHealth: number,
			StunMultiplier: number,
		},
		RightLeg: {
			TotalHealth: number,
			ActualHealth: number,
			StunMultiplier: number,
		},
		LeftLeg: {
			TotalHealth: number,
			ActualHealth: number,
			StunMultiplier: number,
		},
	},
	BrokenParts: { string },
	Attacks: {
		Light: { {} },
		Medium: { {} },
		Heavy: { {} },
	},
	CharactersInBattle: { Model },
}

return Types

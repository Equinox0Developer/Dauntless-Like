local Weapons = {
	Sword = {
		Range = 12,
		Hits = {
			{ CoreDamage = 5, Cooldown = 0.43, BreakMultiplier = 1.2, StunMultiplier = 0.5, WoundMultiplier = 0 },
			{ CoreDamage = 5, Cooldown = 0.53, BreakMultiplier = 1.2, StunMultiplier = 0.5, WoundMultiplier = 0 },
			{ CoreDamage = 5, Cooldown = 0.79, BreakMultiplier = 1.2, StunMultiplier = 0.5, WoundMultiplier = 0 },
			{ CoreDamage = 7.5, Cooldown = 1.6, BreakMultiplier = 1.4, StunMultiplier = 1.0, WoundMultiplier = 0 },
		},
	},
}

return table.clone(Weapons)

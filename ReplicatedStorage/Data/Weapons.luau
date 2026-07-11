local Weapons = {
	Sword = {
		Range = 12,
		Hits = {
			{ Cooldown = 0.45, CriticalChance = 10, CoreDamage = 10, BreakMultiplier = 1.2, StunMultiplier = 0.5, WoundMultiplier = 0, Slowness = 70 },
			{ Cooldown = 0.55, CriticalChance = 10, CoreDamage = 10, BreakMultiplier = 1.2, StunMultiplier = 0.5, WoundMultiplier = 0, Slowness = 70 },
			{ Cooldown = 0.79, CriticalChance = 10, CoreDamage = 10, BreakMultiplier = 1.2, StunMultiplier = 0.5, WoundMultiplier = 0, Slowness = 70 },
			{ Cooldown = 0.75, CriticalChance = 20, CoreDamage = 15, BreakMultiplier = 1.4, StunMultiplier = 1.0, WoundMultiplier = 0, Slowness = 90 },
		},
	},
}

return table.clone(Weapons)

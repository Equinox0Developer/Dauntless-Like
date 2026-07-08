local Weapons = {
	Sword = {
		Damage = { 5, 5, 5, 7.5 },
		Cooldown = { 0.43, 0.53, 0.79, 1.6 },
		Stun = { 0.5, 0.5, 0.5, 1 },
	},
}

return table.clone(Weapons)

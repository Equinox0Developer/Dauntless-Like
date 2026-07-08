local Player = {
	Core = {
		Weapon = "Sword",
		Currency = 0,
		Phase = 1,
	},
	Total = {
		TimePlayed = 0,
		RobuxSpent = 0,
	},
	Passes = {},
	Boosts = {},
	Packs = {},
	Codes = {},
}

return table.clone(Player)

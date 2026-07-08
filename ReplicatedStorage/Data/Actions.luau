local Actions = {
	Attack = {
		Attacking = false,
		Blocking = false,
		Stunned = false,
		Broke = false,
	},
	Block = {
		Attacking = false,
		Blocking = false,
		Stunned = false,
		Broke = false,
	},
	Move = {
		Attacking = false,
		Blocking = false,
		Stunned = false,
		Broke = false,
	},
}

return table.clone(Actions)

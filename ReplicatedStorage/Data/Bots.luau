local Bots = {
	Bot = {
		Health = 1000,
		Toughness = 100, -- Damage resistance
		Stability = 100, -- Stun resistance
		Speed = 10,
		BodyParts = {
			Head = { Health = 75, StunMultiplier = 2 },
			Torso = { Health = 0, StunMultiplier = 1 },
			RightArm = { Health = 100, StunMultiplier = 0 },
			LeftArm = { Health = 100, StunMultiplier = 0 },
			RightLeg = { Health = 125, StunMultiplier = 1.5 },
			LeftLeg = { Health = 125, StunMultiplier = 1.5 },
		},
		Attacks = {
			Light = {
				{ Name = "Slap", Cooldown = 4 },
				-- { Name = "Stomp", Cooldown = 4 },
			},
			--[[Medium = {
				{ Name = "Spin", Cooldown = 6 },
				{ Name = "Swing", Cooldown = 6 },
			},
			Heavy = {
				{ Name = "Throw", Cooldown = 8 },
			}, ]]
		},
	},
}

return table.clone(Bots)

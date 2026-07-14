local Bots = {
	Bot = {
		Health = 100, -- 1000
		Toughness = 100, -- Damage resistance
		Stability = 100, -- Stun resistance
		Speed = 10,
		BodyParts = {
			Head = { Health = 150, StunMultiplier = 2 },
			Torso = { Health = 500, StunMultiplier = 1 },
			RightArm = { Health = 200, StunMultiplier = 0.25 },
			LeftArm = { Health = 200, StunMultiplier = 0.25 },
			RightLeg = { Health = 200, StunMultiplier = 1.5 },
			LeftLeg = { Health = 200, StunMultiplier = 1.5 },
		},
		Attacks = {
			Light = {
				{ Name = "Slap", Cooldown = 4, AnimationId = 106270295385826 },
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

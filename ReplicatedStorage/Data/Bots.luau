--[[
--- Health is the amount of damage a bot can take before being defeated.

--- Toughness is the general damage reduction.
        - (100 is the base value, with 200 it become immortal and with 0, he dies with one hit)

--- Stability is the stun damage needed to stun the bot.
        - (100 is the base value, with 200 it becomes immune to stuns and with 0, he gets stunned with one hit)

--- Stunnable parts values are the stun damage multipliers of each part.
        - (Head = 200, Torso = 100, RightLeg = 150, LeftLeg = 150)

--- Breakable parts values are the durability of each part.
        - (Head = 75, RightArm = 100, LeftArm = 100, RightLeg = 125, LeftLeg = 125)
]]

local Bots = {
	Bot = {
		Health = 1000,
		Toughness = 100,
		Stability = 100,
		Speed = 10,
		StunnableParts = { Head = 200, Torso = 100, RightLeg = 150, LeftLeg = 150 },
		BreakableParts = { Head = 75, RightArm = 100, LeftArm = 100, RightLeg = 125, LeftLeg = 125 },
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

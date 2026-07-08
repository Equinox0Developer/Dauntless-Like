local Codes = {
	["CODE1"] = { Type = "Currency", Quantity = 1000, Expired = false },
	["CODE2"] = { Type = "Boost", Boost = "Name", Time = 1000, Expired = false },
}

return table.clone(Codes)

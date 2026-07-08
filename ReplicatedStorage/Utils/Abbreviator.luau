--// Module
local Abbreviator = {}

--// Tables
local SUFFIXES = {
	"K",  -- 10^3
	"M",  -- 10^6
	"B",  -- 10^9
	"T",  -- 10^12
	"Qa", -- 10^15
	"Qi", -- 10^18
	"Sx", -- 10^21
	"Sp", -- 10^24
	"Oc", -- 10^27
	"No", -- 10^30
	"Dc"  -- 10^33
}

--// Functions
local function truncate(num, decimals): number
	local factor = 10 ^ decimals
	return math.floor(num * factor) / factor
end

local function cleanDecimal(num): string
	local str = tostring(num)

	if str:find("%.") then
		str = str:gsub("0+$", ""):gsub("%.$", "")
	end

	return str
end

function Abbreviator.format(number): string
	if number < 1000 then
		return tostring(math.floor(number))
	end

	local tier = 0
	local short = number

	while short >= 1000 and tier < #SUFFIXES do
		short /= 1000
		tier += 1
	end

	local decimals
	if short < 2 then
		decimals = 2
	elseif short < 100 then
		decimals = 1
	else
		decimals = 0
	end

	short = truncate(short, decimals)

	return cleanDecimal(short) .. SUFFIXES[tier]
end

--// Return
return Abbreviator.format
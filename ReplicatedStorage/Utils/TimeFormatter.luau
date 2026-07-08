local TimeFormatter = {}

-- Formatos disponíveis
TimeFormatter.Format = {
	MinutesSeconds = "mm:ss",
	HoursMinutesSeconds = "hh:mm:ss",
	HoursMinutes = "hh:mm",
	DaysHours = "dd:hh",
	DaysHoursMinutes = "dd:hh:mm",
}

local function pad(n: number): string
	return string.format("%02d", math.floor(n))
end

--[[
	Formata um valor em segundos para o formato especificado.

	@param seconds  number  — total de segundos (inteiro não-negativo)
	@param format   string  — um dos valores de TimeFormatter.Format
	@return         string  — tempo formatado no padrão 00:00 ou 00:00:00

	Exemplo:
		TimeFormatter.format(3723, TimeFormatter.Format.HorasMinutosSegundos)
		-- retorna "01:02:03"
]]

function TimeFormatter.format(seconds: number, format: string): string
	assert(type(seconds) == "number", "TimeFormatter.format: 'seconds' deve ser um número")
	assert(seconds >= 0, "TimeFormatter.format: 'seconds' deve ser não-negativo")
	assert(type(format) == "string", "TimeFormatter.format: 'format' deve ser uma string")

	seconds = math.floor(seconds)

	local totalMinutes = math.floor(seconds / 60)
	local totalHours = math.floor(seconds / 3600)
	local totalDays = math.floor(seconds / 86400)

	local secs = seconds % 60
	local mins = totalMinutes % 60
	local hrs  = totalHours % 24

	if format == TimeFormatter.Format.MinutesSeconds then
		return pad(totalMinutes).. ":".. pad(secs)

	elseif format == TimeFormatter.Format.HoursMinutesSeconds then
		return pad(totalHours).. ":".. pad(mins).. ":".. pad(secs)

	elseif format == TimeFormatter.Format.HoursMinutes then
		return pad(totalHours).. ":".. pad(mins)

	elseif format == TimeFormatter.Format.DaysHours then
		return pad(totalDays).. ":".. pad(hrs)

	elseif format == TimeFormatter.Format.DaysHoursMinutes then
		return pad(totalDays).. ":".. pad(hrs).. ":".. pad(mins)

	else
		error("TimeFormatter.format: formato desconhecido '".. format.. "'")
	end
end

--[[
	Converte uma string formatada de volta para segundos.
	Funciona com qualquer formato de 2 ou 3 partes separadas por ':'.

	@param str      string  — ex: "01:02:03" ou "02:30"
	@param format   string  — o formato que foi usado para gerar a string
	@return         number  — total de segundos

	Exemplo:
		TimeFormatter.parse("01:02:03", TimeFormatter.Format.HorasMinutosSegundos)
		-- retorna 3723
]]

function TimeFormatter.parse(str: string, format: string): number
	assert(type(str) == "string", "TimeFormatter.parse: 'str' deve ser uma string")
	assert(type(format) == "string", "TimeFormatter.parse: 'format' deve ser uma string")

	local parts = {}
	
	for part in string.gmatch(str, "%d+") do
		table.insert(parts, tonumber(part))
	end

	if format == TimeFormatter.Format.MinutosSegundos then
		assert(#parts == 2, "TimeFormatter.parse: esperado 2 partes para mm:ss")
		return parts[1] * 60 + parts[2]

	elseif format == TimeFormatter.Format.HorasMinutosSegundos then
		assert(#parts == 3, "TimeFormatter.parse: esperado 3 partes para hh:mm:ss")
		return parts[1] * 3600 + parts[2] * 60 + parts[3]

	elseif format == TimeFormatter.Format.HorasMinutos then
		assert(#parts == 2, "TimeFormatter.parse: esperado 2 partes para hh:mm")
		return parts[1] * 3600 + parts[2] * 60

	elseif format == TimeFormatter.Format.DiasHoras then
		assert(#parts == 2, "TimeFormatter.parse: esperado 2 partes para dd:hh")
		return parts[1] * 86400 + parts[2] * 3600

	elseif format == TimeFormatter.Format.DiasHorasMinutos then
		assert(#parts == 3, "TimeFormatter.parse: esperado 3 partes para dd:hh:mm")
		return parts[1] * 86400 + parts[2] * 3600 + parts[3] * 60

	else
		error("TimeFormatter.parse: formato desconhecido '" .. format .. "'")
	end
end

return TimeFormatter
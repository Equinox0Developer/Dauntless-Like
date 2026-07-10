--// Module
local General = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// Folders
local systems = ReplicatedStorage:WaitForChild("Systems")

--// Systems
local poolsManager = require(systems:WaitForChild("PoolsManager"))

--// Variables
local highlightsPool = poolsManager.getPool("Highlights")
local indicatorsPool = poolsManager.getPool("Indicators")

local seed = math.random(1, 56565656)
local randomGenerator = Random.new(seed)

local anchorPoolSize = 0
local activeCount = 0

local heartbeatConnection: RBXScriptConnection? = nil

--// Tables
local activeIndicators = {}
local anchorPool = {}

--// Constants
local DAMAGE_COLORS = {
	Core = Color3.fromRGB(225, 225, 225),
	Break = Color3.fromRGB(255, 220, 0),
	Stun = Color3.fromRGB(0, 170, 255),
	Wound = Color3.fromRGB(255, 55, 65),
}

local INITIAL_UP_SPEED_MIN = 8 -- Velocidade inicial pra cima (controla o quanto ele sobe: pico = v^2 / (2 * RISE_GRAVITY)).
local INITIAL_UP_SPEED_MAX = 10 -- Velocidade inicial pra cima (controla o quanto ele sobe: pico = v^2 / (2 * RISE_GRAVITY)).

local RISE_GRAVITY = 15 -- Gravidade enquanto sobe (VelocityY > 0): menor = desacelera mais devagar = sobe mais alto/demorado.

local FALL_GRAVITY_MIN = 35 -- Gravidade enquanto cai (VelocityY <= 0): maior = acelera mais rápido = cai mais forte/rápido.
local FALL_GRAVITY_MAX = 45 -- Gravidade enquanto cai (VelocityY <= 0): maior = acelera mais rápido = cai mais forte/rápido.

local HORIZONTAL_SPREAD = 2.5 -- Espalhamento horizontal só no spawn (posição de nascimento), sem afetar o resto da animação.

local LATERAL_DRIFT_MIN = -0.75 -- Velocidade horizontal durante a animação (studs/s): controla o quanto se espalha enquanto sobe/desce.
local LATERAL_DRIFT_MAX = 0.75 -- Velocidade horizontal durante a animação (studs/s): controla o quanto se espalha enquanto sobe/desce.

local LIFETIME = 1.5 -- Tempo total de vida do indicator, em segundos.

local FADE_DELAY = 1.25 -- Quanto tempo (segundos) esperar, desde o spawn, antes de começar a sumir.
local FADE_DURATION = 0.25 -- Quanto tempo (segundos) o fade em si demora, a partir do momento que começa.

--// Functions
local function getAnchor(worldPosition: Vector3): BasePart
	local anchor: BasePart

	if anchorPoolSize > 0 then
		anchor = anchorPool[anchorPoolSize]
		anchorPool[anchorPoolSize] = nil
		anchorPoolSize -= 1
	else
		anchor = Instance.new("Part")
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.05, 0.05, 0.05)
		anchor.Parent = Workspace
	end

	anchor.CFrame = CFrame.new(worldPosition)

	return anchor
end

local function releaseAnchor(anchor: BasePart)
	anchorPoolSize += 1
	anchorPool[anchorPoolSize] = anchor
end

local function updateIndicators(deltaTime: number)
	local index = 1

	while index <= activeCount do
		local data = activeIndicators[index]
		data.Elapsed += deltaTime

		local gravity = data.VelocityY > 0 and RISE_GRAVITY or data.FallGravity
		data.VelocityY -= gravity * deltaTime

		data.Offset = Vector3.new(data.Offset.X + data.VelocityX * deltaTime, data.Offset.Y + data.VelocityY * deltaTime, data.Offset.Z + data.VelocityZ * deltaTime)
		data.Indicator.StudsOffsetWorldSpace = data.Offset

		if data.Elapsed >= FADE_DELAY then
			local fadeAlpha = math.clamp((data.Elapsed - FADE_DELAY) / FADE_DURATION, 0, 1)
			data.Label.TextTransparency = fadeAlpha

			if data.Stroke then
				data.Stroke.Transparency = fadeAlpha
			end
		end

		if data.Elapsed >= LIFETIME then
			indicatorsPool:releaseUnit(data.Indicator, 0)
			releaseAnchor(data.Anchor)

			activeIndicators[index] = activeIndicators[activeCount]
			activeIndicators[activeCount] = nil
			activeCount -= 1
		else
			index += 1
		end
	end

	if activeCount == 0 and heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

function General.indicator(bodyPart: BasePart, damageType: string, damageValue: number)
	local indicator = indicatorsPool:getUnit()
	local label = indicator.Number
	local stroke = label:FindFirstChildOfClass("UIStroke")

	local anchor = getAnchor(bodyPart.Position)

	local initialOffset =
		Vector3.new(randomGenerator:NextNumber(-HORIZONTAL_SPREAD, HORIZONTAL_SPREAD), randomGenerator:NextNumber(0, 1), randomGenerator:NextNumber(-HORIZONTAL_SPREAD, HORIZONTAL_SPREAD))

	label.Text = damageValue
	label.TextColor3 = DAMAGE_COLORS[damageType]
	label.TextTransparency = 0

	if stroke then
		stroke.Transparency = 0
	end

	indicator.Adornee = anchor
	indicator.StudsOffsetWorldSpace = initialOffset
	indicator.Parent = anchor

	activeCount += 1

	activeIndicators[activeCount] = {
		Indicator = indicator,
		Label = label,
		Stroke = stroke,
		Anchor = anchor,
		Offset = initialOffset,
		VelocityX = randomGenerator:NextNumber(LATERAL_DRIFT_MIN, LATERAL_DRIFT_MAX),
		VelocityY = randomGenerator:NextNumber(INITIAL_UP_SPEED_MIN, INITIAL_UP_SPEED_MAX),
		VelocityZ = randomGenerator:NextNumber(LATERAL_DRIFT_MIN, LATERAL_DRIFT_MAX),
		FallGravity = randomGenerator:NextNumber(FALL_GRAVITY_MIN, FALL_GRAVITY_MAX),
		Elapsed = 0,
	}

	if not heartbeatConnection then
		heartbeatConnection = RunService.Heartbeat:Connect(updateIndicators)
	end
end

function General.highlight(bodyPart: BasePart)
	local highlight = highlightsPool:getUnit()
	highlight.Adornee = bodyPart
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = bodyPart

	highlightsPool:releaseUnit(highlight, 0.25)
end

--// Return
return General

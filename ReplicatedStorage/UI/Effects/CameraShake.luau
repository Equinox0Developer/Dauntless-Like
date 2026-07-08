--// Module
local CameraShake = {}

--// Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--// Variables
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local random = Random.new()

local activeShakes = {}
local connection

local currentShakeCFrame = CFrame.identity

--// Types
type ShakeSettings = {
	Duration: number, --> Duração do tremor em segundos
	Magnitude: number, --> Intensidade do tremor, o quanto a câmera se move
	Roughness: number, --> Velocidade do tremor, o quão rápido a câmera se move
	FadeIn: number, --> Tempo para atingir a força máxima
	FadeOut: number, --> Tempo de enfraquecimento, quanto menor, mais brusco
	PositionInfluence: Vector3, --> Quanto a câmera se move em cada eixo
	RotationInfluence: Vector3, --> Quanto a câmera se rotacionada em cada eixo ao redor do centro
}

--// Tables
CameraShake.Presets = {
	[1] = {
		Duration = 0.15,
		Magnitude = 0.5,
		Roughness = 7.5,
		FadeIn = 0.015,
		FadeOut = 0.15,
		PositionInfluence = Vector3.new(0.05, 0.05, 0.05),
		RotationInfluence = Vector3.new(0.25, 0.25, 0.25),
	},
	[2] = {
		Duration = 0.25,
		Magnitude = 1,
		Roughness = 10,
		FadeIn = 0.025,
		FadeOut = 0.225,
		PositionInfluence = Vector3.new(0.1, 0.1, 0.1),
		RotationInfluence = Vector3.new(0.5, 0.5, 0.5),
	},
	[3] = {
		Duration = 0.5,
		Magnitude = 1.5,
		Roughness = 12.5,
		FadeIn = 0.035,
		FadeOut = 0.35,
		PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
		RotationInfluence = Vector3.new(1, 1, 1),
	},
	[4] = {
		Duration = 0.75,
		Magnitude = 2,
		Roughness = 15,
		FadeIn = 0.045,
		FadeOut = 0.45,
		PositionInfluence = Vector3.new(0.2, 0.2, 0.2),
		RotationInfluence = Vector3.new(1.5, 1.5, 1.5),
	},
	Handheld = {
		Duration = 999,
		Magnitude = 0.15,
		Roughness = 2,
		FadeIn = 1,
		FadeOut = 1,
		PositionInfluence = Vector3.new(0.03, 0.03, 0.03),
		RotationInfluence = Vector3.new(0.15, 0.15, 0.15),
	},
}

--// Functions
local function getShakeOffset(shake: ShakeSettings, deltaTime: number, multiplier: number)
	shake.Time += deltaTime

	local fade = 1

	if shake.Time < shake.FadeIn then
		fade = shake.Time / shake.FadeIn
	elseif shake.Time > (shake.Duration - shake.FadeOut) then
		fade = math.clamp(
			(shake.Duration - shake.Time) / shake.FadeOut,
			0,
			1
		)
	end

	local magnitude = (shake.Magnitude * fade) * multiplier

	local offsetX = random:NextNumber(-1, 1) * magnitude
	local offsetY = random:NextNumber(-1, 1) * magnitude
	local offsetZ = random:NextNumber(-1, 1) * magnitude

	local rotationX = math.rad(random:NextNumber(-1, 1) * magnitude * 2)
	local rotationY = math.rad(random:NextNumber(-1, 1) * magnitude * 2)
	local rotationZ = math.rad(random:NextNumber(-1, 1) * magnitude * 2)

	local positionOffset = Vector3.new(
		offsetX * shake.PositionInfluence.X,
		offsetY * shake.PositionInfluence.Y,
		offsetZ * shake.PositionInfluence.Z
	)

	local rotationOffset = Vector3.new(
		rotationX * shake.RotationInfluence.X,
		rotationY * shake.RotationInfluence.Y,
		rotationZ * shake.RotationInfluence.Z
	)

	return positionOffset, rotationOffset
end

local function update(deltaTime: number, multiplier: number)
	camera = workspace.CurrentCamera

	camera.CFrame *= currentShakeCFrame:Inverse()

	local positionOffset = Vector3.zero
	local rotationOffset = Vector3.zero

	for i = #activeShakes, 1, -1 do
		local shake = activeShakes[i]

		if shake.Time >= shake.Duration then
			table.remove(activeShakes, i)

			continue
		end

		local shakePosition, shakeRotation = getShakeOffset(shake, deltaTime, multiplier)

		positionOffset += shakePosition
		rotationOffset += shakeRotation
	end

	currentShakeCFrame = CFrame.new(positionOffset)
		* CFrame.Angles(
			rotationOffset.X,
			rotationOffset.Y,
			rotationOffset.Z
		)

	camera.CFrame *= currentShakeCFrame

	if #activeShakes == 0 then
		camera.CFrame *= currentShakeCFrame:Inverse()

		currentShakeCFrame = CFrame.identity

		RunService:UnbindFromRenderStep("CameraShake")

		connection = nil
	end
end

local function start(multiplier)
	if connection then
		return
	end

	RunService:BindToRenderStep(
		"CameraShake",
		Enum.RenderPriority.Camera.Value + 1,
		function(deltaTime: number)
			update(deltaTime, multiplier)
		end
	)

	connection = true
end

function CameraShake.stop()
	camera = workspace.CurrentCamera

	camera.CFrame *= currentShakeCFrame:Inverse()

	currentShakeCFrame = CFrame.identity

	table.clear(activeShakes)

	if connection then
		RunService:UnbindFromRenderStep("CameraShake")

		connection = nil
	end
end

function CameraShake.shake(
	duration: number,
	magnitude: number,
	roughness: number?,
	fadeIn: number?,
	fadeOut: number?,
	positionInfluence: Vector3?,
	rotationInfluence: Vector3?,
	multiplier: number
)
	
	start(multiplier)

	table.insert(activeShakes, {
		Time = 0,
		Duration = duration,
		Magnitude = magnitude,
		Roughness = roughness or 10,
		FadeIn = fadeIn or 0,
		FadeOut = fadeOut or duration,
		PositionInfluence = positionInfluence or Vector3.new(0.15, 0.15, 0.15),
		RotationInfluence = rotationInfluence or Vector3.new(1, 1, 1),
	})
end

function CameraShake.shakePreset(presetName: string, multiplier: number?)
	local preset = CameraShake.Presets[presetName]

	if not preset then
		warn(`Preset "{presetName}" não existe!`)

		return
	end

	CameraShake.shake(
		preset.Duration,
		preset.Magnitude,
		preset.Roughness,
		preset.FadeIn,
		preset.FadeOut,
		preset.PositionInfluence,
		preset.RotationInfluence,
		multiplier or 1
	)
end

function CameraShake.shakeAtPosition(
	position: Vector3,
	maxDistance: number,
	duration: number,
	magnitude: number,
	roughness: number?
)
	local character = player.Character

	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not rootPart then
		return
	end

	local distance = (rootPart.Position - position).Magnitude

	if distance > maxDistance then
		return
	end

	local multiplier = 1 - (distance / maxDistance)

	CameraShake.shake(
		duration,
		magnitude * multiplier,
		roughness
	)
end

function CameraShake.tweenFov(
	fov: number,
	duration: number,
	easingStyle: Enum.EasingStyle?,
	easingDirection: Enum.EasingDirection?
)
	camera = workspace.CurrentCamera

	local tween = TweenService:Create(
		camera,
		TweenInfo.new(
			duration,
			easingStyle or Enum.EasingStyle.Sine,
			easingDirection or Enum.EasingDirection.Out
		),
		{
			FieldOfView = fov
		}
	)

	tween:Play()

	return tween
end

--// Return
return CameraShake
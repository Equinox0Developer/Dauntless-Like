local Types = {}

export type Parameters = {
	CFrame: CFrame?,
	Size: number | Vector3,
	VelocityPrediction: boolean?,
	PredictionTime: number?,
	WillDebug: boolean?,
}

export type Hitbox = {
	Active: boolean?,
	CFrame: CFrame?,
	Results: {}?,
}

return Types

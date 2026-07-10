local Types = {}

export type Pool = {
	name: string,
	minCapacity: number,
	maxCapacity: number,
	createFunction: () -> Instance | Model,
	resetFunction: (Instance) -> any,
	folder: Instance,
	inStock: { Instance | Model },
	inUse: { Instance | Model },
}

return Types

extends Node

enum Stage {
	TOWNIE,
	CULTIST,
	FANATIC,
	DESERTER,
}

enum Job {
	LIVE_DULL_LIFE,
	DEFEND,
	PRAY,
}

var citizens: Array[Citizen] = []

func get_stage(stage: Stage):
	return citizens.filter(func(citizen): return citizen.stage == stage)

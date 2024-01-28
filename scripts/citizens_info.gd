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
	FLEE,
}

var citizens = []
var goons = []

func get_stage(stage: Stage):
	return citizens.filter(func(citizen): return citizen.stage == stage)

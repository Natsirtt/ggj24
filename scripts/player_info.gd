extends Node

@export var player: Player
var favour: int = 0

func get_current_favour():
	return favour

func can_afford(cost: int):
	assert(cost >= 0)
	return cost <= get_current_favour()

func pay(cost: int):
	assert(cost >= 0)
	assert(can_afford(cost))
	favour -= cost

func generate_favour(extra: int):
	assert(extra > 0)
	favour += extra

extends Node

@export var player: Player
var favour: int = 2

signal favour_generated(amount: int)
signal favour_consumed(amount: int)

func get_current_favour():
	return favour

func can_afford(cost: int):
	assert(cost >= 0)
	return cost <= get_current_favour()

func pay(cost: int):
	assert(cost >= 0)
	assert(can_afford(cost))
	favour -= cost
	favour_consumed.emit(cost)
	print("Favour is now " + str(favour))

func generate_favour(extra: int):
	assert(extra > 0)
	favour += extra
	favour_generated.emit(extra)
	print("Favour is now " + str(favour))

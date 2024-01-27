class_name Ship extends Node3D

var free_praying_spots: Array[Node3D] = []
var reserved_praying_spots: Array[Node3D] = []

func _ready():
	world_info.ship = self
	for spot in $"Praying Spots Root".get_children():
		free_praying_spots.append(spot as Node3D)
	assert(not free_praying_spots.any(func(x): return x == null))

func has_free_praying_spot():
	return free_praying_spots.size() > 0

func reserve_praying_spot():
	assert(has_free_praying_spot())
	reserved_praying_spots.append(free_praying_spots.pick_random())
	free_praying_spots.erase(reserved_praying_spots[-1])
	print("Reserved spot " + str(reserved_praying_spots[-1]))
	return reserved_praying_spots[-1]

func return_praying_spot(spot: Node3D):
	assert(reserved_praying_spots.has(spot))
	free_praying_spots.append(spot)
	reserved_praying_spots.erase(spot)
	print("Returned spot " + str(spot))

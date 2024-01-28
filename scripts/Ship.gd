class_name Ship extends Node3D

var free_praying_spots: Array[Node3D] = []
var reserved_praying_spots: Array[Node3D] = []
var lamps: Array[Node3D] = []
var fuel = 0

signal fuel_changed(fuel: int)

func _ready():
	lamps.append($Lamps/Lamp_01)
	lamps.append($Lamps/Lamp_02)
	lamps.append($Lamps/Lamp_03)
	for l in lamps:
		l.hide()
	
	fuel_changed.connect(func(f):
		var number_of_lit_lamps = floori(f * 3 / player_info.fuel_win_amount)
		for i in range(3):
			if i < number_of_lit_lamps:
				lamps[i].show()
			else:
				lamps[i].hide()
	)
	
	world_info.ship = self
	for spot in $"Praying Spots Root".get_children():
		free_praying_spots.append(spot as Node3D)
	assert(not free_praying_spots.any(func(x): return x == null))
	$Interactable.interacted.connect(_on_interact)

func _process(_delta):
	$Interactable.can_interact = citizens_info.get_stage(citizens_info.Stage.CULTIST).size() > 0

func _on_interact(_interactor):
	var chosen_one = citizens_info.get_stage(citizens_info.Stage.CULTIST).pick_random()
	chosen_one.change_stage(citizens_info.Stage.FANATIC)
	chosen_one.change_job(citizens_info.Job.LIVE_DULL_LIFE)

func refuel(extra_fuel: int):
	assert(extra_fuel > 0)
	fuel += extra_fuel
	fuel_changed.emit(fuel)
	if fuel == player_info.fuel_win_amount:
		player_info.player.end_game(true)

func consume_fuel(removed_fuel: int):
	print("consuming " + str(removed_fuel) + " fuel")
	assert(removed_fuel > 0)
	if fuel == 0:
		player_info.player.end_game(false)
		return
	fuel = max(fuel - removed_fuel, 0)
	fuel_changed.emit(fuel)

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

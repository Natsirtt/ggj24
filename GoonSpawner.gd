extends Node3D

@export var initial_wait = 30
@export var seconds_between_spawns = 10
@export var random_timing_seconds = 2.0
@export var scene_to_spawn: PackedScene = null

@onready var timer: Timer = $Timer

func _ready():
	if scene_to_spawn == null:
		push_error("You must provide a scene to spawn to spawner " + str(self))
		return
	(func():
		timer.timeout.connect(_spawn)
		timer.start(initial_wait + randf_range(-random_timing_seconds / 2.0, random_timing_seconds / 2.0))
	).call_deferred()  # allow other _ready functions to change the spawners timings

func _spawn():
	if player_info.player.game_has_ended:
		timer.paused = true
		return
		
	print("Spawning a " + str(scene_to_spawn))
	var scene := scene_to_spawn.instantiate() as Node3D
	add_child(scene)
	timer.one_shot = false
	timer.start(seconds_between_spawns + randf_range(-random_timing_seconds / 2.0, random_timing_seconds / 2.0))

extends Node3D

@export var enable_spawning = true
@export var initial_wait = 30
@export var seconds_between_spawns = 10
@export var random_timing_seconds = 2.0
@onready var spawner = $Spawner

func _ready():
	spawner.initial_wait = initial_wait if enable_spawning else 9999999
	spawner.seconds_between_spawns = seconds_between_spawns
	spawner.random_timing_seconds = random_timing_seconds

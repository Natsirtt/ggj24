extends CharacterBody3D

class Target:
	enum Mode { OBJECT, POSITION }
	var mode: Mode
	var target: Variant
	
	func _init(target_or_position: Variant):
		assert(target_or_position is Node3D or target_or_position is Vector3)
		target = target_or_position
		mode = Mode.OBJECT if target is Node3D else Mode.POSITION
	
	func get_position():
		if mode == Mode.OBJECT:
			return (target as Node3D).global_position
		return target as Vector3

var _target: Target = null

var _speed = 1.0
@onready var timer: Timer = $Timer
@onready var navigation: NavigationAgent3D = $NavigationAgent3D
var stage: citizens_info.Stage = citizens_info.Stage.DULL
var job: citizens_info.Job = citizens_info.Job.LIVE_DULL_LIFE

signal character_moved(velocity)
signal stage_changed(stage: citizens_info.Stage)

enum JobState {
	ENTER,
	PROCESS,
	EXIT,
}

var state_machine = {
	citizens_info.Job.LIVE_DULL_LIFE: {
		JobState.ENTER: func():
			pass,
		JobState.PROCESS: func(delta):
			# In dull life mode, citizens roam aimlessly. So we make them pick
			# a target position within 50 meters to slowly go to, and then wait a
			# random amount of time before doing it again.
			_speed = 1.0
			_roam(),
		JobState.EXIT: func():
			_target = null,
	},
	citizens_info.Job.PRAY: {
		JobState.ENTER: func():
			_speed = 3.0
			var ship = world_info.ship
			assert(ship.has_free_praying_spot())
			_target = Target.new(ship.reserve_praying_spot()),
		JobState.PROCESS: func(delta):
			pass,
		JobState.EXIT: func():
			_target = null,
	},
	citizens_info.Job.DEFEND: {
		JobState.ENTER: func():
			pass,
		JobState.PROCESS: func(delta):
			pass,
		JobState.EXIT: func():
			pass,
	}
}

func _roam():
	# this is still biased to closer positions, but I can't be bothered right now
	var random_direction = maths.random_inside_unit_circle()
	var random_distance = randf_range(5.0, 50.0)
	_target = Target.new(Vector3(random_direction.x * random_distance, global_position.y, random_direction.y * random_distance))

func _get_job_func(state: JobState):
	return state_machine[job][state]

func change_job(new_job: citizens_info.Job):
	_get_job_func(JobState.EXIT).call()
	job = new_job
	_get_job_func(JobState.ENTER).call()

func _ready():
	_get_job_func(JobState.ENTER).call()

func _process(delta):
	_get_job_func(JobState.PROCESS).call(delta)

func _physics_process(_delta):
	velocity.x = move_toward(velocity.x, 0, _speed)
	velocity.z = move_toward(velocity.z, 0, _speed)
	if _target != null:
		navigation.target_position = _target.get_position()
		await get_tree().physics_frame
		
		var direction = (navigation.get_next_path_position() - global_position).normalized()
		if direction.length() > 0.01 and not navigation.is_target_reached():
			velocity.x = direction.x * _speed
			velocity.z = direction.z * _speed
			character_moved.emit(velocity)
		
	move_and_slide()

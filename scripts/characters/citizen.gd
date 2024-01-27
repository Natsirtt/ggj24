extends CharacterBody3D

@export var min_dull_life_idle_time = 5.0
@export var max_dull_life_ilde_time = 20.0
@export var min_dull_life_roam_distance = 5.0
@export var max_dull_life_roam_distance = 15.0
@export var favour_generated_per_prayer = 1
@export var seconds_between_favour_generation = 5

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
var _reserved_spot: Node3D = null

var _speed = 0.0
@onready var timer: Timer = $Timer
@onready var navigation: NavigationAgent3D = $NavigationAgent3D
var stage: citizens_info.Stage = citizens_info.Stage.TOWNIE
var job: citizens_info.Job = citizens_info.Job.LIVE_DULL_LIFE

signal character_moved(velocity)
signal character_stopped
signal stage_changed(stage: citizens_info.Stage)
signal job_changed(job: citizens_info.Job)

enum JobState {
	ENTER,
	PROCESS,
	EXIT,
}

var state_machine = {
	citizens_info.Job.LIVE_DULL_LIFE: {
		JobState.ENTER: func():
			print("Entering dull life")
			# In dull life mode, citizens roam aimlessly. So we make them pick
			# a target position within 50 meters to slowly go to, and then wait a
			# random amount of time before doing it again.
			_speed = 1.0
			timer.process_callback = Timer.TIMER_PROCESS_IDLE
			timer.start(randf_range(min_dull_life_idle_time, max_dull_life_ilde_time))
			timer.timeout.connect(func():
				_roam()
				timer.wait_time = randf_range(min_dull_life_idle_time, max_dull_life_ilde_time)
			),
		JobState.PROCESS: func(delta):
			pass,
		JobState.EXIT: func():
			print("Exiting dull life")
			_disconnect_all_timer_listeners()
			timer.stop()
			_target = null,
	},
	citizens_info.Job.PRAY: {
		JobState.ENTER: func():
			print("Entering pray job")
			_speed = 3.0
			var ship = world_info.ship
			assert(ship.has_free_praying_spot())
			_reserved_spot = ship.reserve_praying_spot()
			_target = Target.new(_reserved_spot)
			navigation.target_reached.connect(func():
				print("Reached praying spot")
				_target = null
				timer.timeout.connect(_pray)
				timer.start(seconds_between_favour_generation), CONNECT_ONE_SHOT
			),
		JobState.PROCESS: func(delta):
			pass,
		JobState.EXIT: func():
			print("Exiting pray job")
			_disconnect_all_timer_listeners()
			timer.stop()
			world_info.ship.return_praying_spot(_reserved_spot)
			_target = null,
	},
	citizens_info.Job.DEFEND: {
		JobState.ENTER: func():
			print("Entering defense militia")
			pass,
		JobState.PROCESS: func(delta):
			pass,
		JobState.EXIT: func():
			print("Exiting defense militia")
			pass,
	}
}

func _disconnect_all_timer_listeners():
	for connection in timer.timeout.get_connections():
		timer.timeout.disconnect(connection["callable"])

func _roam():
	print("Starting new roam")
	# this is still biased to closer positions, but I can't be bothered right now
	var random_direction = maths.random_inside_unit_circle()
	var random_distance = randf_range(min_dull_life_roam_distance, max_dull_life_roam_distance)
	_target = Target.new(Vector3(random_direction.x * random_distance, global_position.y, random_direction.y * random_distance))

func _pray():
	player_info.generate_favour(favour_generated_per_prayer)

func _get_job_func(state: JobState):
	return state_machine[job][state]

func change_job(new_job: citizens_info.Job):
	_get_job_func(JobState.EXIT).call()
	job = new_job
	_get_job_func(JobState.ENTER).call()
	job_changed.emit(job)
	print(str(self) + "'s job is now " + str(job))

func _ready():
	_get_job_func(JobState.ENTER).call()
	change_job(citizens_info.Job.PRAY)

func _process(delta):
	_get_job_func(JobState.PROCESS).call(delta)

func _physics_process(_delta):
	var was_stopped = velocity.is_zero_approx()
	var is_stopped = true
	velocity.x = move_toward(velocity.x, 0, _speed)
	velocity.z = move_toward(velocity.z, 0, _speed)
	if _target != null:
		navigation.target_position = _target.get_position()
		await get_tree().physics_frame
		
		var direction = (navigation.get_next_path_position() - global_position).normalized()
		if direction.length() > 0.01 and not navigation.is_target_reached():
			velocity.x = direction.x * _speed
			velocity.z = direction.z * _speed
			is_stopped = false
			character_moved.emit(velocity)
	if not was_stopped and is_stopped:
		character_stopped.emit()
		
	move_and_slide()

class_name Citizen extends CharacterBody3D

@export var min_dull_life_idle_time = 5.0
@export var max_dull_life_ilde_time = 20.0
@export var min_dull_life_roam_distance = 5.0
@export var max_dull_life_roam_distance = 15.0
@export var favour_generated_per_prayer = 1
@export var seconds_between_favour_generation = 10
@export var seconds_between_defender_salary = 3

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
var is_targetted_by_goon = false

var _speed = 0.0
@onready var timer: Timer = $Timer
@onready var navigation: NavigationAgent3D = $NavigationAgent3D
@onready var interactable: Interactable = $Interactable
@onready var animation_handler: AnimationHandler = $AnimationHandler
var stage: citizens_info.Stage = citizens_info.Stage.TOWNIE
var job: citizens_info.Job = citizens_info.Job.LIVE_DULL_LIFE

signal character_moved(velocity)
signal character_stopped
signal character_interacted
signal character_stage_changed(stage: citizens_info.Stage)
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
			timer.one_shot = false
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
			_disconnect_all_listeners()
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
				# somehow _pray is already connected sometimes?
				_disconnect_all_listeners()
				timer.timeout.connect(_pray)
				timer.one_shot = false
				timer.start(seconds_between_favour_generation), CONNECT_ONE_SHOT
			),
		JobState.PROCESS: func(delta):
			pass,
		JobState.EXIT: func():
			print("Exiting pray job")
			_disconnect_all_listeners()
			timer.stop()
			world_info.ship.return_praying_spot(_reserved_spot)
			_target = null,
	},
	citizens_info.Job.DEFEND: {
		JobState.ENTER: func():
			print("Entering defense militia")
			_speed = 5.0
			animation_handler.color_tint = Color.LIGHT_CORAL
			timer.one_shot = false
			timer.timeout.connect(func():
				print("It's payday!")
				if not player_info.can_afford(1):
					print("You can't pay me? I'm done!")
					change_stage(citizens_info.Stage.DESERTER)
					change_job(citizens_info.Job.FLEE)
					return
				player_info.pay(1)
			)
			timer.start(seconds_between_defender_salary),
		JobState.PROCESS: func(delta):
			if _target == null:
				var candidate_goons = citizens_info.goons.filter(func(goon): return not goon.is_targeted_by_defender)
				if candidate_goons.size() > 0:
					var new_target = candidate_goons.pick_random()
					new_target.is_targeted_by_defender = true
					navigation.target_reached.connect(func():
						new_target.leave_and_never_return()
						character_interacted.emit("attack")
						_target = null, CONNECT_ONE_SHOT)
					_target = Target.new(new_target),
		JobState.EXIT: func():
			print("Exiting defense militia")
			_disconnect_all_listeners(),
	},
	citizens_info.Job.FLEE: {
		JobState.ENTER: func():
			print("Getting the hell outta here")
			var direction = maths.random_inside_unit_circle()
			# Just going to a bonkers distance
			_target = Target.new(Vector3(direction.x * 100000, global_position.y, direction.y * 100000)),
		JobState.PROCESS: func(delta):
			pass,
		JobState.EXIT: func():
			print("Stopped fleeing")
			_disconnect_all_listeners(),
	},
}

func _disconnect_all_listeners():
	for connection in timer.timeout.get_connections():
		if timer.timeout.is_null():
			break
		timer.timeout.disconnect(connection["callable"])
	for connection in navigation.target_reached.get_connections():
		if navigation.target_reached.is_null():
			break
		navigation.target_reached.disconnect(connection["callable"])

func _roam():
	print("Starting new roam")
	# this is still biased to closer positions, but I can't be bothered right now
	var random_direction = maths.random_inside_unit_circle()
	var random_distance = randf_range(min_dull_life_roam_distance, max_dull_life_roam_distance)
	_target = Target.new(Vector3(random_direction.x * random_distance, global_position.y, random_direction.y * random_distance))

func _pray():
	player_info.generate_favour(favour_generated_per_prayer)
	character_interacted.emit("pray")

func _get_job_func(state: JobState):
	return state_machine[job][state]

func change_job(new_job: citizens_info.Job):
	assert(new_job != job or job == citizens_info.Job.LIVE_DULL_LIFE)
	_get_job_func(JobState.EXIT).call()
	animation_handler.color_tint = Color.WHITE
	job = new_job
	_get_job_func(JobState.ENTER).call()
	job_changed.emit(job)
	print(str(self) + "'s job is now " + str(job))

func change_stage(new_stage: citizens_info.Stage):
	if new_stage == citizens_info.Stage.CULTIST:
		animation_handler.skin = "Cultist"
		interactable.context_for_player = "cultist"
		interactable.cost = 0
		_speed = 3.0
		$Interactable/InteractionIndicatorActionProxy.show()
		$Interactable/InteractionIndicatorFavourProxy.hide()
	elif new_stage == citizens_info.Stage.FANATIC:
		animation_handler.skin = "Fanatic"
		interactable.context_for_player = "fanatic"
		interactable.can_interact = false
		_speed = 5.0
		world_info.ship.refuel(1)
	elif new_stage == citizens_info.Stage.TOWNIE:
		animation_handler.skin = "Townie"
		interactable.context_for_player = "townie"
		$Interactable/InteractionIndicatorActionProxy.hide()
		$Interactable/InteractionIndicatorFavourProxy.show()
		interactable.cost = 1
		_speed = 1.0
	elif new_stage == citizens_info.Stage.DESERTER:
		animation_handler.skin = "Deserter"
		interactable.context_for_player = "deserter"
		interactable.can_interact = false
		_speed = 4.0
	stage = new_stage
	character_stage_changed.emit(stage)
	print(str(self) + " changed to stage " + str(stage))

func _ready():
	change_stage(citizens_info.Stage.TOWNIE)
	change_job(citizens_info.Job.LIVE_DULL_LIFE)
	interactable.interacted.connect(_on_interact)
	citizens_info.citizens.append(self)

func _process(delta):
	_get_job_func(JobState.PROCESS).call(delta)

func _on_interact(interactor):
	assert(stage == citizens_info.Stage.TOWNIE or stage == citizens_info.Stage.CULTIST)
	if stage == citizens_info.Stage.TOWNIE:
		change_stage(citizens_info.Stage.CULTIST)
		change_job(citizens_info.Job.PRAY)
	elif stage == citizens_info.Stage.CULTIST:
		if job == citizens_info.Job.PRAY:
			change_job(citizens_info.Job.DEFEND)
		else:
			change_job(citizens_info.Job.PRAY)

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

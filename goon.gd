class_name Goon extends CharacterBody3D

const SPEED = 5.0

signal character_moved(velocity)
signal character_stopped
signal character_interacted
# HACK unused here, necessary for animation handler
signal character_stage_changed(stage: citizens_info.Stage)

@onready var navigation: NavigationAgent3D = $NavigationAgent3D
@onready var timer: Timer = $Timer
@onready var interactable: Interactable = $Interactable
var _target : Node3D

func _ready():
	player_info.player.game_ended.connect(func(won: bool): scare_off(), CONNECT_ONE_SHOT)
	navigation.target_reached.connect(_reached_target, CONNECT_ONE_SHOT)
	interactable.interacted.connect(func(interactor): scare_off(), CONNECT_ONE_SHOT)
	var candidate_targets = citizens_info.get_stage(citizens_info.Stage.CULTIST).filter(func(citizen): return not citizen.is_targetted_by_goon)
	if candidate_targets.size() == 0:
		_target = world_info.ship
		print("Set target to ship @" + str(_target.global_position))
		return
	
	_target = candidate_targets.pick_random()
	_target.is_targetted_by_goon = true

func _reached_target():
	print(str(self) + " reached target " + str(_target))
	var as_citizen := _target as Citizen
	if as_citizen != null:
		_target = null
		as_citizen.change_stage(citizens_info.Stage.DESERTER)
		as_citizen.change_job(citizens_info.Job.FLEE)
		character_interacted.emit("save")
		timer.one_shot = true
		timer.timeout.connect(leave_and_never_return, CONNECT_ONE_SHOT)
		timer.start(1)
		return
	
	var as_ship := _target as Ship
	assert(as_ship != null)
	_target = null
	timer.one_shot = false
	timer.timeout.connect(func():
		character_interacted.emit("attack")
		world_info.ship.consume_fuel(1)
	)
	timer.start(3.0)

func leave_and_never_return():
	print("Goon leaving never to return")
	var direction = maths.random_inside_unit_circle()
	var proxy_target = Node3D.new()
	add_child(proxy_target)
	proxy_target.global_position = Vector3(direction.x * 100000, global_position.y, direction.y * 100000)
	_target = proxy_target

func scare_off():
	timer.paused = true
	leave_and_never_return()

func _physics_process(delta):
	var was_stopped = velocity.is_zero_approx()
	var is_stopped = true
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)
	if _target != null:
		navigation.target_position = _target.global_position
		await get_tree().physics_frame
		
		var direction = (navigation.get_next_path_position() - global_position).normalized()
		if direction.length() > 0.01 and not navigation.is_target_reached():
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			is_stopped = false
			character_moved.emit(velocity)
	if not was_stopped and is_stopped:
		character_stopped.emit()
		
	move_and_slide()

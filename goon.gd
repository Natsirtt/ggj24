class_name Goon extends CharacterBody3D

const SPEED = 5.0

signal character_moved(velocity)
signal character_stopped
signal character_interacted
# HACK unused here, necessary for animation handler
signal character_stage_changed(stage: citizens_info.Stage)

@onready var navigation: NavigationAgent3D = $NavigationAgent3D
var _target : Node3D

func _ready():
	pass

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

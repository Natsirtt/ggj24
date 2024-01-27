extends CharacterBody3D

const SPEED = 3.0
@onready var navigation: NavigationAgent3D = $NavigationAgent3D

signal character_moved(velocity)

func _ready():
	pass

func _physics_process(_delta):
	navigation.target_position = player_info.player.global_position
	await get_tree().physics_frame
		
	var direction = (navigation.get_next_path_position() - global_position).normalized()
	if direction.length() > 0.01 and not navigation.is_target_reached():
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	character_moved.emit(velocity)
	move_and_slide()

extends CharacterBody3D

@onready var animation_handler = $Animation
@onready var interaction_area = $InteractionZone
var _interactables_in_range = []

signal character_moved(velocity)

const SPEED = 5.0

func _ready():
	interaction_area.connect("area_entered", _on_interaction_area_entered)

func _process(_delta):
	if Input.is_action_pressed("quit"):
		get_tree().quit(0)
	
	if Input.is_action_just_pressed("interact") and _interactables_in_range.size() > 0:
		_interactables_in_range[0].interact(self)


func _physics_process(_delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	character_moved.emit(velocity)

	move_and_slide()

func _on_interaction_area_entered(body):
	if body is Interactable:
		_interactables_in_range.append(body)
		_interactables_in_range.sort_custom(func(a, b): return self.global_position.distance_squared_to(a.global_position) < self.global_position.distance_squared_to(b.global_position))

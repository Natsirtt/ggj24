class_name Player extends CharacterBody3D

@onready var animation_handler: AnimationHandler = $Animation
@onready var interaction_area = $InteractionZone
var _interactables_in_range: Array[Interactable] = []
var closest_interactable: Interactable = null

var game_has_ended := false
signal game_ended(won: bool)
signal character_moved(velocity)
signal character_stopped
signal character_interacted
# HACK! We want the AnimationHandler to work seamlessly with Player and Citizen and Goon;
# overall 
signal character_stage_changed(stage: citizens_info.Stage)

const SPEED = 5.0

func _ready():
	interaction_area.connect("area_entered", _on_interaction_area_entered)
	interaction_area.connect("area_exited", _on_interaction_area_exited)
	player_info.player = self

func _compute_closest_interactable():
	if _interactables_in_range.size() == 0:
		closest_interactable = null
		return
		
	_interactables_in_range.sort_custom(func(a, b): return self.global_position.distance_squared_to(a.global_position) < self.global_position.distance_squared_to(b.global_position))
	var new_closest := _interactables_in_range[0]
	if closest_interactable != new_closest:
		if closest_interactable != null:
			closest_interactable.unready_interact(self)
		new_closest.ready_interact(self)
		closest_interactable = new_closest

func _process(_delta):
	if Input.is_action_pressed("quit"):
		get_tree().quit(0)
	
	if game_has_ended:
		return
	
	if Input.is_action_just_pressed("interact") and _interactables_in_range.size() > 0:
		var interactable = _interactables_in_range[0]
		if player_info.can_afford(interactable.cost):
			player_info.pay(interactable.cost)
			interactable.interact(self)
			print("Player interacted")
			character_interacted.emit(interactable.context_for_player)
	
	_compute_closest_interactable()

func _physics_process(_delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		character_moved.emit(velocity)
	else:
		if not velocity.is_zero_approx():
			character_stopped.emit()
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _on_interaction_area_entered(body):
	var interactable := body as Interactable
	if interactable == null or not interactable.can_interact:
		return
		
	_interactables_in_range.append(interactable)

func _on_interaction_area_exited(body):
	var interactable = body as Interactable
	if interactable == null:
		return
	
	if interactable == closest_interactable:
		interactable.unready_interact(self)
		closest_interactable = null
		
	_interactables_in_range.erase(interactable)

func end_game(won: bool):
	if not game_has_ended:
		game_ended.emit(won)
		game_has_ended = true

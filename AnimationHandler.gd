extends Node3D

@onready var _animated_sprite = $Body/DeerBody
@onready var _sprite_direction = $Body/DeerBody/SpriteDirection
@onready var isLeft = true
@onready var is_interacting = false
@export var character_node: Node3D

func play_interact_anim(is_interacting):
		self.is_interacting = is_interacting
	

func update_velocity(velocity):
	if is_interacting:
		_animated_sprite.play("TellJoke")
		
	elif velocity.length() > 0.1:
		_animated_sprite.play("default")
		if velocity.x < -0.1 :
			if isLeft:
				pass
			else :
				_sprite_direction.play("MoveLeft")
				isLeft = true
			
			
		elif velocity.x > 0.1:
			if !isLeft:
				pass
			else :
				_sprite_direction.play("MoveRight")
				isLeft = false
			
			
	else:
		_animated_sprite.play("Idle")

# Called when the node enters the scene tree for the first time.
func _ready():
	character_node.connect("character_moved", update_velocity)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("interact"):
		play_interact_anim(true)
	else: 
		play_interact_anim(false)
	


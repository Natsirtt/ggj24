class_name AnimationHandler extends Node3D

@onready var _animated_sprite = $Body/DeerBody
@onready var _sprite_direction = $Body/DeerBody/SpriteDirection
var isLeft = true
var is_interacting = false
@export var character_node: Node3D


func update_velocity(velocity):
	if is_interacting:
		return
		
	if velocity.length() > 0.1:
		_animated_sprite.play("Player_Walk")
		if velocity.x > 0.1 :
			if isLeft:
				pass
			else :
				_sprite_direction.play("MoveLeft")
				isLeft = true
			
			
		elif velocity.x < - 0.1:
			if !isLeft:
				pass
			else :
				_sprite_direction.play("MoveRight")
				isLeft = false
	else:
		_animated_sprite.play("Player_Idle")

# Called when the node enters the scene tree for the first time.
func _ready():
	character_node.connect("character_moved", update_velocity)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("interact"):
		_playAnimWithInto("Player_Joke")
		self.is_interacting = true
	elif Input.is_action_just_released("interact"): 
		self.is_interacting = false
		
	

func _playAnimWithInto(AnimName):
	_animated_sprite.play(AnimName + "_Into")
	_animated_sprite.animation_finished.connect(func():	_animated_sprite.play(AnimName + "_Idle"), CONNECT_ONE_SHOT)
	
	
	pass

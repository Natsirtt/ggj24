extends Node3D
@onready var _animated_sprite = $Body/DeerBody
@onready var _sprite_direction = $Body/DeerBody/SpriteDirection
@onready var isLeft = true
@export var character_node: Node3D


func update_velocity(velocity):
	if velocity.length() > 0.1:
		_animated_sprite.play("default")
		if velocity.x < -0.1 :
			if isLeft:
				pass
			else :
				_sprite_direction.play("MoveLeft")
				isLeft = true
			
			
		else:
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
	
	
	pass


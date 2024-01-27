extends Node3D
@onready var _animated_sprite = $Body/DeerBody

func update_velocity(velocity):
	if velocity.length() > 0.1:
		_animated_sprite.play("default")
	
	else:
		_animated_sprite.play("Idle")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	pass


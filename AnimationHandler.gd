class_name AnimationHandler extends Node3D

@onready var _animated_sprite = $Body/DeerBody
@onready var _sprite_direction = $Body/DeerBody/SpriteDirection
var isLeft = true
var is_interacting = false
var timer : Timer
@export var skin : String = "Townie"
@export var character_node: Node3D


func update_velocity(velocity):
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
	
	
	if is_interacting:
		return
		
	if velocity.length() > 0.1:
		_animated_sprite.play(skin + "_Walk")

	else:
		_animated_sprite.play(skin + "_Idle")

# Called when the node enters the scene tree for the first time.
func _ready():
	character_node.connect("character_moved", update_velocity)
	character_node.connect("character_stopped", update_velocity.bind(Vector3.ZERO))
	character_node.connect("character_interacted", _handleInteract.bind(null))
	character_node.connect("character_stage_changed", _handleStageChange.bind(null))
	timer = Timer.new()
	add_child(timer)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func _handleInteract(context):
	_playAnimWithInto("Player_Joke")
	self.is_interacting = true
	
	print("AnimHandleInteract")
	
	timer.one_shot = true
	timer.timeout.connect(func(): is_interacting = false, CONNECT_ONE_SHOT)
	timer.start(5)
	
	
func _playAnimWithInto(AnimName):
	_animated_sprite.play(AnimName + "_Into")
	_animated_sprite.animation_finished.connect(func():	_animated_sprite.play(AnimName + "_Idle"), CONNECT_ONE_SHOT)
	
	
func _handleStageChange(State):
	pass	

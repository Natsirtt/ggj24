class_name AnimationHandler extends Node3D

@onready var _animated_sprite = $Body/DeerBody
@onready var _sprite_direction = $Body/DeerBody/SpriteDirection
var isLeft = true
var is_interacting = false
var timer : Timer
@export var skin : String = "Townie"
@export var character_node: Node3D
var color_tint: Color = Color.WHITE:
	set(val):
		$Body/DeerBody.modulate = val
	get:
		return $Body/DeerBody.modulate


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
	character_node.connect("character_interacted", _handleInteract)
	character_node.connect("character_stage_changed", _handleStageChange)
	timer = Timer.new()
	add_child(timer)
	_animated_sprite.play(skin + "_Idle")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var context_timings = {
	"Goon_save": 1.0,
	"Cultist_pray": 4.0
}

var anim_remapper = {
	"Player_attack": "Player_cultist",
	"Player_ship": "Player_cultist",
	"Goon_attack" : "Goon_save"
}


	

	
func _handleInteract(context):
	var anim_name = skin + "_" + context

	var real_anim_name = anim_remapper.get(anim_name, anim_name)
	_playAnimWithInto(real_anim_name)
	self.is_interacting = true
	
	print("AnimHandleInteract")
	
	timer.one_shot = true
	timer.timeout.connect(func(): is_interacting = false, CONNECT_ONE_SHOT)
	timer.start(context_timings.get(anim_name, 3.0))
	
	
func _playAnimWithInto(AnimName):
	_animated_sprite.play(AnimName + "_Into")
	_animated_sprite.animation_finished.connect(func():	_animated_sprite.play(AnimName + "_Idle"), CONNECT_ONE_SHOT)
	
	
func _handleStageChange(State):
	if State == citizens_info.Stage.CULTIST or State == citizens_info.Stage.FANATIC :
		is_interacting = true
		_animated_sprite.play(skin + "_Turn_Into")	
		timer.one_shot = true
		timer.timeout.connect(func(): _handleStageChange(-1) , CONNECT_ONE_SHOT)
		if State == citizens_info.Stage.CULTIST:
			timer.start(1)
		else:
			timer.start(3)
	else:
		_animated_sprite.play(skin + "_Idle")	
		is_interacting = false

extends CanvasLayer

@onready var favour_label := $"VBoxContainer/Favour/value"
@onready var fuel_label := $VBoxContainer/Fuel/value

func _ready():
	player_info.favour_generated.connect(func(_extra): _set_favour_label())
	player_info.favour_consumed.connect(func(_consumed): _set_favour_label())
	world_info.ship.fuel_changed.connect(func(fuel): fuel_label.text = str(fuel))
	_set_favour_label()

func _set_favour_label():
	favour_label.text = str(player_info.favour)

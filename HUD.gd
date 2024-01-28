extends CanvasLayer

@onready var favour_label := $"HBoxContainer/Favour value"

func _ready():
	player_info.favour_generated.connect(func(_extra): _set_favour_label())
	player_info.favour_consumed.connect(func(_consumed): _set_favour_label())
	_set_favour_label()

func _set_favour_label():
	favour_label.text = str(player_info.favour)

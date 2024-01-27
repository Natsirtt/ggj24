extends Node3D

@export var interactable_script: Interactable

func _ready():
	self.hide()
	interactable_script.ready_to_interact.connect(func(_interactor): self.show())
	interactable_script.unready_to_interact.connect(func(_interactor): self.hide())

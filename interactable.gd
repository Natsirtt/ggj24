class_name Interactable extends Area3D

signal interacted(interactor)
signal ready_to_interact(interactor)
signal unready_to_interact(interactor)

@export var cost = 0
@export var context_for_player: String = ""
@export var can_interact = true

func _ready():
	if context_for_player.length() == 0:
		push_error("Please set an interaction context for the player to know what it interacted with for animation purposes")

func interact(interactor):
	interacted.emit(interactor)

func ready_interact(interactor):
	ready_to_interact.emit(interactor)

func unready_interact(interactor):
	unready_to_interact.emit(interactor)

class_name Interactable extends Area3D

signal interacted(interactor)
signal ready_to_interact(interactor)
signal unready_to_interact(interactor)

@export var cost = 0

func interact(interactor):
	interacted.emit(interactor)

func ready_interact(interactor):
	ready_to_interact.emit(interactor)

func unready_interact(interactor):
	unready_to_interact.emit(interactor)

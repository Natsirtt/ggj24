class_name Interactable extends Area3D

signal interacted(interactor)

func interact(interactor):
	interacted.emit(interactor)

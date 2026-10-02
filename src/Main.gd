extends Node

func _ready() -> void:
	randomize()

func _input(event: InputEvent) -> void:
	if event.is_action("reset"):
		get_tree().reload_current_scene()

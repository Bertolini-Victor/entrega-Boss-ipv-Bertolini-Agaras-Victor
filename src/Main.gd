extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()

func _restart_level() -> void:
	get_tree().reload_current_scene()

func _on_player_player_died() -> void:
	_restart_level()


func _on_goal_level_completed() -> void:
	_restart_level()

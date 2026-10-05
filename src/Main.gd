class_name Main
extends Node

# Maneja eventos de entrada no procesados.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		_restart_level() 

# Reinicia la escena actual.
func _restart_level() -> void:
	get_tree().call_deferred("reload_current_scene")

# Callback para cuando el jugador muere.
func _on_player_player_died() -> void:
	_restart_level()

# Callback para cuando el jugador completa el nivel.
func _on_goal_level_completed() -> void:
	_restart_level()

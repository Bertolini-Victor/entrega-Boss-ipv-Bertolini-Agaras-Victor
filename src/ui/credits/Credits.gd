extends Control

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.is_action_pressed("ui_cancel"):
			_on_back_button_pressed()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")

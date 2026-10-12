extends Control

func _on_retry_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Main.tscn")

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")

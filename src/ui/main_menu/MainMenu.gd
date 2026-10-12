extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Main.tscn")

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/credits/Credits.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

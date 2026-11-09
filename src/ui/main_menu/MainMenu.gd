extends Control

# Inicia el juego cargando la cinematica o nivel principal.
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/intro/IntroCutscene.tscn")

# Abre la pantalla de creditos desde el menu principal.
func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/credits/Credits.tscn")

# Cierra la aplicacion del juego.
func _on_quit_button_pressed() -> void:
	get_tree().quit()

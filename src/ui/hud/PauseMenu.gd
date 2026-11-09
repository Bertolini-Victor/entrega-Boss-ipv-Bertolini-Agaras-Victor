class_name PauseMenu
extends CanvasLayer

var is_paused: bool = false

@onready var pause_button: Button = $PauseButton
@onready var overlay: ColorRect = $Overlay
@onready var btn_resume: Button = $Overlay/VBoxContainer/BtnResume
@onready var btn_music: Button = $Overlay/VBoxContainer/BtnMusic
@onready var btn_main_menu: Button = $Overlay/VBoxContainer/BtnMainMenu

# Configura el menu para procesar siempre y mantenerse oculto al inicio.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	is_paused = false

# Escucha la tecla de pausa (Escape / ui_cancel).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		toggle_pause()
		get_viewport().set_input_as_handled()

# Alterna el estado de pausa del arbol de juego y la visibilidad del menu.
func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	overlay.visible = is_paused

# Obtiene la referencia al reproductor de musica de fondo de la escena principal.
func _get_music_player() -> AudioStreamPlayer:
	if owner and owner.has_node("BackgroundMusic"):
		return owner.get_node("BackgroundMusic") as AudioStreamPlayer
	if get_tree().current_scene and get_tree().current_scene.has_node("BackgroundMusic"):
		return get_tree().current_scene.get_node("BackgroundMusic") as AudioStreamPlayer
	if get_tree().current_scene:
		var node = get_tree().current_scene.find_child("BackgroundMusic", true, false)
		if node is AudioStreamPlayer:
			return node as AudioStreamPlayer
	return null

# Callback al presionar el boton de pausa en el HUD.
func _on_pause_button_pressed() -> void:
	toggle_pause()

# Callback al presionar Seguir Jugando.
func _on_btn_resume_pressed() -> void:
	toggle_pause()

# Callback al alternar la reproduccion de la musica de fondo.
func _on_btn_music_pressed() -> void:
	var music_player = _get_music_player()
	if music_player:
		music_player.stream_paused = !music_player.stream_paused

# Callback al volver al menu principal despausando primero el arbol de juego.
func _on_btn_main_menu_pressed() -> void:
	get_tree().paused = false
	is_paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")

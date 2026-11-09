extends Control

const FRAME_DURATION: float = 2.2
const TOTAL_FRAMES: int = 30

@onready var slide_display: TextureRect = $SlideDisplay
@onready var ambient_music: AudioStreamPlayer = $AmbientMusic
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var frame_timer: Timer = $FrameTimer

var _frames: Array[Texture2D] = []
var _current_index: int = 0
var _is_transitioning: bool = false
var _frame_tween: Tween = null

# Prepara la reproduccion de cuadros y musica de la introduccion.
func _ready() -> void:
	# Cargar frames secuenciales 1.jpg a 30.jpg en orden numerico estricto
	for i in range(1, TOTAL_FRAMES + 1):
		var path := "res://assets/textures/intro_animation/%d.jpg" % i
		var tex: Texture2D = load(path)
		if tex:
			_frames.append(tex)
		else:
			push_warning("No se pudo cargar textura: " + path)

	# Asegurar loop de la musica ambiental
	if ambient_music:
		if not ambient_music.finished.is_connected(_on_music_finished):
			ambient_music.finished.connect(_on_music_finished)
		if not ambient_music.playing:
			ambient_music.play()

	# Mostrar el primer frame o pasar directamente si no hay texturas
	if _frames.size() > 0:
		_show_frame(0)
	else:
		_finish_cutscene()

# Permite avanzar de cuadro o saltar la cinematica completa.
func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_finish_cutscene()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE:
			_advance_frame()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			_advance_frame()
			get_viewport().set_input_as_handled()

# Pasa al siguiente fotograma de la cinematica o finaliza si era el ultimo.
func _advance_frame() -> void:
	if _is_transitioning:
		return

	_current_index += 1
	if _current_index >= _frames.size():
		_finish_cutscene()
	else:
		_show_frame(_current_index)

# Muestra el cuadro especificado con desvanecimiento.
func _show_frame(index: int) -> void:
	if index < 0 or index >= _frames.size():
		return

	slide_display.texture = _frames[index]

	# Transicion suave rapida de opacidad (0.15s)
	if _frame_tween and _frame_tween.is_valid():
		_frame_tween.kill()
	slide_display.modulate.a = 0.85
	_frame_tween = create_tween()
	_frame_tween.tween_property(slide_display, "modulate:a", 1.0, 0.15)

	# Reiniciar el temporizador para este frame
	frame_timer.start(FRAME_DURATION)

# Avanza automaticamente de fotograma por temporizador.
func _on_frame_timer_timeout() -> void:
	_advance_frame()

# Concluye la cinematica al terminar el audio de fondo.
func _on_music_finished() -> void:
	if not _is_transitioning and ambient_music:
		ambient_music.play()

# Transiciona la escena hacia el nivel principal del juego.
func _finish_cutscene() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	frame_timer.stop()

	# Fade-out a negro y bajada progresiva de volumen de audio
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.35)
	if ambient_music and ambient_music.playing:
		tween.tween_property(ambient_music, "volume_db", -80.0, 0.35)

	tween.chain().tween_callback(func():
		get_tree().change_scene_to_file("res://src/Main.tscn")
	)

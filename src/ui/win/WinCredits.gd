extends Control

@export var scroll_speed: float = 60.0
@onready var credits_container: Control = $CreditsContent

var _transitioned: bool = false
var _is_hovering_link: bool = false

func _ready() -> void:
	# Inicia el contenedor justo debajo de la pantalla
	credits_container.position.y = size.y
	var link_btn: Control = credits_container.get_node_or_null("VictoriaInstagram")
	if link_btn:
		link_btn.mouse_entered.connect(_on_link_mouse_entered)
		link_btn.mouse_exited.connect(_on_link_mouse_exited)

func _process(delta: float) -> void:
	if _transitioned:
		return
	if _is_hovering_link:
		return
	credits_container.position.y -= scroll_speed * delta
	if credits_container.position.y + credits_container.size.y < -30.0:
		_goto_main_menu()

func _on_link_mouse_entered() -> void:
	_is_hovering_link = true

func _on_link_mouse_exited() -> void:
	_is_hovering_link = false

func _unhandled_input(event: InputEvent) -> void:
	if _transitioned:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_accept"):
			_goto_main_menu()
	elif event is InputEventMouseButton and event.is_pressed():
		_goto_main_menu()

func _goto_main_menu() -> void:
	if _transitioned:
		return
	_transitioned = true
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")

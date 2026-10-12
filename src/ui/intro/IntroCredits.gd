extends Control

@onready var timer: Timer = $Timer

var _transitioned: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if _transitioned:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.is_action_pressed("ui_accept"):
			_goto_main_menu()
	elif event is InputEventMouseButton and event.is_pressed():
		_goto_main_menu()

func _on_timer_timeout() -> void:
	_goto_main_menu()

func _goto_main_menu() -> void:
	if _transitioned:
		return
	_transitioned = true
	get_tree().change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")

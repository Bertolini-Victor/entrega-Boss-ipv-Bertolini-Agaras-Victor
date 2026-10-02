extends Area2D

@onready var green_circle: Node2D = $GreenCircle


func _ready() -> void:
	green_circle.modulate = Color("#ffffff4d")
	green_circle.visible = false
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("show_enemy_detection_area"):
		green_circle.visible = !green_circle.visible

@tool
extends Node2D

@export var turret_scene: PackedScene
@export var amount: int
@export var extents: Vector2: set = _set_extents


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
	else:
		_initialize.call_deferred()

func _initialize() -> void:
	for i in amount:
		var turret_instance: Node = turret_scene.instantiate()
		var turret_pos: Vector2 = Vector2(
			randf_range(global_position.x, global_position.x + extents.x),
			randf_range(global_position.y, global_position.y + extents.y)
		)
		add_child(turret_instance)
		turret_instance.initialize(turret_pos, self)

func _set_extents(value: Vector2) -> void:
	extents = value
	
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, extents), Color.BLUE, false)

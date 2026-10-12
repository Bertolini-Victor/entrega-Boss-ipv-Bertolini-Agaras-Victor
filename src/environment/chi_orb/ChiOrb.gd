class_name ChiOrb
extends Area2D

@export var value: int = 10

var _collected: bool = false
var _time: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
	_base_y = position.y

func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * 4.0) * 2.5
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.8, 0.1, 0.35))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.88, 0.25, 0.85))
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 0.8, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is Player or body.has_method("collect_chi"):
		_collected = true
		if body.has_method("collect_chi"):
			body.collect_chi(value)
		queue_free()

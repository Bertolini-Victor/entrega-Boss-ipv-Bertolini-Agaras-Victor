class_name BreakableWall
extends StaticBody2D

@export var wall_color: Color = Color(0.35, 0.75, 0.95, 1.0)
@export var immune_flash_color: Color = Color(0.75, 0.75, 0.82, 1.0)
@export var break_flash_color: Color = Color(2.2, 2.4, 3.0, 1.0)
@export var break_duration: float = 0.25

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _is_breaking: bool = false
var _flash_tween: Tween = null

func _ready() -> void:
	if is_instance_valid(sprite):
		sprite.self_modulate = wall_color
	queue_redraw()

# Reacciona con un destello grisáceo al recibir ataques que no son Rayo Control.
func take_damage(_amount: int = 1) -> void:
	if _is_breaking or not is_instance_valid(sprite):
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	sprite.self_modulate = immune_flash_color
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "self_modulate", wall_color, 0.15)

# Destruye el muro al recibir un impacto directo de Rayo Control.
func hit_by_lightning() -> void:
	if _is_breaking:
		return
	_is_breaking = true
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
	queue_redraw()
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	if is_instance_valid(sprite):
		sprite.self_modulate = break_flash_color
		_flash_tween = create_tween()
		_flash_tween.set_parallel(true)
		_flash_tween.tween_property(sprite, "modulate:a", 0.0, break_duration)
		_flash_tween.tween_property(sprite, "scale", sprite.scale * 1.15, break_duration)
	await get_tree().create_timer(break_duration).timeout
	if not is_inside_tree():
		return
	queue_free()

func _draw() -> void:
	var line_color: Color = Color(0.75, 0.95, 1.0, 0.9) if not _is_breaking else Color(1.0, 1.0, 1.0, 1.0)
	draw_line(Vector2(-12.0, -68.0), Vector2(4.0, -32.0), line_color, 2.0)
	draw_line(Vector2(4.0, -32.0), Vector2(-10.0, 6.0), line_color, 2.0)
	draw_line(Vector2(-10.0, 6.0), Vector2(11.0, 42.0), line_color, 2.0)
	draw_line(Vector2(11.0, 42.0), Vector2(-6.0, 70.0), line_color, 2.0)
	if _is_breaking:
		draw_circle(Vector2(0.0, -20.0), 16.0, Color(0.6, 0.95, 1.0, 0.65))
		draw_circle(Vector2(0.0, 25.0), 18.0, Color(0.6, 0.95, 1.0, 0.65))

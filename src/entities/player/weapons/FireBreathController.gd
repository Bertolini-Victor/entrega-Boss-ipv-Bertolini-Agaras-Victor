class_name FireBreathController
extends Node2D

@export var vertical_range: float = 135.0
@export var breath_width: float = 44.0
@export var attack_duration: float = 0.28
@export var fire_cooldown: float = 0.45

var _is_attacking: bool = false
var _cooldown_timer: float = 0.0
var _visual_timer: float = 0.0
var _player: CharacterBody2D = null

func _ready() -> void:
	_player = _get_player()

func _get_player() -> CharacterBody2D:
	if owner is CharacterBody2D:
		return owner as CharacterBody2D
	var current: Node = get_parent()
	while current != null:
		if current is CharacterBody2D:
			return current as CharacterBody2D
		current = current.get_parent()
	return null

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	if _is_attacking:
		_visual_timer = maxf(0.0, _visual_timer - delta)
		queue_redraw()

func is_ready() -> bool:
	return not _is_attacking and _cooldown_timer <= 0.0

func is_attacking() -> bool:
	return _is_attacking

# Ejecuta el ataque de Aliento de Fuego exclusivamente en direccion vertical (Vector2.UP).
func attack() -> void:
	if not is_ready():
		return

	if _player == null:
		_player = _get_player()

	_is_attacking = true
	_visual_timer = attack_duration
	_cooldown_timer = fire_cooldown
	queue_redraw()

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2(breath_width, vertical_range)

	var hit_origin: Vector2 = global_position + Vector2(0.0, -vertical_range * 0.5)

	var body_params := PhysicsShapeQueryParameters2D.new()
	body_params.shape = shape
	body_params.collision_mask = 4
	body_params.collide_with_bodies = true
	body_params.collide_with_areas = false
	body_params.transform = Transform2D(0.0, hit_origin)

	var results: Array = space_state.intersect_shape(body_params)
	for result in results:
		var collider = result["collider"]
		if collider.has_method("take_damage"):
			collider.take_damage(1)
		elif collider.has_method("die"):
			collider.die()

	var area_params := PhysicsShapeQueryParameters2D.new()
	area_params.shape = shape
	area_params.collision_mask = 16
	area_params.collide_with_bodies = false
	area_params.collide_with_areas = true
	area_params.transform = Transform2D(0.0, hit_origin)

	var area_results: Array = space_state.intersect_shape(area_params)
	for area_result in area_results:
		var area_collider = area_result["collider"]
		if area_collider is Area2D:
			var proj = area_collider.get_parent()
			if proj != null and proj.has_method("remove") and not proj is FireballProjectile and not proj is LightningProjectile:
				proj.remove()

	await get_tree().create_timer(attack_duration).timeout
	if not is_inside_tree():
		return
	_is_attacking = false
	queue_redraw()

func _draw() -> void:
	if not _is_attacking:
		return

	var progress: float = clampf(1.0 - (_visual_timer / maxf(attack_duration, 0.01)), 0.0, 1.0)
	var alpha: float = clampf(sin(progress * PI) * 1.15, 0.25, 1.0)
	var current_height: float = lerpf(vertical_range * 0.45, vertical_range, clampf(progress * 2.2, 0.0, 1.0))
	var half_w_top: float = breath_width * 0.5
	var half_w_base: float = breath_width * 0.18

	var outer_pts := PackedVector2Array([
		Vector2(-half_w_base, -4.0),
		Vector2(-half_w_top, -current_height),
		Vector2(0.0, -current_height - 10.0),
		Vector2(half_w_top, -current_height),
		Vector2(half_w_base, -4.0)
	])
	var outer_col := Color(1.0, 0.28, 0.05, 0.55 * alpha)
	draw_colored_polygon(outer_pts, outer_col)

	var inner_pts := PackedVector2Array([
		Vector2(-half_w_base * 0.65, -4.0),
		Vector2(-half_w_top * 0.6, -current_height * 0.88),
		Vector2(0.0, -current_height * 0.96),
		Vector2(half_w_top * 0.6, -current_height * 0.88),
		Vector2(half_w_base * 0.65, -4.0)
	])
	var inner_col := Color(1.0, 0.72, 0.15, 0.75 * alpha)
	draw_colored_polygon(inner_pts, inner_col)

	var core_pts := PackedVector2Array([
		Vector2(-half_w_base * 0.35, -4.0),
		Vector2(-half_w_top * 0.28, -current_height * 0.65),
		Vector2(0.0, -current_height * 0.75),
		Vector2(half_w_top * 0.28, -current_height * 0.65),
		Vector2(half_w_base * 0.35, -4.0)
	])
	var core_col := Color(1.0, 0.96, 0.65, 0.9 * alpha)
	draw_colored_polygon(core_pts, core_col)

	for i: int in range(5):
		var t: float = fmod(progress * 1.8 + float(i) * 0.2, 1.0)
		var x_off: float = sin(t * TAU + float(i) * 1.4) * (half_w_top * 0.55 * t)
		var y_off: float = -lerpf(10.0, current_height, t)
		var r: float = lerpf(5.5, 2.0, t)
		draw_circle(Vector2(x_off, y_off), r, Color(1.0, 0.82, 0.25, (1.0 - t) * 0.85 * alpha))

func die() -> void:
	queue_free()

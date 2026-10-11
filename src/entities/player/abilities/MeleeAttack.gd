extends Node2D
class_name MeleeAttack

@export var attack_duration: float = 0.15
@export var attack_range: float = 40.0
@export var wall_check_distance: float = 18.0

var _is_attacking: bool = false
var _draw_slash: bool = false
var _slash_facing: float = 1.0
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

# Ejecuta el ataque cuerpo a cuerpo orientado según facing_direction (+1.0 o -1.0).
func attack(facing_direction: float = 1.0) -> void:
	if _is_attacking:
		return

	var facing: float = 1.0 if facing_direction >= 0.0 else -1.0

	if _player == null:
		_player = _get_player()

	# Bloquear el ataque si el jugador está pegado físicamente a una pared en la dirección frontal
	if _player != null and _player.is_on_wall():
		var wall_normal: Vector2 = _player.get_wall_normal()
		if sign(wall_normal.x) == -facing:
			return

	# Chequeo frontal mediante raycast contra Capa 1 ("world") y Capa 4 ("obstacles")
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var exclude_rids: Array[RID] = []
	if _player != null:
		exclude_rids.append(_player.get_rid())

	var ray_params := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(facing * wall_check_distance, 0.0),
		1 | 8,
		exclude_rids
	)
	ray_params.collide_with_bodies = true
	ray_params.collide_with_areas = false

	var wall_hit: Dictionary = space_state.intersect_ray(ray_params)
	if not wall_hit.is_empty():
		return

	_is_attacking = true

	# Activar el efecto visual del corte
	_slash_facing = facing
	_draw_slash = true
	queue_redraw()

	# Usar PhysicsShapeQueryParameters2D para detección instantánea y confiable
	var shape := RectangleShape2D.new()
	var attack_height: float = 30.0
	shape.size = Vector2(attack_range, attack_height)

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.collision_mask = 4  # Capa de enemigos (turrets)
	params.collide_with_bodies = true
	params.collide_with_areas = false

	# Centrar el shape adelante del jugador según la dirección y rango de ataque
	var hit_origin: Vector2 = global_position + Vector2((attack_range * 0.5) * facing, 0.0)
	params.transform = Transform2D(0.0, hit_origin)

	var results: Array = space_state.intersect_shape(params)
	for result in results:
		var collider = result["collider"]
		if collider.has_method("die"):
			collider.die()

	await get_tree().create_timer(attack_duration).timeout
	_draw_slash = false
	queue_redraw()
	_is_attacking = false

func _draw() -> void:
	if not _draw_slash:
		return

	# Dibujar un arco semitransparente amarillo/blanco como efecto de corte
	var slash_color := Color(1.0, 0.95, 0.6, 0.55)
	var center := Vector2((attack_range * 0.25) * _slash_facing, -3.0)
	var radius := attack_range * 0.55
	# Ángulo del arco: de -60° a +60° (mirando a la derecha) o invertido
	var start_angle: float
	var end_angle: float
	if _slash_facing > 0:
		start_angle = deg_to_rad(-60.0)
		end_angle = deg_to_rad(60.0)
	else:
		start_angle = deg_to_rad(120.0)
		end_angle = deg_to_rad(240.0)

	# Construir los puntos del arco como un polígono relleno
	var point_count: int = 12
	var arc_points: PackedVector2Array = PackedVector2Array()
	arc_points.append(center)
	for i in range(point_count + 1):
		var angle: float = start_angle + (end_angle - start_angle) * float(i) / float(point_count)
		arc_points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var colors: PackedColorArray = PackedColorArray()
	for i in range(arc_points.size()):
		colors.append(slash_color)
	draw_polygon(arc_points, colors)

	# Borde exterior más brillante
	var edge_color := Color(1.0, 1.0, 0.8, 0.8)
	for i in range(point_count):
		var angle_a: float = start_angle + (end_angle - start_angle) * float(i) / float(point_count)
		var angle_b: float = start_angle + (end_angle - start_angle) * float(i + 1) / float(point_count)
		var pa: Vector2 = center + Vector2(cos(angle_a), sin(angle_a)) * radius
		var pb: Vector2 = center + Vector2(cos(angle_b), sin(angle_b)) * radius
		draw_line(pa, pb, edge_color, 2.0)

func die() -> void:
	queue_free()

extends Node2D
class_name MeleeAttack

@export var attack_duration: float = 0.15
@export var attack_range: float = 40.0
var _is_attacking: bool = false
var _draw_slash: bool = false
var _slash_facing: float = 1.0

# Ejecuta el ataque cuerpo a cuerpo orientado según facing_direction (+1.0 o -1.0).
func attack(facing_direction: float = 1.0) -> void:
	if _is_attacking:
		return
	_is_attacking = true

	var facing: float = 1.0 if facing_direction >= 0.0 else -1.0

	# Activar el efecto visual del corte
	_slash_facing = facing
	_draw_slash = true
	queue_redraw()

	# Usar PhysicsShapeQueryParameters2D para detección instantánea y confiable
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

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

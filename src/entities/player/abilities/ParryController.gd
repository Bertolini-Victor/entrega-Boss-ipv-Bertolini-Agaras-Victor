class_name ParryController
extends Node2D

signal parry_success
signal parry_failed

@export var parry_window: float = 0.25
@export var redirect_window: float = 0.10
@export var chi_reward: int = 15
@export var melee_parry_range: float = 65.0

@onready var parry_zone: Area2D = $ParryZone

var _player: Node2D = null
var _incoming_projectile: Node = null
var _can_parry: bool = false
var _parry_timer: float = 0.0
var _active_parry_timer: float = 0.0

var _draw_shield: bool = false
var _visual_timer: float = 0.0
var _visual_duration: float = 0.25
var _is_success: bool = false

var _is_redirect: bool = false
var _attempting_redirect: bool = false

func _ready() -> void:
	_player = get_parent()
	if not parry_zone.area_exited.is_connected(_on_parry_zone_area_exited):
		parry_zone.area_exited.connect(_on_parry_zone_area_exited)

func _process(delta: float) -> void:
	if _draw_shield:
		_visual_timer -= delta
		if _visual_timer <= 0.0:
			_draw_shield = false
		queue_redraw()

	if _can_parry:
		_parry_timer -= delta
		if _parry_timer <= 0.0:
			_parry_expired()

	if _active_parry_timer > 0.0:
		_active_parry_timer -= delta
		var melee_enemy: Node2D = _find_parryable_melee_enemy()
		if melee_enemy != null:
			_do_melee_parry(melee_enemy)

func try_parry(allow_redirect: bool = false) -> void:
	_draw_shield = true
	_visual_timer = _visual_duration
	_is_success = false
	_is_redirect = false
	_attempting_redirect = allow_redirect
	_active_parry_timer = parry_window
	queue_redraw()

	if _can_parry and _incoming_projectile != null and is_instance_valid(_incoming_projectile):
		_active_parry_timer = 0.0
		if allow_redirect:
			_do_redirect()
		else:
			_do_parry()
		return

	var melee_enemy: Node2D = _find_parryable_melee_enemy()
	if melee_enemy != null:
		_do_melee_parry(melee_enemy)
		return

	parry_failed.emit()

func try_parry_melee_attack(attacker: Node2D) -> bool:
	if _active_parry_timer <= 0.0 or attacker == null or not is_instance_valid(attacker):
		return false
	_do_melee_parry(attacker)
	return true

func _do_melee_parry(enemy: Node2D) -> void:
	_active_parry_timer = 0.0
	_can_parry = false
	if enemy != null and is_instance_valid(enemy) and enemy.has_method("on_parried"):
		enemy.on_parried()
	_is_success = true
	_is_redirect = false
	_draw_shield = true
	_visual_timer = _visual_duration
	queue_redraw()
	_grant_chi_reward()
	parry_success.emit()

func _find_parryable_melee_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_dist: float = melee_parry_range
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.is_inside_tree() or ("dead" in enemy and enemy.dead):
			continue
		if not enemy.has_method("is_parryable_attack_active") or not enemy.is_parryable_attack_active():
			continue
		var d: float = global_position.distance_to(enemy.global_position)
		if d <= min_dist:
			min_dist = d
			nearest = enemy
	return nearest

func _do_redirect() -> void:
	_can_parry = false
	if _incoming_projectile != null and is_instance_valid(_incoming_projectile):
		var target = _find_nearest_enemy()
		if target != null:
			var new_dir = _incoming_projectile.global_position.direction_to(target.global_position)
			_incoming_projectile.direction = new_dir
			_incoming_projectile.rotation = new_dir.angle()
			var hitbox = _incoming_projectile.get_node_or_null("Hitbox")
			if hitbox:
				hitbox.collision_mask = 1 | 4 | 8
				hitbox.collision_layer = 0
			else:
				_incoming_projectile.remove()
			_incoming_projectile = null
			_is_success = true
			_is_redirect = true
			_grant_chi_reward()
			parry_success.emit()
		else:
			# CRITERIO DE ACEPTACIÓN: Si no hay Turret viva, hace bloqueo normal
			_do_parry()
	else:
		_do_parry()

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_dist: float = INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.is_inside_tree() or ("dead" in enemy and enemy.dead):
			continue
		var d = global_position.distance_to(enemy.global_position)
		if d < min_dist:
			min_dist = d
			nearest = enemy
	return nearest

func _on_parry_zone_area_entered(area: Area2D) -> void:
	var proj = area.get_parent()
	if proj is Projectile and not proj is FireballProjectile and not proj is LightningProjectile:
		_incoming_projectile = proj
		_can_parry = true
		_parry_timer = parry_window

func _on_parry_zone_area_exited(area: Area2D) -> void:
	if area.get_parent() == _incoming_projectile:
		_parry_expired()

func _do_parry() -> void:
	_can_parry = false
	if _incoming_projectile != null and is_instance_valid(_incoming_projectile):
		_incoming_projectile.remove()
	_incoming_projectile = null
	
	_is_success = true
	_grant_chi_reward()
	parry_success.emit()

func _grant_chi_reward() -> void:
	if _player != null and is_instance_valid(_player) and _player.has_method("collect_chi"):
		_player.collect_chi(chi_reward)

func _parry_expired() -> void:
	_can_parry = false
	_incoming_projectile = null

func die() -> void:
	queue_free()

func _draw() -> void:
	if not _draw_shield:
		return
	
	var center := Vector2.ZERO
	var progress = clamp(1.0 - (_visual_timer / _visual_duration), 0.0, 1.0)
	
	# El radio se expande de 15 a 45
	var radius = lerp(15.0, 45.0, progress)
	var alpha = lerp(0.8, 0.0, progress)
	
	var shield_color: Color
	var edge_color: Color
	
	if _is_success:
		if _is_redirect:
			# Violeta/Magenta vibrante para que se distinga mucho del amarillo del parry normal
			shield_color = Color(0.8, 0.2, 1.0, alpha * 0.7)
			edge_color = Color(1.0, 0.4, 1.0, alpha)
		else:
			# Amarillo/blanco brillante para parry normal
			shield_color = Color(1.0, 0.9, 0.4, alpha * 0.6)
			edge_color = Color(1.0, 1.0, 0.8, alpha)
	else:
		if _attempting_redirect:
			# Si intentamos un redirect al aire o fallamos la ventana, lo mostramos morado opaco/oscuro
			shield_color = Color(0.5, 0.1, 0.6, alpha * 0.4)
			edge_color = Color(0.7, 0.2, 0.8, alpha)
		else:
			# Azul frío para intento de parry normal fallido
			shield_color = Color(0.4, 0.8, 1.0, alpha * 0.4)
			edge_color = Color(0.6, 0.9, 1.0, alpha)
	
	draw_circle(center, radius, shield_color)
	
	# Dibujar el borde
	var point_count = 24
	var points = PackedVector2Array()
	for i in range(point_count + 1):
		var angle = float(i) / point_count * TAU
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	for i in range(point_count):
		draw_line(points[i], points[i+1], edge_color, 2.0)

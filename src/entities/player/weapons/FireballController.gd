class_name FireballController
extends Node2D

@onready var weapon_tip: Node2D = $WeaponTip
@onready var fire_timer: Timer = $FireTimer
@export var projectile_scene: PackedScene

var projectile_container: Node

# Calcula la direccion hacia donde mira el jugador.
func _get_facing_direction() -> Vector2:
	if owner is Player:
		return (owner as Player).get_facing_direction()
	var current: Node = get_parent()
	while current != null:
		if current is Player:
			return (current as Player).get_facing_direction()
		current = current.get_parent()
	return Vector2.RIGHT

# Orienta el arma estrictamente en direccion horizontal segun hacia donde mira el jugador.
func process_input() -> void:
	var facing_dir: Vector2 = _get_facing_direction()
	rotation = 0.0 if facing_dir.x >= 0.0 else PI

# Instancia un proyectil y lo dispara estrictamente en linea recta horizontal segun el frente del jugador.
func fire() -> void:
	if not fire_timer.is_stopped():
		return
	var horizontal_dir: Vector2 = _get_facing_direction()
	rotation = 0.0 if horizontal_dir.x >= 0.0 else PI
	var projectile_instance: Node = projectile_scene.instantiate()
	projectile_container.add_child(projectile_instance)
	projectile_instance.initialize(
		weapon_tip.global_position,
		horizontal_dir
	)
	fire_timer.start()

# Comprueba si el proyectil de bola de fuego esta listo para dispararse.
func is_ready() -> bool:
	return fire_timer.is_stopped()

# Destruye el arma.
func die() -> void:
	queue_free()

class_name FireballController
extends Node2D

@onready var weapon_tip: Node2D = $WeaponTip
@onready var fire_timer: Timer = $FireTimer
@export var projectile_scene: PackedScene

var projectile_container: Node

# Orienta el arma estrictamente en direccion horizontal segun la posicion del puntero.
func process_input() -> void:
	var dir_x: float = 1.0 if get_global_mouse_position().x >= global_position.x else -1.0
	rotation = 0.0 if dir_x > 0.0 else PI

# Instancia un proyectil y lo dispara estrictamente en linea recta horizontal.
func fire() -> void:
	if not fire_timer.is_stopped():
		return
	var dir_x: float = 1.0 if get_global_mouse_position().x >= global_position.x else -1.0
	var horizontal_dir: Vector2 = Vector2.RIGHT if dir_x > 0.0 else Vector2.LEFT
	rotation = 0.0 if dir_x > 0.0 else PI
	var projectile_instance: Node = projectile_scene.instantiate()
	projectile_container.add_child(projectile_instance)
	projectile_instance.initialize(
		weapon_tip.global_position,
		horizontal_dir
	)
	fire_timer.start()

func is_ready() -> bool:
	return fire_timer.is_stopped()

# Destruye el arma.
func die() -> void:
	queue_free()

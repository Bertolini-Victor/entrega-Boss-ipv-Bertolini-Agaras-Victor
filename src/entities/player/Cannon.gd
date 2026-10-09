class_name Cannon
extends Node2D

@onready var weapon_tip: Node2D = $WeaponTip
@onready var fire_timer: Timer = $FireTimer
@export var projectile_scene: PackedScene

var projectile_container: Node

# Orienta el arma hacia el cursor.
func process_input() -> void:
	look_at(get_global_mouse_position())

# Instancia un proyectil y lo dispara.
func fire() -> void:
	if not fire_timer.is_stopped():
		return
	var projectile_instance: Node = projectile_scene.instantiate()
	projectile_container.add_child(projectile_instance)
	projectile_instance.initialize(
		weapon_tip.global_position,
		global_position.direction_to(weapon_tip.global_position)
	)
	fire_timer.start()

# Destruye el arma.
func die() -> void:
	queue_free() 

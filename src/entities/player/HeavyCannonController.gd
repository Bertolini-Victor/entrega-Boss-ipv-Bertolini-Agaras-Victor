class_name HeavyCannonController
extends Node2D

@export var projectile_scene: PackedScene
@export var charge_time: float = 0.6
@export var fire_cooldown: float = 1.2

var projectile_container: Node
var _is_charging: bool = false
var _on_cooldown: bool = false

@onready var weapon_tip: Marker2D = $WeaponTip
@onready var charge_timer: Timer = $ChargeTimer
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	if charge_timer and not charge_timer.timeout.is_connected(_on_charge_timer_timeout):
		charge_timer.timeout.connect(_on_charge_timer_timeout)
	if cooldown_timer and not cooldown_timer.timeout.is_connected(_on_cooldown_timer_timeout):
		cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

# Procesa la entrada y maneja la carga y orientación del arma pesada.
func process_input() -> void:
	look_at(get_global_mouse_position())
	if Input.is_action_pressed("attack_heavy") and not _on_cooldown:
		if not _is_charging:
			_start_charge()
	elif _is_charging:
		_cancel_charge()

func _start_charge() -> void:
	_is_charging = true
	charge_timer.start(charge_time)

func _cancel_charge() -> void:
	_is_charging = false
	charge_timer.stop()

func _on_charge_timer_timeout() -> void:
	_fire()
	_is_charging = false
	_on_cooldown = true
	cooldown_timer.start(fire_cooldown)

func _on_cooldown_timer_timeout() -> void:
	_on_cooldown = false

func _fire() -> void:
	if projectile_scene == null:
		return
	var container: Node = projectile_container if projectile_container != null else get_parent()
	var projectile_instance: Node = projectile_scene.instantiate()
	container.add_child(projectile_instance)
	projectile_instance.initialize(
		weapon_tip.global_position,
		global_position.direction_to(weapon_tip.global_position)
	)

func die() -> void:
	_is_charging = false
	if charge_timer and is_instance_valid(charge_timer):
		charge_timer.stop()
	if cooldown_timer and is_instance_valid(cooldown_timer):
		cooldown_timer.stop()
	queue_free()

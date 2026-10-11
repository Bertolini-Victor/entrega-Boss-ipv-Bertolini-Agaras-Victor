class_name HeavyCannonController
extends Node2D

@export var projectile_scene: PackedScene
@export var charge_time: float = 0.6
@export var fire_cooldown: float = 1.2

var projectile_container: Node = null
var _is_charging: bool = false
var _on_cooldown: bool = false

var _sprite: CanvasItem = null
var _original_modulate: Color = Color.WHITE
var _original_scale: Vector2 = Vector2.ONE

@onready var weapon_tip: Marker2D = $WeaponTip
@onready var charge_timer: Timer = $ChargeTimer
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	_init_visual_feedback()

func _init_visual_feedback() -> void:
	var target: CanvasItem = _get_sprite()
	if target != null:
		_original_modulate = target.modulate
		_original_scale = target.scale
	else:
		_original_modulate = modulate
		_original_scale = scale

func _get_sprite() -> CanvasItem:
	if _sprite != null and is_instance_valid(_sprite):
		return _sprite
	if has_node("Sprite2D"):
		_sprite = get_node("Sprite2D") as CanvasItem
	elif get_parent() and get_parent().has_node("Weapon/Sprite2D"):
		_sprite = get_parent().get_node("Weapon/Sprite2D") as CanvasItem
	elif get_parent() and get_parent().has_node("%Weapon/Sprite2D"):
		_sprite = get_parent().get_node("%Weapon/Sprite2D") as CanvasItem
	
	if _sprite != null:
		_original_modulate = _sprite.modulate
		_original_scale = _sprite.scale
	return _sprite

func _apply_charge_feedback(charging: bool) -> void:
	var target: CanvasItem = _get_sprite()
	if charging:
		var charge_color: Color = Color(1.8, 1.2, 0.2, 1.0)
		var charge_scale: Vector2 = _original_scale * 1.15
		if target != null:
			target.modulate = charge_color
			target.scale = charge_scale
		modulate = charge_color
		scale = charge_scale
	else:
		if target != null:
			target.modulate = _original_modulate
			target.scale = _original_scale
		modulate = _original_modulate
		scale = _original_scale

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
	_apply_charge_feedback(true)
	charge_timer.start(charge_time)

func _cancel_charge() -> void:
	_is_charging = false
	_apply_charge_feedback(false)
	charge_timer.stop()

func _on_charge_timer_timeout() -> void:
	_fire()
	_is_charging = false
	_apply_charge_feedback(false)
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
	_apply_charge_feedback(false)
	if charge_timer and is_instance_valid(charge_timer):
		charge_timer.stop()
	if cooldown_timer and is_instance_valid(cooldown_timer):
		cooldown_timer.stop()
	queue_free()

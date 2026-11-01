class_name LightningController
extends Node2D

@export var projectile_scene: PackedScene
@export var charge_time: float = 0.55
@export var fire_cooldown: float = 1.2
@export var chi_cost: int = 20

var projectile_container: Node = null
var _is_charging: bool = false
var _on_cooldown: bool = false

var _sprite: CanvasItem = null
var _original_modulate: Color = Color.WHITE

@onready var weapon_tip: Marker2D = $WeaponTip
@onready var charge_timer: Timer = $ChargeTimer
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	_init_visual_feedback()

func _init_visual_feedback() -> void:
	var target: CanvasItem = _get_sprite()
	if target != null:
		_original_modulate = target.self_modulate
	else:
		_original_modulate = Color.WHITE

func _get_player() -> Player:
	if owner is Player:
		return owner as Player
	if get_parent() and get_parent().get_parent() is Player:
		return get_parent().get_parent() as Player
	var p: Node = get_tree().get_first_node_in_group("player")
	if p is Player:
		return p as Player
	return null

func _get_facing_direction() -> Vector2:
	var player: Player = _get_player()
	if player != null:
		return player.get_facing_direction()
	return Vector2.RIGHT

func _can_pay_chi() -> bool:
	var player: Player = _get_player()
	if player != null:
		return player.has_enough_chi(chi_cost)
	return true

func _consume_chi() -> bool:
	var player: Player = _get_player()
	if player != null:
		return player.consume_chi(chi_cost)
	return true

func _get_sprite() -> CanvasItem:
	if _sprite != null and is_instance_valid(_sprite):
		return _sprite
	if has_node("Sprite2D"):
		_sprite = get_node("Sprite2D") as CanvasItem
	elif owner != null and owner.has_node("BodyPivot/Body"):
		_sprite = owner.get_node("BodyPivot/Body") as CanvasItem
	elif get_parent() and get_parent().get_parent() and get_parent().get_parent().has_node("BodyPivot/Body"):
		_sprite = get_parent().get_parent().get_node("BodyPivot/Body") as CanvasItem

	if _sprite != null:
		_original_modulate = _sprite.self_modulate
	return _sprite

func _apply_charge_feedback(charging: bool) -> void:
	var target: CanvasItem = _get_sprite()
	if charging:
		var charge_color: Color = Color(1.8, 1.2, 0.2, 1.0)
		if target != null:
			target.self_modulate = charge_color
		modulate = charge_color
	else:
		if target != null:
			target.self_modulate = _original_modulate
		modulate = Color.WHITE

# Procesa la entrada y orienta el ataque de rayo estrictamente en horizontal.
func process_input() -> void:
	var horizontal_dir: Vector2 = _get_facing_direction()
	rotation = 0.0 if horizontal_dir.x >= 0.0 else PI
	if (Input.is_action_just_pressed("attack_lightning") or Input.is_action_pressed("attack_lightning")) and not _on_cooldown:
		if not _is_charging:
			if _can_pay_chi():
				_start_charge()

func _start_charge() -> void:
	_is_charging = true
	_apply_charge_feedback(true)
	charge_timer.start(charge_time)

func _cancel_charge() -> void:
	_is_charging = false
	_apply_charge_feedback(false)
	charge_timer.stop()

func _on_charge_timer_timeout() -> void:
	if not _consume_chi():
		_cancel_charge()
		return
	_fire()
	_is_charging = false
	_apply_charge_feedback(false)
	_on_cooldown = true
	cooldown_timer.start(fire_cooldown)

func _on_cooldown_timer_timeout() -> void:
	_on_cooldown = false

# Instancia y dispara el rayo estrictamente en linea recta horizontal.
func _fire() -> void:
	if projectile_scene == null:
		return
	var horizontal_dir: Vector2 = _get_facing_direction()
	rotation = 0.0 if horizontal_dir.x >= 0.0 else PI
	var container: Node = projectile_container if projectile_container != null else get_parent()
	var projectile_instance: Node = projectile_scene.instantiate()
	container.add_child(projectile_instance)
	projectile_instance.initialize(
		weapon_tip.global_position,
		horizontal_dir
	)

func is_charging() -> bool:
	return _is_charging

func die() -> void:
	_is_charging = false
	_apply_charge_feedback(false)
	if charge_timer and is_instance_valid(charge_timer):
		charge_timer.stop()
	if cooldown_timer and is_instance_valid(cooldown_timer):
		cooldown_timer.stop()
	queue_free()

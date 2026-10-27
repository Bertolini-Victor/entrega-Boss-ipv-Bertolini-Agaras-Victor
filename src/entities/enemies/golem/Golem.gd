class_name Golem
extends CharacterBody2D

signal died

enum State {
	IDLE,
	CHASE,
	TELEGRAPH,
	ATTACK,
	STUNNED,
	HURT,
	DEAD
}

const CHI_ORB_SCENE: PackedScene = preload("res://src/environment/chi_orb/ChiOrb.tscn")

@export var max_health: int = 3
@export var move_speed: float = 65.0
@export var patrol_speed: float = 32.0
@export var patrol_distance: float = 64.0
@export var attack_range: float = 46.0
@export var attack_damage: int = 1
@export var telegraph_duration: float = 0.45
@export var attack_active_duration: float = 0.20
@export var attack_cooldown: float = 0.90
@export var stun_duration: float = 1.20
@export var gravity_acceleration: float = 980.0
@export var max_fall_speed: float = 650.0
@export var telegraph_color: Color = Color(2.2, 0.55, 0.3, 1.0)
@export var stun_color: Color = Color(0.55, 0.75, 1.4, 1.0)

@onready var body_anim: AnimatedSprite2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var floor_check: RayCast2D = $FloorCheck
@onready var detection_area: Area2D = $DetectionArea

var health: int = 3
var dead: bool = false
var target: Node2D = null

var _state: State = State.IDLE
var _spawn_x: float = 0.0
var _facing: float = -1.0
var _cooldown_timer: float = 0.0
var _state_timer: float = 0.0
var _parryable_window: bool = false
var _telegraph_tween: Tween = null

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_spawn_x = global_position.x
	_set_facing(_facing)
	_play_animation("idle")

func _physics_process(delta: float) -> void:
	if dead:
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity_acceleration * delta, max_fall_speed)
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)

	match _state:
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				if body_anim != null:
					body_anim.self_modulate = Color.WHITE
					body_anim.speed_scale = 1.0
				_cooldown_timer = maxf(_cooldown_timer, attack_cooldown * 0.4)
				_state = State.CHASE if _has_valid_target() else State.IDLE
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				if body_anim != null:
					body_anim.self_modulate = Color.WHITE
					body_anim.speed_scale = 1.0
				_state = State.CHASE if _has_valid_target() else State.IDLE
		State.TELEGRAPH, State.ATTACK:
			velocity.x = 0.0
		State.CHASE:
			_process_chase_state()
		State.IDLE:
			_process_idle_state()

	move_and_slide()

func _has_valid_target() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.is_inside_tree():
		return false
	if "dead" in target and target.dead:
		return false
	return true

func _process_chase_state() -> void:
	if not _has_valid_target():
		target = null
		_state = State.IDLE
		return

	var dx: float = target.global_position.x - global_position.x
	var dy: float = absf(target.global_position.y - global_position.y)
	if absf(dx) > 2.0:
		_set_facing(1.0 if dx >= 0.0 else -1.0)

	if absf(dx) <= attack_range and dy <= 48.0:
		velocity.x = 0.0
		if _cooldown_timer <= 0.0:
			_start_attack_sequence()
		else:
			_play_animation("idle")
		return

	if _can_advance_on_floor():
		velocity.x = _facing * move_speed
		_play_animation("run")
	else:
		velocity.x = 0.0
		_play_animation("idle")

func _process_idle_state() -> void:
	if _has_valid_target():
		_state = State.CHASE
		return

	var offset_from_spawn: float = global_position.x - _spawn_x
	if absf(offset_from_spawn) >= patrol_distance and sign(offset_from_spawn) == _facing:
		_set_facing(-_facing)
	elif is_on_wall() or not _can_advance_on_floor():
		_set_facing(-_facing)

	if _can_advance_on_floor():
		velocity.x = _facing * patrol_speed
		_play_animation("run")
	else:
		velocity.x = 0.0
		_play_animation("idle")

func _can_advance_on_floor() -> bool:
	if not is_on_floor():
		return true
	if floor_check == null:
		return true
	floor_check.force_raycast_update()
	return floor_check.is_colliding()

func _set_facing(dir: float) -> void:
	_facing = 1.0 if dir >= 0.0 else -1.0
	if body_anim != null:
		body_anim.flip_h = _facing < 0.0
	if floor_check != null:
		floor_check.position.x = absf(floor_check.position.x) * _facing

func _cancel_telegraph() -> void:
	if _telegraph_tween != null and _telegraph_tween.is_valid():
		_telegraph_tween.kill()
	_telegraph_tween = null
	if body_anim != null:
		body_anim.self_modulate = Color.WHITE
		body_anim.speed_scale = 1.0

func _start_attack_sequence() -> void:
	if dead or _state == State.TELEGRAPH or _state == State.ATTACK or _state == State.STUNNED:
		return

	_state = State.TELEGRAPH
	_parryable_window = true
	velocity.x = 0.0
	_play_animation("attack")

	if body_anim != null:
		body_anim.speed_scale = 0.55
		body_anim.self_modulate = Color.WHITE

	if _telegraph_tween != null and _telegraph_tween.is_valid():
		_telegraph_tween.kill()
	_telegraph_tween = create_tween()
	if body_anim != null:
		_telegraph_tween.tween_property(body_anim, "self_modulate", telegraph_color, telegraph_duration)
	else:
		_telegraph_tween.tween_interval(telegraph_duration)

	await _telegraph_tween.finished
	if not is_inside_tree():
		return
	if dead or _state != State.TELEGRAPH:
		return

	_state = State.ATTACK
	if body_anim != null:
		body_anim.speed_scale = 1.35
		body_anim.self_modulate = Color(2.5, 0.9, 0.5, 1.0)

	var parried: bool = _execute_melee_hit()
	if parried or _state == State.STUNNED or dead:
		return

	await get_tree().create_timer(attack_active_duration).timeout
	if not is_inside_tree():
		return
	if dead or _state != State.ATTACK:
		return

	_parryable_window = false
	if body_anim != null:
		body_anim.speed_scale = 1.0
		body_anim.self_modulate = Color.WHITE
	_cooldown_timer = attack_cooldown
	_state = State.CHASE if _has_valid_target() else State.IDLE

func _execute_melee_hit() -> bool:
	if dead or not _has_valid_target():
		_parryable_window = false
		return false

	var dx: float = target.global_position.x - global_position.x
	var dy: float = absf(target.global_position.y - global_position.y)
	var in_front: bool = sign(dx) == _facing or absf(dx) <= 18.0
	if absf(dx) <= attack_range + 8.0 and dy <= 44.0 and in_front:
		var parry_ctrl: Node = target.get_node_or_null("ParryController")
		if parry_ctrl != null and parry_ctrl.has_method("try_parry_melee_attack"):
			if parry_ctrl.try_parry_melee_attack(self):
				return true
		_parryable_window = false
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)
	else:
		_parryable_window = false
	return false

func is_parryable_attack_active() -> bool:
	return not dead and _parryable_window and (_state == State.TELEGRAPH or _state == State.ATTACK)

func on_parried() -> void:
	if dead:
		return
	_cancel_telegraph()
	_parryable_window = false
	_state = State.STUNNED
	_state_timer = stun_duration
	velocity.x = -_facing * 45.0
	if body_anim != null:
		body_anim.speed_scale = 1.0
		body_anim.self_modulate = stun_color
	_play_animation("hit")

func take_damage(amount: int = 1) -> void:
	if dead:
		return

	health = max(0, health - amount)
	_cancel_telegraph()
	_parryable_window = false

	if health <= 0:
		die()
		return

	if _state != State.STUNNED:
		_state = State.HURT
		_state_timer = 0.28
	if body_anim != null:
		body_anim.speed_scale = 1.0
		body_anim.self_modulate = Color(2.2, 2.2, 2.2, 1.0)
	_play_animation("hit")

func die() -> void:
	if dead:
		return

	dead = true
	_state = State.DEAD
	_cancel_telegraph()
	_parryable_window = false
	remove_from_group("enemies")
	velocity = Vector2.ZERO
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if detection_area != null:
		detection_area.set_deferred("monitoring", false)
	set_physics_process(false)
	if body_anim != null:
		body_anim.speed_scale = 1.0
		body_anim.self_modulate = Color.WHITE
	_spawn_chi_orb()
	_play_animation("die")
	died.emit()
	if body_anim != null and body_anim.sprite_frames != null and body_anim.sprite_frames.has_animation("die"):
		await body_anim.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	queue_free()

func _spawn_chi_orb() -> void:
	if CHI_ORB_SCENE:
		var orb: Node = CHI_ORB_SCENE.instantiate()
		orb.global_position = global_position + Vector2(0.0, -12.0)
		get_parent().call_deferred("add_child", orb)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if dead:
		return
	if body is Player:
		target = body
		if _state == State.IDLE:
			_state = State.CHASE

func _on_detection_area_body_exited(body: Node2D) -> void:
	if dead:
		return
	if body == target:
		target = null

func _play_animation(animation: String) -> void:
	if body_anim != null and body_anim.sprite_frames != null and body_anim.sprite_frames.has_animation(animation):
		if body_anim.animation != animation or not body_anim.is_playing():
			body_anim.play(animation)

class_name Player
extends CharacterBody2D

signal player_died
signal died

@onready var weapon: Cannon = $"%Weapon"
@onready var body_animations: AnimationPlayer = $BodyAnimations
@onready var body_pivot: Node2D = $BodyPivot
@onready var melee_attack: MeleeAttack = $WeaponContainer/MeleeAttack
@onready var heavy_cannon: HeavyCannonController = $WeaponContainer/HeavyCannon
@onready var parry_controller: ParryController = $ParryController

@export_group("Movement")
@export var acceleration: float = 950.0
@export var h_speed_limit: float = 150.0
@export var friction_weight: float = 10.0
@export var skid_acceleration: float = 2400.0

@export_group("Jump & Gravity")
@export var jump_height: float = 70.0
@export var jump_rise_time: float = 0.35
@export var jump_fall_time: float = 0.28 
@export var jump_cut_multiplier: float = 0.45
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12
@export var air_acceleration_ratio: float = 0.75

@export_group("Physics Interaction")
@export var push_force: float = 120.0

@export_group("Abilities")
@export var can_melee: bool = true
@export var can_fireball: bool = true
@export var can_heavy_blast: bool = true
@export var can_parry: bool = true
@export var can_redirect: bool = false

var projectile_container: Node
var h_movement_direction: int = 0
var jump: bool = false
var dead: bool = false

var _gravity_rise: float = 0.0
var _gravity_fall: float = 0.0
var _jump_velocity: float = 0.0

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false
var _is_rising: bool = false

# Configura el estado inicial del jugador.
func _ready() -> void:
	_compute_jump_physics()
	initialize()

func _compute_jump_physics() -> void:
	_gravity_rise  = (2.0 * jump_height) / (jump_rise_time  * jump_rise_time)
	_gravity_fall  = (2.0 * jump_height) / (jump_fall_time  * jump_fall_time)
	_jump_velocity = (2.0 * jump_height) / jump_rise_time

# Establece el contenedor para los proyectiles del arma.
func initialize(p_projectile_container: Node = get_parent()) -> void:
	assert(p_projectile_container != null, "projectile_container cannot be null")
	self.projectile_container = p_projectile_container
	weapon.projectile_container = p_projectile_container
	if heavy_cannon:
		heavy_cannon.projectile_container = p_projectile_container
	elif has_node("WeaponContainer/HeavyCannon"):
		$WeaponContainer/HeavyCannon.projectile_container = p_projectile_container
	body_animations.play("idle")

# Procesa el movimiento y las colisiones del jugador.
func _physics_process(delta: float) -> void:
	_process_input()

	# ── Timers ──────────────────────────────────────────────────────────────
	var on_floor := is_on_floor()

	if on_floor:
		_coyote_timer = coyote_time
	elif _coyote_timer > 0.0:
		_coyote_timer -= delta

	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	# ── Horizontal movement ─────────────────────────────────────────────────
	if not dead and h_movement_direction != 0:
		var is_skidding: bool = on_floor and velocity.x != 0.0 and sign(velocity.x) != h_movement_direction
		var current_accel: float
		if is_skidding:
			current_accel = skid_acceleration
		elif on_floor:
			current_accel = acceleration
		else:
			current_accel = acceleration * air_acceleration_ratio

		velocity.x = clamp(
			velocity.x + (h_movement_direction * current_accel * delta),
			-h_speed_limit,
			h_speed_limit
		)
		if h_movement_direction > 0:
			body_pivot.scale.x = 1
		elif h_movement_direction < 0:
			body_pivot.scale.x = -1
	else:
		var friction := friction_weight if on_floor else friction_weight * 0.35
		velocity.x = move_toward(velocity.x, 0.0, friction * 100.0 * delta)

	# ── Jump ─────────────────────────────────────────
	var can_jump := _coyote_timer > 0.0
	if _jump_buffer_timer > 0.0 and can_jump:
		velocity.y    = -_jump_velocity
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		_is_rising = true

	# ── Asymmetric gravity ──────────────────────────────────────────────────
	var g := _gravity_rise if velocity.y < 0.0 else _gravity_fall
	velocity.y += g * delta

	if on_floor and velocity.y > 0.0:
		velocity.y = 0.0
		_is_rising = false

	_was_on_floor = on_floor
	move_and_slide()

	# ── RigidBody2D push  ──────────────────────────
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is RigidBody2D:
			var rigid_body: RigidBody2D = collider as RigidBody2D
			var collision_normal: Vector2 = collision.get_normal()
			var velocity_alignment: float = float(
				collision_normal.dot(-velocity.normalized()) > 0.0
			)
			if velocity_alignment > 0.0 and not velocity.is_zero_approx():
				rigid_body.apply_central_impulse(
					-collision_normal.slerp(-velocity.normalized(), 0.5)
					* push_force * velocity_alignment
				)

	if not dead:
		_update_animation()

# Procesa la entrada del usuario.
func _process_input() -> void:
	if dead:
		jump = false
		h_movement_direction = 0
		return

	# ── Helpers para exclusión mutua ────────────────────────────────────────
	var _melee_busy   : bool = can_melee   and melee_attack  != null and melee_attack.is_attacking()
	var _fireball_busy: bool = can_fireball and weapon        != null and not weapon.is_ready()
	var _heavy_busy   : bool = can_heavy_blast and heavy_cannon != null and heavy_cannon.is_charging()
	var _any_attack_busy: bool = _melee_busy or _fireball_busy or _heavy_busy

	# Melee — bloqueado si hay cualquier otro ataque activo
	if Input.is_action_just_pressed("attack_melee") and can_melee and not _fireball_busy and not _heavy_busy:
		var mouse_offset_x: float = get_global_mouse_position().x - global_position.x
		var facing_dir: float = sign(mouse_offset_x) if mouse_offset_x != 0.0 else body_pivot.scale.x
		if facing_dir == 0.0:
			facing_dir = 1.0
		body_pivot.scale.x = facing_dir
		melee_attack.attack(facing_dir)

	# Fireball — bloqueada si el cañón pesado está cargando o el melee está activo
	if Input.is_action_just_pressed("attack_1") and can_fireball and not _heavy_busy and not _melee_busy:
		weapon.fire()

	weapon.process_input()

	# Cañón pesado — bloqueado si el fireball está en cooldown o el melee está activo
	if can_heavy_blast and heavy_cannon:
		if not _fireball_busy and not _melee_busy:
			heavy_cannon.process_input()

	# Jump buffer: queue on press
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

	# Variable jump cut: release early while rising → cut velocity
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	jump = Input.is_action_just_pressed("jump")

	h_movement_direction = int(
		Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")
	)

	if can_parry and parry_controller != null:
		if Input.is_action_just_pressed("parry"):
			parry_controller.try_parry(false)
		elif Input.is_action_just_pressed("parry_redirect"):
			if can_redirect:
				parry_controller.try_parry(true)

# Maneja la muerte del jugador.
func die() -> void:
	if dead:
		return 
	
	dead = true
	collision_layer = 0 
	collision_mask = 1 
	if weapon:
		weapon.die()
		weapon = null
	if melee_attack:
		melee_attack.die()
		melee_attack = null
	if heavy_cannon:
		heavy_cannon.die()
		heavy_cannon = null
	if parry_controller:
		parry_controller.die()
		parry_controller = null
	_play_animation("die")
	await body_animations.animation_finished
	died.emit()
	player_died.emit()

# Actualiza la animacion segun el estado de movimiento.
func _update_animation() -> void:
	if not is_on_floor():
		_play_animation("jump")
	elif h_movement_direction != 0:
		_play_animation("walk")
	else:
		_play_animation("idle")

# Reproduce una animacion del cuerpo.
func _play_animation(animation: String) -> void:
	if body_animations.has_animation(animation):
		body_animations.play(animation)

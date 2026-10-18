class_name Player
extends CharacterBody2D

signal player_died
signal health_changed(current_hp: int, max_hp: int)
signal chi_changed(current_chi: int, max_chi: int)
signal fireball_unlocked

@onready var weapon: FireballController = $"%Weapon"
@onready var body_animations: AnimationPlayer = $BodyAnimations
@onready var body_pivot: Node2D = $BodyPivot
@onready var body_sprite: Sprite2D = $BodyPivot/Body
@onready var melee_attack: MeleeAttack = $WeaponContainer/MeleeAttack
@onready var lightning_controller: LightningController = $WeaponContainer/LightningAttack
@onready var parry_controller: ParryController = $ParryController

var _sprite_base_pos: Vector2 = Vector2.ZERO
var _sprite_half_height: float = 0.0

@export_group("Stats")
@export var max_health: int = 2
@export var max_chi: int = 100

@export_group("Movement")
@export var acceleration: float = 950.0
@export var h_speed_limit: float = 150.0
@export var friction_weight: float = 10.0
@export var skid_acceleration: float = 2400.0
@export var skid_speed_threshold: float = 95.0
@export var skid_stop_threshold: float = 25.0

@export_group("Jump & Gravity")
@export var jump_height: float = 90.0
@export var jump_rise_time: float = 0.38
@export var jump_fall_time: float = 0.30
@export var jump_cut_multiplier: float = 0.45
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12
@export var air_acceleration_ratio: float = 0.75
@export var max_fall_speed: float = 680.0
@export var speed_jump_bonus: float = 45.0
@export var apex_velocity_threshold: float = 45.0
@export var apex_gravity_multiplier: float = 0.50
@export var apex_acceleration_multiplier: float = 1.20
@export var corner_correction_px: int = 4

@export_group("Game Feel & Juice")
@export var jump_stretch_scale: Vector2 = Vector2(0.78, 1.24)
@export var land_squash_max_scale: Vector2 = Vector2(1.28, 0.74)
@export var squash_recovery_speed: float = 11.0
@export var max_run_tilt_degrees: float = 6.0
@export var skid_tilt_degrees: float = 9.0

@export_group("Physics Interaction")
@export var push_force: float = 120.0

@export_group("Abilities")
@export var can_melee: bool = true
@export var can_fireball: bool = false
@export var can_lightning: bool = false
@export var can_parry: bool = true
@export var can_redirect: bool = false

@export_group("Combat")
@export var attack_lock_time: float = 0.18

var health: int = 2
var chi: int = 0
var _is_invulnerable: bool = false
var _invulnerability_timer: float = 0.0

var projectile_container: Node
var h_movement_direction: int = 0
var jump: bool = false
var dead: bool = false

var _gravity_rise: float = 0.0
var _gravity_fall: float = 0.0
var _jump_velocity: float = 0.0

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _cast_lock_timer: float = 0.0
var _was_on_floor: bool = false
var _pre_land_velocity_y: float = 0.0
var _is_skidding_active: bool = false
var _dust_particles: Array[Dictionary] = []
var _skid_dust_timer: float = 0.0

# Configura el estado inicial del jugador.
func _ready() -> void:
	_cache_sprite_metrics()
	_compute_jump_physics()
	initialize()
	health = max_health
	chi = 0
	health_changed.emit(health, max_health)
	chi_changed.emit(chi, max_chi)

# Lee la posicion del sprite desde la escena. Convencion: el borde inferior
# del sprite queda sobre el origen del Player (los pies), por lo que la mitad
# del alto equivale a la distancia vertical del centro del sprite a los pies.
func _cache_sprite_metrics() -> void:
	if body_sprite == null:
		return
	_sprite_base_pos = body_sprite.position
	_sprite_half_height = absf(_sprite_base_pos.y)

func _compute_jump_physics() -> void:
	_gravity_rise  = (2.0 * jump_height) / (jump_rise_time  * jump_rise_time)
	_gravity_fall  = (2.0 * jump_height) / (jump_fall_time  * jump_fall_time)
	_jump_velocity = (2.0 * jump_height) / jump_rise_time

# Establece el contenedor para los proyectiles del arma.
func initialize(p_projectile_container: Node = get_parent()) -> void:
	assert(p_projectile_container != null, "projectile_container cannot be null")
	self.projectile_container = p_projectile_container
	weapon.projectile_container = p_projectile_container
	if lightning_controller:
		lightning_controller.projectile_container = p_projectile_container
	body_animations.play("idle")

# Procesa el movimiento y las colisiones del jugador.
func _physics_process(delta: float) -> void:
	if _cast_lock_timer > 0.0:
		_cast_lock_timer -= delta

	if _is_invulnerable:
		_invulnerability_timer -= delta
		if body_pivot:
			body_pivot.modulate.a = 0.35 if int(_invulnerability_timer * 12.0) % 2 == 0 else 1.0
		if _invulnerability_timer <= 0.0:
			_is_invulnerable = false
			if body_pivot:
				body_pivot.modulate.a = 1.0

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
		if is_skidding and absf(velocity.x) < skid_stop_threshold:
			velocity.x = 0.0
			is_skidding = false
		_is_skidding_active = is_skidding and absf(velocity.x) >= skid_speed_threshold

		var is_in_apex: bool = not on_floor and Input.is_action_pressed("jump") and absf(velocity.y) <= apex_velocity_threshold
		var current_accel: float
		if is_skidding:
			current_accel = skid_acceleration
		elif on_floor:
			current_accel = acceleration
		else:
			var air_accel_mult: float = apex_acceleration_multiplier if is_in_apex else 1.0
			current_accel = acceleration * air_acceleration_ratio * air_accel_mult

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
		_is_skidding_active = false
		var friction := friction_weight if on_floor else friction_weight * 0.35
		velocity.x = move_toward(velocity.x, 0.0, friction * 100.0 * delta)

	if _is_skidding_active and on_floor and not dead:
		_skid_dust_timer -= delta
		if _skid_dust_timer <= 0.0:
			_skid_dust_timer = 0.08
			_spawn_skid_dust()
	else:
		_skid_dust_timer = 0.0

	# ── Jump ─────────────────────────────────────────
	var can_jump := _coyote_timer > 0.0
	if _jump_buffer_timer > 0.0 and can_jump:
		var speed_ratio: float = absf(velocity.x) / maxf(h_speed_limit, 1.0)
		var extra_jump: float = speed_ratio * speed_jump_bonus
		velocity.y    = -(_jump_velocity + extra_jump)
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		if not Input.is_action_pressed("jump"):
			velocity.y *= jump_cut_multiplier
		_apply_jump_juice(on_floor)

	# ── Asymmetric gravity & Apex Hang ──────────────────────────────────────
	var is_in_apex_grav: bool = not on_floor and Input.is_action_pressed("jump") and absf(velocity.y) <= apex_velocity_threshold
	var g := _gravity_rise if velocity.y < 0.0 else _gravity_fall
	if is_in_apex_grav:
		g *= apex_gravity_multiplier
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)

	if not on_floor:
		_pre_land_velocity_y = velocity.y
	else:
		_pre_land_velocity_y = 0.0

	if on_floor and velocity.y > 0.0:
		velocity.y = 0.0

	# ── Corner Correction ────────────────────────────
	if velocity.y < 0.0:
		_check_corner_correction(delta)

	_was_on_floor = on_floor
	move_and_slide()

	# ── Landing Juice ────────────────────────────────
	var just_landed: bool = not _was_on_floor and is_on_floor()
	if just_landed:
		_apply_landing_juice()

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

	_update_visual_juice(delta, on_floor)
	_update_dust_particles(delta)

	if not dead:
		_update_animation()

# Procesa la entrada del usuario.
func _process_input() -> void:
	if dead:
		jump = false
		h_movement_direction = 0
		return

	# ── Exclusión mutua entre ataques ───────────────────────────────────────
	var melee_busy: bool = can_melee and melee_attack != null and melee_attack.is_attacking()
	var lightning_busy: bool = can_lightning and lightning_controller != null and lightning_controller.is_charging()
	var cast_locked: bool = _cast_lock_timer > 0.0

	# Melee — blocked while charging lightning or during the cast lock
	if Input.is_action_just_pressed("attack_melee") and can_melee and not lightning_busy and not cast_locked:
		var mouse_offset_x: float = get_global_mouse_position().x - global_position.x
		var facing_dir: float = sign(mouse_offset_x) if mouse_offset_x != 0.0 else body_pivot.scale.x
		if facing_dir == 0.0:
			facing_dir = 1.0
		body_pivot.scale.x = facing_dir
		melee_attack.attack(facing_dir)
		melee_busy = melee_attack.is_attacking()

	# Fireball — blocked while melee is active, while charging lightning,
	# or during the cast lock. Only locks the other attacks if it actually fired.
	if Input.is_action_just_pressed("attack_1") and can_fireball and not lightning_busy and not melee_busy and not cast_locked:
		if weapon.is_ready():
			weapon.fire()
			_cast_lock_timer = attack_lock_time
			cast_locked = true

	weapon.process_input()

	# Lightning attack — blocked while melee is active or during the cast lock.
	if can_lightning and lightning_controller:
		if not melee_busy and not cast_locked:
			lightning_controller.process_input()

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

# Recibe danio progresivo con 1.0s de invulnerabilidad temporal (i-frames).
func take_damage(amount: int = 1) -> void:
	if dead or _is_invulnerable:
		return
	
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	
	if health <= 0:
		die()
	else:
		_is_invulnerable = true
		_invulnerability_timer = 1.0

# Recolecta energia Chi y desbloquea la Bola de Fuego al alcanzar 100 puntos.
func collect_chi(amount: int) -> void:
	if dead:
		return
	
	chi = min(max_chi, chi + amount)
	chi_changed.emit(chi, max_chi)
	
	if chi >= max_chi and not can_fireball:
		can_fireball = true
		fireball_unlocked.emit()

# Maneja la muerte del jugador.
func die() -> void:
	if dead:
		return 
	
	dead = true
	_is_invulnerable = false
	_dust_particles.clear()
	queue_redraw()
	if body_sprite:
		body_sprite.scale = Vector2.ONE
		body_sprite.rotation = 0.0
		body_sprite.position = _sprite_base_pos
	if body_animations:
		body_animations.speed_scale = 1.0
	if body_pivot:
		body_pivot.modulate.a = 1.0
	collision_layer = 0 
	collision_mask = 1 
	if weapon:
		weapon.die()
		weapon = null
	if melee_attack:
		melee_attack.die()
		melee_attack = null
	if lightning_controller:
		lightning_controller.die()
		lightning_controller = null
	if parry_controller:
		parry_controller.die()
		parry_controller = null
	var wait_for_animation: bool = body_animations != null \
		and body_animations.has_animation("die") \
		and body_animations.get_animation("die").loop_mode == Animation.LOOP_NONE
	if wait_for_animation:
		_play_animation("die")
		await body_animations.animation_finished
	else:
		await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	player_died.emit()

# Actualiza la animacion segun el estado de movimiento y modula la cadencia de caminata.
func _update_animation() -> void:
	if not is_on_floor():
		body_animations.speed_scale = 1.0
		_play_animation("jump")
	elif h_movement_direction != 0:
		var speed_ratio: float = clampf(absf(velocity.x) / maxf(h_speed_limit, 1.0), 0.0, 1.0)
		body_animations.speed_scale = lerpf(0.75, 1.35, speed_ratio)
		_play_animation("walk")
	else:
		body_animations.speed_scale = 1.0
		_play_animation("idle")

# Reproduce una animacion del cuerpo.
func _play_animation(animation: String) -> void:
	if body_animations.has_animation(animation):
		body_animations.play(animation)

# Evalua colisiones superiores y redondea esquinas si el hueco esta a pocos pixeles.
func _check_corner_correction(delta: float) -> void:
	if corner_correction_px <= 0:
		return
	var motion := Vector2(0.0, velocity.y * delta)
	if not test_move(global_transform, motion):
		return
	
	for step: int in range(1, corner_correction_px + 1):
		var left_xform := Transform2D(0.0, global_position + Vector2(-float(step), 0.0))
		if not test_move(left_xform, motion):
			global_position.x -= float(step)
			return
		
		var right_xform := Transform2D(0.0, global_position + Vector2(float(step), 0.0))
		if not test_move(right_xform, motion):
			global_position.x += float(step)
			return

# Aplica estiramiento visual y polvo al despegar.
func _apply_jump_juice(was_on_ground: bool) -> void:
	if body_sprite:
		body_sprite.scale = jump_stretch_scale
		body_sprite.position.y = -_sprite_half_height * body_sprite.scale.y
	if was_on_ground:
		_spawn_jump_dust()

# Aplica compresion de impacto al aterrizar y polvo si la caida fue fuerte.
func _apply_landing_juice() -> void:
	var impact_ratio: float = clampf(_pre_land_velocity_y / max_fall_speed, 0.15, 1.0)
	if body_sprite:
		body_sprite.scale = Vector2.ONE.lerp(land_squash_max_scale, impact_ratio)
		body_sprite.position.y = -_sprite_half_height * body_sprite.scale.y
	if _pre_land_velocity_y >= max_fall_speed * 0.40:
		_spawn_hard_landing_dust()

# Recupera la escala del sprite hacia Vector2.ONE, ajusta posicion y calcula inclinacion.
func _update_visual_juice(delta: float, on_floor_now: bool) -> void:
	if not body_sprite or dead:
		return
	
	body_sprite.scale = body_sprite.scale.lerp(Vector2.ONE, clampf(squash_recovery_speed * delta, 0.0, 1.0))
	body_sprite.position.y = -_sprite_half_height * body_sprite.scale.y
	body_sprite.position.x = _sprite_base_pos.x
	
	var target_tilt: float = 0.0
	if on_floor_now:
		if _is_skidding_active:
			target_tilt = -sign(velocity.x) * deg_to_rad(skid_tilt_degrees)
		elif h_movement_direction != 0 and absf(velocity.x) > 10.0:
			var speed_ratio: float = clampf(absf(velocity.x) / h_speed_limit, 0.0, 1.0)
			target_tilt = sign(velocity.x) * speed_ratio * deg_to_rad(max_run_tilt_degrees)
	
	body_sprite.rotation = lerp_angle(body_sprite.rotation, target_tilt, clampf(14.0 * delta, 0.0, 1.0))

func _spawn_jump_dust() -> void:
	var origin := Vector2(-5.0, 0.0)
	for i: int in range(5):
		var vel := Vector2(randf_range(-35.0, 35.0), randf_range(-8.0, -18.0))
		_add_dust_particle(origin + Vector2(randf_range(-4.0, 4.0), 0.0), vel, randf_range(0.20, 0.32), randf_range(1.5, 2.5))

func _spawn_skid_dust() -> void:
	var dir: float = sign(velocity.x)
	if dir == 0.0:
		dir = 1.0
	var origin := Vector2(-5.0 + dir * 6.0, 0.0)
	var vel := Vector2(dir * randf_range(15.0, 45.0), randf_range(-6.0, -14.0))
	_add_dust_particle(origin, vel, randf_range(0.18, 0.28), randf_range(1.2, 2.2))

func _spawn_hard_landing_dust() -> void:
	var origin := Vector2(-5.0, 0.0)
	for i: int in range(7):
		var dir: float = -1.0 if i % 2 == 0 else 1.0
		var vel := Vector2(dir * randf_range(25.0, 65.0), randf_range(-5.0, -16.0))
		_add_dust_particle(origin + Vector2(dir * randf_range(1.0, 6.0), 0.0), vel, randf_range(0.22, 0.35), randf_range(1.6, 2.8))

func _add_dust_particle(pos: Vector2, vel: Vector2, lifetime: float, radius: float) -> void:
	if _dust_particles.size() >= 30:
		_dust_particles.pop_front()
	_dust_particles.append({
		"pos": pos,
		"vel": vel,
		"lifetime": lifetime,
		"initial_lifetime": lifetime,
		"radius": radius,
		"color": Color(0.88, 0.88, 0.94, 0.65)
	})

func _update_dust_particles(delta: float) -> void:
	var had_particles: bool = not _dust_particles.is_empty()
	var write_idx: int = 0
	for i: int in range(_dust_particles.size()):
		var p: Dictionary = _dust_particles[i]
		p["lifetime"] -= delta
		if p["lifetime"] > 0.0:
			p["pos"] += p["vel"] * delta
			_dust_particles[write_idx] = p
			write_idx += 1
	_dust_particles.resize(write_idx)
	if had_particles or not _dust_particles.is_empty():
		queue_redraw()

func _draw() -> void:
	for p: Dictionary in _dust_particles:
		var alpha: float = clampf(p["lifetime"] / p["initial_lifetime"], 0.0, 1.0) * 0.65
		var col: Color = p["color"]
		col.a = alpha
		draw_circle(p["pos"], p["radius"], col)

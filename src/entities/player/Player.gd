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
@export var acceleration: float = 3750.0
@export var h_speed_limit: float = 600.0
@export var friction_weight: float = 6.25

@export_group("Jump & Gravity")
@export var jump_speed: float = 500.0
@export var gravity: float = 625.0 

@export_group("Physics Interaction")
@export var push_force: float = 80.0

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

# Configura el estado inicial del jugador.
func _ready() -> void:
	initialize()

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
	
	if !dead && h_movement_direction != 0:
		velocity.x = clamp(
			velocity.x + (h_movement_direction * acceleration * delta),
			-h_speed_limit,
			h_speed_limit
		)
		if h_movement_direction > 0:
			body_pivot.scale.x = 1
		elif h_movement_direction < 0:
			body_pivot.scale.x = -1
	else:
		velocity.x = move_toward(velocity.x, 0, friction_weight * 100 * delta)
		
	if jump and is_on_floor():
		velocity.y = -jump_speed

	velocity.y += gravity * delta
	
	move_and_slide()
	
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is RigidBody2D:
			var rigid_body: RigidBody2D = collider as RigidBody2D
			var collision_normal: Vector2 = collision.get_normal()
			var velocity_alignment: float = float(
				collision_normal.dot(-velocity.normalized()) > 0.0
			)
			rigid_body.apply_central_impulse(
				-collision_normal.slerp(-velocity.normalized(), 0.5) * push_force * velocity_alignment
			)

	if not dead:
		_update_animation()

# Procesa la entrada del usuario.
func _process_input() -> void:
	if dead:
		jump = false
		h_movement_direction = 0 
		return
	
	if Input.is_action_just_pressed("attack_melee") and can_melee:
		var mouse_offset_x: float = get_global_mouse_position().x - global_position.x
		var facing_dir: float = sign(mouse_offset_x) if mouse_offset_x != 0.0 else body_pivot.scale.x
		if facing_dir == 0.0:
			facing_dir = 1.0
		body_pivot.scale.x = facing_dir
		melee_attack.attack(facing_dir)
	
	if Input.is_action_just_pressed("attack_1") and can_fireball:
		weapon.fire()

	jump = Input.is_action_just_pressed("jump")

	h_movement_direction = int(
		Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")
	)
	
	weapon.process_input()
	if can_heavy_blast and heavy_cannon:
		heavy_cannon.process_input()
		
	if can_parry:
		if Input.is_action_just_pressed("parry") or Input.is_action_just_pressed("parry_redirect"):
			parry_controller.try_parry(can_redirect)

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

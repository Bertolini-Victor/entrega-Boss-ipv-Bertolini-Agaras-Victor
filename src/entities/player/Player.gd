class_name Player
extends CharacterBody2D

signal player_died

@onready var weapon: Node = $"%Weapon"
@onready var body_animations: AnimationPlayer = $BodyAnimations
@onready var body_pivot: Node2D = $BodyPivot

@export_group("Movement")
@export var acceleration: float = 3750.0
@export var h_speed_limit: float = 600.0
@export var friction_weight: float = 6.25

@export_group("Jump & Gravity")
@export var jump_speed: float = 500.0
@export var gravity: float = 625.0 

@export_group("Physics Interaction")
@export var push_force: float = 80.0

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
		velocity.y -= jump_speed

	velocity.y += gravity * delta
	
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_collider() is RigidBody2D:
			var collision_normal: Vector2 = collision.get_normal()
			var velocity_alignment: float = float(
				collision_normal.dot(-velocity.normalized()) > 0.0
			)
			collision.get_collider().apply_central_impulse(
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
	
	if Input.is_action_just_pressed("attack_1"):
		weapon.fire()

	jump = Input.is_action_just_pressed("jump")

	h_movement_direction = int(
		Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")
	)
	
	weapon.process_input()

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
	_play_animation("die")
	await body_animations.animation_finished
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

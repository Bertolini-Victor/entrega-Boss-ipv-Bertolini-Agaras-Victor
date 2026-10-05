extends CharacterBody2D
class_name Player

signal player_died

@onready var weapon: Node = $"%Weapon"
@onready var body_animations: AnimationPlayer = $BodyAnimations
@onready var body_pivot: Node2D = $BodyPivot
@export var ACCELERATION: float = 3750.0
@export var H_SPEED_LIMIT: float = 600.0
@export var jump_speed: int = 500
@export var FRICTION_WEIGHT: float = 6.25
@export var gravity: int = 625
@export var push_force: float = 80.0

var projectile_container: Node
var h_movement_direction: int = 0
var jump: bool = false
var dead: bool = false

func _ready() -> void:
	initialize()

func initialize(projectile_container: Node = get_parent()) -> void:
	self.projectile_container = projectile_container
	weapon.projectile_container = projectile_container
	body_animations.play("idle")

func _physics_process(delta: float) -> void:
	_process_input()
	
	if !dead && h_movement_direction != 0:
		velocity.x = clamp(
			velocity.x + (h_movement_direction * ACCELERATION * delta),
			-H_SPEED_LIMIT,
			H_SPEED_LIMIT
		)
		body_pivot.scale.x = 1 - 2 * float(h_movement_direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION_WEIGHT * 100 * delta)
		
	if jump and is_on_floor():
		velocity.y -= jump_speed

	velocity.y += gravity * delta
	
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
	move_and_slide()
	if not dead:
		_update_animation()

func _process_input() -> void:
	if dead:
		jump = false
		h_movement_direction = 0 
		return
	
	if Input.is_action_just_pressed("attack_1"):
		if projectile_container == null:
			projectile_container = get_parent()
		if weapon.projectile_container == null:
			weapon.projectile_container = projectile_container
		weapon.fire()

	jump = Input.is_action_just_pressed("jump")

	h_movement_direction = int(
		Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")
	)
	
	weapon.process_input()

func die():
	if dead:
		return 
	
	dead = true
	collision_layer = 0 
	collision_mask = 1 
	weapon.die()
	_play_animation("die")
	await body_animations.animation_finished
	player_died.emit()

func _update_animation() -> void:
	if not is_on_floor():
		_play_animation("jump")
	elif h_movement_direction != 0:
		_play_animation("walk")
	else:
		_play_animation("idle")

func _play_animation(animation: String) -> void:
	if body_animations.has_animation(animation):
		body_animations.play(animation)

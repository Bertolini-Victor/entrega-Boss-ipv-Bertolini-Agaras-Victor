class_name Projectile
extends Node2D

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var hitbox: Area2D = $Hitbox
@onready var projectile_animations: AnimationPlayer = $ProjectileAnimations
@export var velocity_speed: float = 300.0

var direction: Vector2

# Configura la posicion inicial y direccion del proyectil.
func initialize(spawn_position: Vector2, p_direction: Vector2) -> void:
	self.direction = p_direction
	global_position = spawn_position
	rotation = direction.angle()
	
	lifetime_timer.start()  
	
	projectile_animations.play("fire_start")
	projectile_animations.queue("fire_loop")

# Mueve el proyectil en cada frame.
func _physics_process(delta: float) -> void:
	var movement: Vector2 = direction * velocity_speed * delta
	global_position += movement

# Callback al expirar el tiempo de vida.
func _on_lifetime_timer_timeout() -> void:
	remove()

# Detiene el proyectil y reproduce la animacion de impacto.
func remove() -> void:
	lifetime_timer.stop() 
	
	hitbox.set_deferred("collision_mask", 0) 
	set_physics_process(false)
	projectile_animations.play("hit")
	
	await projectile_animations.animation_finished
	queue_free()

# Maneja las colisiones con otros cuerpos.
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
		remove()
	elif body is StaticBody2D or body is TileMapLayer or body is RigidBody2D: 
		remove() 

extends Node2D

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var hitbox: Area2D = $Hitbox
@onready var projectile_animations: AnimationPlayer = $ProjectileAnimations
@export var VELOCITY: float = 900.0

var direction: Vector2


func initialize(spawn_position: Vector2, direction: Vector2) -> void:
	self.direction = direction
	global_position = spawn_position
	rotation = direction.angle()
	
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	lifetime_timer.start()
	
	projectile_animations.play("fire_start")
	projectile_animations.queue("fire_loop")


func _physics_process(delta: float) -> void:
	position += direction * VELOCITY * delta


func _on_lifetime_timer_timeout() -> void:
	remove()

func remove() -> void:
	lifetime_timer.stop() 
	
	hitbox.set_deferred("collision_mask", 0) 
	set_physics_process(false)
	projectile_animations.play("hit")
	
	await projectile_animations.animation_finished
	queue_free()

func _remove() -> void:
	pass

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
		remove()
	elif body is StaticBody2D or body is TileMapLayer or body is RigidBody2D: 
		remove() 

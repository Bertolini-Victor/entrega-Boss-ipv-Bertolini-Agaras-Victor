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
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	lifetime_timer.start()
	projectile_animations.play("fire_loop")


func _physics_process(delta: float) -> void:
	position += direction * VELOCITY * delta


func _on_lifetime_timer_timeout() -> void:
	remove()


func remove() -> void:
	hitbox.collision_mask = 0
	set_physics_process(false)
	projectile_animations.play("hit")


func _remove() -> void:
	get_parent().remove_child(self)
	queue_free()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
		queue_free()
	elif body is StaticBody2D or body is TileMapLayer or body is RigidBody2D: 
		queue_free() 

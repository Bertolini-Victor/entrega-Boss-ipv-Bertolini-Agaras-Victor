class_name Projectile
extends Node2D

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var hitbox: Area2D = $Hitbox
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@export var velocity_speed: float = 300.0

var direction: Vector2 = Vector2.RIGHT:
	set(val):
		direction = val.normalized() if val != Vector2.ZERO else Vector2.ZERO
		velocity = direction * velocity_speed

var velocity: Vector2 = Vector2.ZERO
var _is_removing: bool = false

# Inicializa y reproduce la animación spawn encadenada a move.
func _ready() -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation("spawn"):
			animated_sprite.play("spawn")
			animated_sprite.animation_finished.connect(_on_spawn_animation_finished, CONNECT_ONE_SHOT)
		elif animated_sprite.sprite_frames.has_animation("move"):
			animated_sprite.play("move")

func _on_spawn_animation_finished() -> void:
	if not _is_removing and animated_sprite != null and animated_sprite.animation == "spawn":
		if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("move"):
			animated_sprite.play("move")

# Configura la posición inicial y dirección del proyectil.
func initialize(spawn_position: Vector2, p_direction: Vector2) -> void:
	self.direction = p_direction
	global_position = spawn_position
	rotation = direction.angle()
	
	if lifetime_timer:
		lifetime_timer.start()

# Mueve el proyectil en cada frame según su velocidad.
func _physics_process(delta: float) -> void:
	if _is_removing:
		return
	global_position += velocity * delta

# Desactiva las colisiones del proyectil de forma diferida.
func _disable_collisions() -> void:
	var col: CollisionShape2D = null
	if has_node("Hitbox/CollisionShape2D"):
		col = get_node("Hitbox/CollisionShape2D") as CollisionShape2D
	elif has_node("CollisionShape2D"):
		col = get_node("CollisionShape2D") as CollisionShape2D
	if col != null and is_instance_valid(col):
		col.set_deferred("disabled", true)
	if hitbox != null and is_instance_valid(hitbox):
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)

# Finaliza el ciclo de vida del proyectil deteniendo movimiento, desactivando colisiones y reproduciendo animación.
func _finish_projectile(anim_name: String) -> void:
	if _is_removing:
		return
	_is_removing = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	if lifetime_timer:
		lifetime_timer.stop()
	_disable_collisions()
	
	if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
		animated_sprite.play(anim_name)
	else:
		queue_free()

# Al impactar (colisión): detiene movimiento, desactiva colisiones y reproduce impact.
func on_impact() -> void:
	_finish_projectile("impact")

# Al vencer su tiempo de vida (sin chocar): detiene movimiento, desactiva colisiones y reproduce fade.
func on_fade() -> void:
	_finish_projectile("fade")

# Compatibilidad con llamadas heredadas a remove().
func remove() -> void:
	on_impact()

# Callback al expirar el tiempo de vida sin chocar.
func _on_lifetime_timer_timeout() -> void:
	on_fade()

# Maneja las colisiones con otros cuerpos físicos.
func _on_hitbox_body_entered(body: Node2D) -> void:
	if _is_removing:
		return
	if body.has_method("take_damage"):
		body.take_damage(1)
		on_impact()
	elif body.has_method("die"):
		body.die()
		on_impact()
	elif body is StaticBody2D or body is TileMapLayer or body is RigidBody2D: 
		on_impact()

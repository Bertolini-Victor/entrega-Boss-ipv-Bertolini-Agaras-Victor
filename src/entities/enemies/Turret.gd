class_name Turret
extends StaticBody2D

@onready var fire_position: Node2D = $FirePosition
@onready var fire_timer: Timer = $FireTimer
@onready var raycast: RayCast2D = $RayCast2D
@onready var body_anim: AnimatedSprite2D = $Body
@export var projectile_scene: PackedScene
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var target: Node2D
var projectile_container: Node
var dead: bool = false

# Inicializa el temporizador y la animacion.
func _ready() -> void:
	fire_timer.timeout.connect(fire)	
	_play_animation("idle")

# Configura la posicion y el contenedor de proyectiles.
func initialize(turret_pos: Vector2, p_projectile_container: Node) -> void:
	global_position = turret_pos
	self.projectile_container = p_projectile_container

# Instancia y dispara un proyectil hacia el objetivo.
func fire() -> void:
	if target == null:
		return
	
	var proj_instance: Node = projectile_scene.instantiate()
	if projectile_container == null:
		projectile_container = get_parent()
	projectile_container.add_child(proj_instance)
	proj_instance.initialize(
		fire_position.global_position,
		fire_position.global_position.direction_to(target.global_position)
	)
	fire_timer.start()

# Apunta al objetivo y controla el temporizador de disparo.
func _physics_process(_delta: float) -> void:
	if target == null:
		return
	
	raycast.set_target_position(raycast.to_local(target.global_position))
	if raycast.is_colliding() && raycast.get_collider() == target:
		if fire_timer.is_stopped():
			fire_timer.start()
	elif !fire_timer.is_stopped():
		fire_timer.stop()

# Desactiva la torreta y reproduce la animacion de muerte.
func die() -> void:
	if dead:
		return 
	
	dead = true
	fire_timer.stop()
	collision_shape.set_deferred("disabled", true)
	set_physics_process(false) 
	_play_animation("die")
	await body_anim.animation_finished
	queue_free()

# Detecta cuando un jugador entra en rango.
func _on_detection_area_body_entered(body: Node2D) -> void:
	if dead:
		return

	if body is Player and target == null:
		target = body

# Detecta cuando el jugador sale del rango.
func _on_detection_area_body_exited(body: Node2D) -> void:
	if dead:
		return

	if body == target:
		target = null
		fire_timer.stop()

# Reproduce una animacion especifica.
func _play_animation(animation: String) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)

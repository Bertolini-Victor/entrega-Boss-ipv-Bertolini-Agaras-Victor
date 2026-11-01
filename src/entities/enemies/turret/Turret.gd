class_name Turret
extends StaticBody2D

signal died

const CHI_ORB_SCENE: PackedScene = preload("res://src/environment/chi_orb/ChiOrb.tscn")
const IDLE_SCALE: Vector2 = Vector2(0.067, 0.067)
const ACTION_SCALE: Vector2 = Vector2(0.095, 0.095)

@onready var fire_position: Node2D = $FirePosition
@onready var fire_timer: Timer = $FireTimer
@onready var raycast: RayCast2D = $RayCast2D
@onready var sprite: AnimatedSprite2D = $Visuals
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var projectile_scene: PackedScene
@export var max_health: int = 2
@export var fire_cooldown: float = 2.0
@export var projectile_speed: float = 240.0
@export var telegraph_duration: float = 0.55

var attack_cooldown: float:
	get:
		return fire_cooldown
	set(val):
		fire_cooldown = val

var health: int = 2
var target: Node2D
var projectile_container: Node
var dead: bool = false
var _facing: float = -1.0
var _is_firing: bool = false

# Inicializa el temporizador y la animacion.
func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	if sprite != null:
		sprite.flip_h = _facing < 0.0
		sprite.animation_finished.connect(_on_animation_finished)
	fire_timer.wait_time = maxf(attack_cooldown, 0.1)
	fire_timer.timeout.connect(fire)
	_play_animation("idle")

func _process(_delta: float) -> void:
	if dead or sprite == null:
		return

	if target != null and is_instance_valid(target):
		var dx: float = target.global_position.x - global_position.x
		if absf(dx) > 2.0:
			_facing = 1.0 if dx >= 0.0 else -1.0
			sprite.flip_h = _facing < 0.0

# Configura la posicion y el contenedor de proyectiles.
func initialize(turret_pos: Vector2, p_projectile_container: Node) -> void:
	global_position = turret_pos
	self.projectile_container = p_projectile_container

# Punto de mira: centro del hitbox del objetivo si lo expone; si no, su posicion.
func _get_target_aim_point() -> Vector2:
	if target != null and target.has_method("get_aim_point"):
		return target.get_aim_point()
	return target.global_position

func _play_animation(anim_name: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(anim_name):
		return
	sprite.scale = IDLE_SCALE if anim_name == "idle" else ACTION_SCALE
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)

# Cancela el estado de disparo y regresa a idle si esta viva.
func _cancel_attack() -> void:
	_is_firing = false
	if not dead and sprite != null and sprite.animation != "die" and sprite.animation != "hurt":
		_play_animation("idle")

# Recibe danio: reduce la vida, ejecuta animacion de hurt o die.
func take_damage(amount: int = 1) -> void:
	if dead:
		return

	health = max(0, health - amount)
	if health <= 0:
		die()
	else:
		_is_firing = false
		_play_animation("hurt")

# Mantiene compatibilidad con llamadas directas de animacion de impacto.
func play_hit_anim() -> void:
	take_damage(1)

# Maneja la finalizacion de animaciones no ciclicas.
func _on_animation_finished() -> void:
	if dead or sprite == null:
		return

	match sprite.animation:
		"hurt":
			_play_animation("idle")
			if target != null and fire_timer.is_stopped():
				fire_timer.wait_time = maxf(attack_cooldown, 0.1)
				fire_timer.start()
		"fire":
			_is_firing = false
			_play_animation("idle")
			if target != null:
				fire_timer.wait_time = maxf(attack_cooldown, 0.1)
				fire_timer.start()

# Dispara la animacion de fuego e instancia el proyectil.
func fire() -> void:
	if dead or target == null or _is_firing or (sprite != null and sprite.animation == "hurt"):
		return

	_is_firing = true
	_play_animation("fire")

	# Espera el frame de disparo (frame 2 de 4 a 12 fps = ~0.16s)
	var shot_delay: float = 2.0 / 12.0
	await get_tree().create_timer(shot_delay).timeout

	if not is_inside_tree() or dead or not _is_firing or projectile_scene == null:
		return

	var proj_instance: Node = projectile_scene.instantiate()
	if "velocity_speed" in proj_instance:
		proj_instance.velocity_speed = projectile_speed
	elif "speed" in proj_instance:
		proj_instance.speed = projectile_speed
	if projectile_container == null:
		projectile_container = get_parent()
	projectile_container.add_child(proj_instance)
	proj_instance.initialize(
		fire_position.global_position,
		fire_position.global_position.direction_to(_get_target_aim_point())
	)

# Apunta al objetivo y controla el temporizador de disparo.
func _physics_process(_delta: float) -> void:
	if dead or target == null:
		return

	raycast.set_target_position(raycast.to_local(_get_target_aim_point()))
	raycast.force_raycast_update()
	if raycast.is_colliding() and raycast.get_collider() == target:
		if fire_timer.is_stopped() and not _is_firing and sprite != null and sprite.animation != "hurt":
			fire_timer.wait_time = maxf(attack_cooldown, 0.1)
			fire_timer.start()
	else:
		if not fire_timer.is_stopped():
			fire_timer.stop()
		if _is_firing and sprite != null and sprite.animation == "fire":
			_cancel_attack()

# Desactiva la torreta y reproduce la animacion de muerte.
func die() -> void:
	if dead:
		return

	dead = true
	_is_firing = false
	remove_from_group("enemies")
	fire_timer.stop()
	collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	set_process(false)
	_spawn_chi_orb()
	died.emit()

	if sprite != null:
		_play_animation("die")
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.25).timeout

	if not is_inside_tree():
		return
	queue_free()

func _spawn_chi_orb() -> void:
	if CHI_ORB_SCENE:
		var orb: Node = CHI_ORB_SCENE.instantiate()
		orb.global_position = global_position
		get_parent().call_deferred("add_child", orb)

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
		_cancel_attack()

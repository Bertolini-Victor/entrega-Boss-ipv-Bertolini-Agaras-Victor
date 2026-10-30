class_name Turret
extends StaticBody2D

signal died

const CHI_ORB_SCENE: PackedScene = preload("res://src/environment/chi_orb/ChiOrb.tscn")
const IDLE_SCALE: Vector2 = Vector2(0.095, 0.095)
const ACTION_SCALE: Vector2 = Vector2(0.117, 0.117)

@onready var fire_position: Node2D = $FirePosition
@onready var fire_timer: Timer = $FireTimer
@onready var raycast: RayCast2D = $RayCast2D
@onready var sprite: AnimatedSprite2D = $Visuals
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var projectile_scene: PackedScene
@export var attack_cooldown: float = 2.8
@export var telegraph_duration: float = 0.55
@export var telegraph_color: Color = Color(2.0, 0.5, 0.5, 1.0)

var target: Node2D
var projectile_container: Node
var dead: bool = false
var _facing: float = -1.0
var _is_telegraphing: bool = false
var _telegraph_tween: Tween = null
var _hit_tween: Tween = null

# Inicializa el temporizador y la animacion.
func _ready() -> void:
	add_to_group("enemies")
	if sprite != null:
		sprite.flip_h = _facing < 0.0
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

# Cancela el telegrafiado activo y restaura el estado visual original del sprite.
func _cancel_telegraph() -> void:
	_is_telegraphing = false
	if _telegraph_tween != null and _telegraph_tween.is_valid():
		_telegraph_tween.kill()
	_telegraph_tween = null
	if sprite != null:
		sprite.self_modulate = Color.WHITE
		sprite.rotation = 0.0
		sprite.speed_scale = 1.0
		_play_animation("idle")

func play_hit_anim() -> void:
	if sprite == null:
		return
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()

	sprite.self_modulate = Color(3.0, 3.0, 3.0)
	var shake_dir: float = 1.0 if randf() >= 0.5 else -1.0
	sprite.rotation = randf_range(0.10, 0.18) * shake_dir

	_hit_tween = create_tween()
	_hit_tween.set_parallel(true)
	_hit_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.2)
	_hit_tween.tween_property(sprite, "rotation", 0.0, 0.2)

# Ejecuta el telegrafiado visual con la animacion de ataque y dispara un proyectil hacia el objetivo.
func fire() -> void:
	if dead or target == null or _is_telegraphing:
		return

	_is_telegraphing = true
	var post_shot_duration: float = 0.24
	var total_duration: float = maxf(telegraph_duration + post_shot_duration, 0.2)

	if sprite != null:
		sprite.scale = ACTION_SCALE
		sprite.self_modulate = Color.WHITE
		sprite.frame = 0
		var base_fps: float = sprite.sprite_frames.get_animation_speed("attack")
		sprite.speed_scale = (4.0 / total_duration) / maxf(base_fps, 1.0)
		sprite.play("attack")

	if _telegraph_tween != null and _telegraph_tween.is_valid():
		_telegraph_tween.kill()
	_telegraph_tween = create_tween()
	if sprite != null:
		_telegraph_tween.tween_property(sprite, "self_modulate", telegraph_color, telegraph_duration)
	else:
		_telegraph_tween.tween_interval(telegraph_duration)

	await _telegraph_tween.finished
	if not is_inside_tree():
		return
	if dead or target == null or not _is_telegraphing:
		_cancel_telegraph()
		return

	if sprite != null:
		sprite.self_modulate = Color.WHITE

	var proj_instance: Node = projectile_scene.instantiate()
	if projectile_container == null:
		projectile_container = get_parent()
	projectile_container.add_child(proj_instance)
	proj_instance.initialize(
		fire_position.global_position,
		fire_position.global_position.direction_to(_get_target_aim_point())
	)

	await get_tree().create_timer(post_shot_duration).timeout
	if not is_inside_tree():
		return
	if dead:
		return

	_cancel_telegraph()
	fire_timer.wait_time = maxf(attack_cooldown, 0.1)
	fire_timer.start()

# Apunta al objetivo y controla el temporizador de disparo.
func _physics_process(_delta: float) -> void:
	if dead or target == null:
		return

	raycast.set_target_position(raycast.to_local(_get_target_aim_point()))
	raycast.force_raycast_update()
	if raycast.is_colliding() && raycast.get_collider() == target:
		if fire_timer.is_stopped() and not _is_telegraphing:
			fire_timer.wait_time = maxf(attack_cooldown, 0.1)
			fire_timer.start()
	else:
		if !fire_timer.is_stopped():
			fire_timer.stop()
		if _is_telegraphing:
			_cancel_telegraph()

# Desactiva la torreta y reproduce el efecto de muerte.
func die() -> void:
	if dead:
		return

	dead = true
	_cancel_telegraph()
	remove_from_group("enemies")
	fire_timer.stop()
	collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	_spawn_chi_orb()
	died.emit()
	play_hit_anim()
	if sprite != null:
		sprite.stop()
		var death_tween: Tween = create_tween()
		death_tween.set_parallel(true)
		death_tween.tween_property(sprite, "scale", Vector2(IDLE_SCALE.x * 1.2, 0.0), 0.25)
		death_tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
		await death_tween.finished
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
		_cancel_telegraph()

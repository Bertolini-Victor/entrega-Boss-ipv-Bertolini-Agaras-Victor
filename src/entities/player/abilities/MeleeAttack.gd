extends Node2D
class_name MeleeAttack

const SLASH_FRAMES: Array[Texture2D] = [
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_01.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_02.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_03.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_04.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_05.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_06.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_07.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_08.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_09.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_10.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_11.png"),
	preload("res://assets/textures/melee_attack/Fire Slash_Frame_12.png"),
]

@export var attack_duration: float = 0.24
@export var attack_range: float = 40.0
@export var wall_check_distance: float = 18.0
@export var slash_scale: Vector2 = Vector2(0.085, 0.085)
@export var slash_offset: Vector2 = Vector2(22.0, -2.0)

var _is_attacking: bool = false
var _player: CharacterBody2D = null
var _slash_sprite: AnimatedSprite2D = null

func _ready() -> void:
	_player = _get_player()
	_setup_slash_sprite()

func _setup_slash_sprite() -> void:
	_slash_sprite = get_node_or_null("SlashSprite") as AnimatedSprite2D
	if _slash_sprite == null:
		_slash_sprite = AnimatedSprite2D.new()
		_slash_sprite.name = "SlashSprite"
		add_child(_slash_sprite)

	var frames := SpriteFrames.new()
	if not frames.has_animation("slash"):
		frames.add_animation("slash")
	frames.set_animation_loop("slash", false)
	frames.set_animation_speed("slash", float(SLASH_FRAMES.size()) / maxf(attack_duration, 0.05))
	for tex: Texture2D in SLASH_FRAMES:
		frames.add_frame("slash", tex)

	_slash_sprite.sprite_frames = frames
	_slash_sprite.scale = slash_scale
	_slash_sprite.visible = false

func _get_player() -> CharacterBody2D:
	if owner is CharacterBody2D:
		return owner as CharacterBody2D
	var current: Node = get_parent()
	while current != null:
		if current is CharacterBody2D:
			return current as CharacterBody2D
		current = current.get_parent()
	return null

# Ejecuta el ataque cuerpo a cuerpo orientado según facing_direction (+1.0 o -1.0).
func attack(facing_direction: float = 1.0) -> void:
	if _is_attacking:
		return

	var facing: float = 1.0 if facing_direction >= 0.0 else -1.0

	if _player == null:
		_player = _get_player()

	# Bloquear el ataque si el jugador está pegado físicamente a una pared en la dirección frontal
	if _player != null and _player.is_on_wall():
		var wall_normal: Vector2 = _player.get_wall_normal()
		if sign(wall_normal.x) == -facing:
			return

	# Chequeo frontal mediante raycast contra Capa 1 ("world") y Capa 4 ("obstacles")
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var exclude_rids: Array[RID] = []
	if _player != null:
		exclude_rids.append(_player.get_rid())

	var ray_params := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(facing * wall_check_distance, 0.0),
		1 | 8,
		exclude_rids
	)
	ray_params.collide_with_bodies = true
	ray_params.collide_with_areas = false

	var wall_hit: Dictionary = space_state.intersect_ray(ray_params)
	if not wall_hit.is_empty():
		return

	_is_attacking = true

	if _slash_sprite != null:
		_slash_sprite.position = Vector2(slash_offset.x * facing, slash_offset.y)
		_slash_sprite.scale = slash_scale
		_slash_sprite.flip_h = facing > 0.0
		_slash_sprite.sprite_frames.set_animation_speed("slash", float(SLASH_FRAMES.size()) / maxf(attack_duration, 0.05))
		_slash_sprite.visible = true
		_slash_sprite.frame = 0
		_slash_sprite.play("slash")

	# Usar PhysicsShapeQueryParameters2D para detección instantánea y confiable
	var shape := RectangleShape2D.new()
	var attack_height: float = 30.0
	shape.size = Vector2(attack_range, attack_height)

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.collision_mask = 4  # Capa de enemigos (turrets)
	params.collide_with_bodies = true
	params.collide_with_areas = false

	# Centrar el shape adelante del jugador según la dirección y rango de ataque
	var hit_origin: Vector2 = global_position + Vector2((attack_range * 0.5) * facing, 0.0)
	params.transform = Transform2D(0.0, hit_origin)

	var results: Array = space_state.intersect_shape(params)
	for result in results:
		var collider = result["collider"]
		if collider.has_method("take_damage"):
			collider.take_damage(1)
		elif collider.has_method("die"):
			collider.die()

	await get_tree().create_timer(attack_duration).timeout
	if not is_inside_tree():
		return
	if _slash_sprite != null:
		_slash_sprite.stop()
		_slash_sprite.visible = false
	_is_attacking = false

func is_attacking() -> bool:
	return _is_attacking

func die() -> void:
	queue_free()

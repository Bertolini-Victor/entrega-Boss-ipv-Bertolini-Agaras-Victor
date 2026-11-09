class_name BossMecha
extends CharacterBody2D

signal boss_defeated
signal health_changed(current_health: int, max_health: int)

enum State {
	INACTIVE,
	IDLE,
	WALK,
	ATTACK,
	JUMP,
	HURT,
	DEAD
}

@export var max_health: int = 12
@export var move_speed: float = 75.0
@export var projectile_speed: float = 560.0
@export var fire_cooldown: float = 2.0
@export var jump_cooldown: float = 5.5
@export var projectile_scene: PackedScene = preload("res://src/entities/enemies/turret/TurretProjectile.tscn")
@export var gravity: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle

var health: int = 12
var dead: bool = false
var active: bool = false
var target: Node2D = null

var current_state: State = State.INACTIVE
var _facing: float = -1.0
var _fire_timer: float = 0.8
var _jump_timer: float = 3.0
var _state_timer: float = 0.0
var _hit_tween: Tween = null
var _muzzle_base_x: float = 42.0

# Configura el estado inicial, grupo y animacion del jefe.
func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	if muzzle:
		_muzzle_base_x = absf(muzzle.position.x)
	_set_facing(-1.0)
	_play_animation("idle")

# Activa al jefe e inicia sus rutinas de combate contra el jugador.
func activate() -> void:
	if active or dead:
		return
	active = true
	_find_player()
	current_state = State.IDLE
	_fire_timer = 1.0
	_jump_timer = 4.0
	_play_animation("idle")

# Busca y asigna la referencia al jugador dentro del arbol de nodos.
func _find_player() -> void:
	if target != null and is_instance_valid(target):
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	else:
		var root = get_tree().current_scene
		if root:
			var p = root.find_child("Player", true, false)
			if p is Node2D:
				target = p

# Ejecuta la maquina de estados de combate y fisicas del jefe.
func _physics_process(delta: float) -> void:
	if dead or not active:
		if not is_on_floor():
			velocity.y = minf(velocity.y + gravity * delta, 700.0)
			move_and_slide()
		return

	if target == null or not is_instance_valid(target):
		_find_player()

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 700.0)
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if _fire_timer > 0.0:
		_fire_timer = maxf(0.0, _fire_timer - delta)
	if _jump_timer > 0.0:
		_jump_timer = maxf(0.0, _jump_timer - delta)

	# Orientación hacia el jugador mientras no esté en plena parábola aérea de salto
	if target != null and current_state != State.JUMP:
		var dx: float = target.global_position.x - global_position.x
		if absf(dx) > 10.0:
			_set_facing(1.0 if dx > 0.0 else -1.0)

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_decide_next_action()
		State.WALK:
			_process_walk_state(delta)
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		State.JUMP:
			_process_jump_state(delta)
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 350.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.IDLE
				_play_animation("idle")

	move_and_slide()

# Controla el desplazamiento y posicionamiento tactico del jefe.
func _process_walk_state(delta: float) -> void:
	if target == null:
		current_state = State.IDLE
		_play_animation("idle")
		return

	var dx: float = target.global_position.x - global_position.x
	var dist: float = absf(dx)

	# Si puede saltar o atacar, transicionar
	if _jump_timer <= 0.0 and dist > 120.0:
		_start_jump()
		return

	if _fire_timer <= 0.0:
		_start_attack()
		return

	# Mantener distancia óptima de combate (entre 180 y 320 px)
	var desired_dir: float = 0.0
	if dist > 260.0:
		desired_dir = _facing
	elif dist < 160.0:
		desired_dir = -_facing
	else:
		# En rango cómodo, detenerse y esperar disparo
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		if sprite and sprite.animation != "idle":
			_play_animation("idle")
		return

	velocity.x = desired_dir * move_speed
	_play_animation("walk")

# Gestiona la fisica y el aterrizaje durante el salto del jefe.
func _process_jump_state(_delta: float) -> void:
	# El salto aterriza al tocar el piso mientras la velocidad vertical es descendente
	if is_on_floor() and velocity.y >= 0.0:
		velocity.x = 0.0
		_play_animation("idle")
		current_state = State.IDLE
		_state_timer = 0.4
		_jump_timer = jump_cooldown

# Elige la siguiente accion del jefe segun distancia y enfriamientos.
func _decide_next_action() -> void:
	if target == null:
		_state_timer = 0.5
		return

	var dist: float = absf(target.global_position.x - global_position.x)

	if _jump_timer <= 0.0 and (dist > 150.0 or randf() < 0.4):
		_start_jump()
	elif _fire_timer <= 0.0:
		_start_attack()
	else:
		current_state = State.WALK
		_play_animation("walk")

# Inicia un salto con impulso hacia la posicion del jugador.
func _start_jump() -> void:
	if current_state == State.ATTACK or dead:
		return
	current_state = State.JUMP
	_play_animation("jump")

	var jump_impulse_y: float = -420.0
	var h_dist: float = 0.0
	if target != null:
		h_dist = target.global_position.x - global_position.x

	var jump_impulse_x: float = clampf(h_dist * 0.9, -240.0, 240.0)
	velocity = Vector2(jump_impulse_x, jump_impulse_y)

# Comienza la secuencia de ataque a distancia del jefe.
func _start_attack() -> void:
	if dead or current_state == State.ATTACK or current_state == State.JUMP:
		return

	current_state = State.ATTACK
	velocity.x = 0.0
	_play_animation("attack")

	# Frame 3 de 6 a 8 fps = ~0.375s para el instante del fogonazo
	var shot_delay: float = 3.0 / 8.0
	var timer := get_tree().create_timer(shot_delay)
	timer.timeout.connect(_on_attack_fire_moment)

# Dispara el proyectil en el fotograma adecuado de la animacion.
func _on_attack_fire_moment() -> void:
	if dead or current_state != State.ATTACK or not is_inside_tree():
		return
	_fire_projectile()

# Instancia y lanza un proyectil en direccion al jugador.
func _fire_projectile() -> void:
	if projectile_scene == null or muzzle == null:
		return

	var proj: Node = projectile_scene.instantiate()
	if "velocity_speed" in proj:
		proj.velocity_speed = projectile_speed
	elif "speed" in proj:
		proj.speed = projectile_speed

	var spawn_pos: Vector2 = muzzle.global_position
	var aim_point: Vector2
	if target != null and is_instance_valid(target):
		aim_point = target.global_position + Vector2(0.0, -15.0)
	else:
		aim_point = spawn_pos + Vector2(_facing * 100.0, 0.0)

	var dir: Vector2 = spawn_pos.direction_to(aim_point)

	get_parent().add_child(proj)
	if proj.has_method("initialize"):
		proj.initialize(spawn_pos, dir)

	_fire_timer = fire_cooldown

	# Esperar a que concluya la animación de ataque para regresar a idle
	if sprite != null:
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout

	if dead or current_state != State.ATTACK:
		return

	current_state = State.IDLE
	_state_timer = 0.2
	_play_animation("idle")

# Aplica daño proporcional por impacto directo de rayo.
func hit_by_lightning() -> void:
	# El Rayo le quita un tercio exacto de su vida máxima: 3 impactos = muerte
	var lightning_dmg: int = int(ceil(float(max_health) / 3.0))
	take_damage(lightning_dmg)

# Reduce los puntos de vida del jefe y gestiona su retroceso visual.
func take_damage(amount: int = 1) -> void:
	if dead:
		return

	# Si un rayo impactó llamando a take_damage(100) en lugar de hit_by_lightning:
	if amount >= 100:
		amount = int(ceil(float(max_health) / 3.0))

	health = max(0, health - amount)
	health_changed.emit(health, max_health)

	_play_hit_flash()

	if health <= 0:
		die()
		return

	# Si no está atacando o saltando, muestra reacción hurt
	if current_state != State.ATTACK and current_state != State.JUMP:
		current_state = State.HURT
		_state_timer = 0.28
		_play_animation("hurt")
		velocity.x = -_facing * 35.0

# Reproduce un destello visual al recibir impacto.
func _play_hit_flash() -> void:
	if sprite == null:
		return
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()

	sprite.self_modulate = Color(3.0, 0.4, 0.4, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.2)

# Desactiva al jefe, emite la señal de victoria e inicia su animacion de muerte.
func die() -> void:
	if dead:
		return
	dead = true
	current_state = State.DEAD
	remove_from_group("enemies")

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	velocity = Vector2.ZERO
	set_physics_process(false)

	boss_defeated.emit()

	if sprite != null:
		var death_tween: Tween = create_tween()
		death_tween.set_parallel(true)
		death_tween.tween_property(sprite, "scale", Vector2(1.2, 0.05), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		death_tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		await death_tween.finished
	else:
		await get_tree().create_timer(0.5).timeout

	if is_inside_tree():
		queue_free()

# Actualiza la orientacion visual y el punto de disparo del jefe.
func _set_facing(new_facing: float) -> void:
	_facing = 1.0 if new_facing >= 0.0 else -1.0
	if sprite != null:
		sprite.flip_h = (_facing > 0.0)
	if muzzle != null:
		muzzle.position.x = _facing * _muzzle_base_x

# Reproduce una animacion del sprite si no esta en reproduccion.
func _play_animation(anim_name: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(anim_name):
		return
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)

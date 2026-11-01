class_name GoalZuko
extends Area2D

signal level_completed

@export var golem_scene: PackedScene = preload("res://src/entities/enemies/golem/Golem.tscn")

@onready var zuko_sprite: AnimatedSprite2D = $ZukoSprite
@onready var teleport_beam: AnimatedSprite2D = $TeleportBeam
@onready var teleport_particles: CPUParticles2D = $TeleportParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _triggered: bool = false
var _golem_left: Node2D = null
var _golem_right: Node2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Detectar al jugador (capa 2)
	body_entered.connect(_on_body_entered)

	if teleport_beam != null:
		teleport_beam.visible = false
	if zuko_sprite != null:
		zuko_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body is Player or body.name == "Player":
		_triggered = true
		_start_cutscene(body)

func _start_cutscene(player: Node2D) -> void:
	# 1. Desactivar colision del Goal para no repetir la ejecucion
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	# Desactivar movimiento del jugador (estado "Cinematic")
	if "is_cinematic" in player:
		player.is_cinematic = true
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)

	# 2. Secuencia cinematica
	# Paso 1: Cambia la animacion de Zuko a "shocked"
	if zuko_sprite != null:
		zuko_sprite.play("shocked")

	# Espera 0.5 segundos
	await get_tree().create_timer(0.5).timeout

	# Instancia por codigo dos Golems apareciendo a cada lado de Zuko
	_spawn_kidnapper_golems()

	# Paso 2: Cambia la animacion de Zuko a "grabbed"
	if zuko_sprite != null:
		zuko_sprite.play("grabbed")

	# Espera 0.5 segundos
	await get_tree().create_timer(0.5).timeout

	# Paso 3: Haz visible el TeleportBeam, reproduce su animacion y activa TeleportParticles.restart()
	if teleport_beam != null:
		teleport_beam.visible = true
		teleport_beam.play("beam")
	if teleport_particles != null:
		teleport_particles.restart()

	# Inmediatamente anima con Tween: modulate.a -> 0.0 y estirar ligeramente hacia arriba (scale.y = 2.0x)
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	if zuko_sprite != null:
		var target_zuko_scale_y: float = zuko_sprite.scale.y * 2.0
		tween.tween_property(zuko_sprite, "modulate:a", 0.0, 0.6)
		tween.tween_property(zuko_sprite, "scale:y", target_zuko_scale_y, 0.6)

	if _golem_left != null:
		var target_golem_l_scale_y: float = _golem_left.scale.y * 2.0
		tween.tween_property(_golem_left, "modulate:a", 0.0, 0.6)
		tween.tween_property(_golem_left, "scale:y", target_golem_l_scale_y, 0.6)

	if _golem_right != null:
		var target_golem_r_scale_y: float = _golem_right.scale.y * 2.0
		tween.tween_property(_golem_right, "modulate:a", 0.0, 0.6)
		tween.tween_property(_golem_right, "scale:y", target_golem_r_scale_y, 0.6)

	await tween.finished

	# Esperar a que concluya el haz del rayo
	if teleport_beam != null and teleport_beam.is_playing():
		await teleport_beam.animation_finished
	else:
		await get_tree().create_timer(0.3).timeout

	# Llamar a la funcion de victoria del juego
	level_completed.emit()
	_trigger_win()

func _spawn_kidnapper_golems() -> void:
	if golem_scene == null:
		return

	# Golem Izquierdo
	_golem_left = golem_scene.instantiate() as Node2D
	_configure_cinematic_golem(_golem_left, Vector2(-26, 0), false)
	add_child(_golem_left)

	# Golem Derecho
	_golem_right = golem_scene.instantiate() as Node2D
	_configure_cinematic_golem(_golem_right, Vector2(26, 0), true)
	add_child(_golem_right)

func _configure_cinematic_golem(golem: Node2D, local_pos: Vector2, facing_left: bool) -> void:
	golem.position = local_pos
	golem.set_physics_process(false)
	golem.set_process(false)
	if "collision_layer" in golem:
		golem.collision_layer = 0
	if "collision_mask" in golem:
		golem.collision_mask = 0

	for child in golem.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
		elif child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)

	var visuals: AnimatedSprite2D = golem.get_node_or_null("Visuals") as AnimatedSprite2D
	if visuals != null:
		visuals.flip_h = facing_left
		if visuals.sprite_frames != null and visuals.sprite_frames.has_animation("attack"):
			visuals.play("attack")
		elif visuals.sprite_frames != null and visuals.sprite_frames.has_animation("idle"):
			visuals.play("idle")

func _trigger_win() -> void:
	var hud: CanvasLayer = get_tree().current_scene.get_node_or_null("HUD") as CanvasLayer
	if hud != null and hud.has_method("show_win_screen"):
		hud.show_win_screen()
	elif get_tree().current_scene.has_method("_on_goal_level_completed"):
		get_tree().current_scene._on_goal_level_completed()
	else:
		get_tree().change_scene_to_file("res://src/ui/win/WinCredits.tscn")

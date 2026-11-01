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
	# Desactivar colisión del Goal para no repetir la ejecución
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	# 1. Inicio: Al detectar al body (Iroh), llama inmediatamente a body.disable_controls()
	if player.has_method("disable_controls"):
		player.disable_controls()
	else:
		if "is_cinematic" in player:
			player.is_cinematic = true
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		if player.has_method("set_physics_process"):
			player.set_physics_process(false)

	# 2. Sorpresa: Cambia la animación de Zuko a "shocked"
	if zuko_sprite != null:
		zuko_sprite.play("shocked")

	# 3. Pausa 1: Ritmo dramático de inicio
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return

	# 4. Aparición de Golems: Instancia los dos Golems falsos (solo visuales)
	# Base de Zuko coincide con y=0. offset_y = 0.0 alinea exactamente la base de los Golems con el piso de Zuko.
	var offset_y: float = 0.0
	_spawn_kidnapper_golems(offset_y)

	# 5. Captura: Cambia la animación de Zuko a "grabbed"
	if zuko_sprite != null:
		zuko_sprite.play("grabbed")

	# 6. Pausa 2: Tensión dramática antes del teletransporte
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return

	# 7. Teletransportación:
	# - Haz visible el TeleportBeam y reproduce "beam"
	# - Activa las partículas: $TeleportParticles.emitting = true
	# - Usa un Tween de 1.0 segundo para hacer fade out a Zuko y los dos Golems y estirarlos verticalmente
	if teleport_beam != null:
		teleport_beam.visible = true
		teleport_beam.play("beam")
	if teleport_particles != null:
		teleport_particles.emitting = true
		teleport_particles.restart()

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	if zuko_sprite != null:
		var target_zuko_scale_y: float = zuko_sprite.scale.y * 2.0
		tween.tween_property(zuko_sprite, "modulate:a", 0.0, 1.0)
		tween.tween_property(zuko_sprite, "scale:y", target_zuko_scale_y, 1.0)

	if _golem_left != null:
		var target_golem_l_scale_y: float = _golem_left.scale.y * 2.0
		tween.tween_property(_golem_left, "modulate:a", 0.0, 1.0)
		tween.tween_property(_golem_left, "scale:y", target_golem_l_scale_y, 1.0)

	if _golem_right != null:
		var target_golem_r_scale_y: float = _golem_right.scale.y * 2.0
		tween.tween_property(_golem_right, "modulate:a", 0.0, 1.0)
		tween.tween_property(_golem_right, "scale:y", target_golem_r_scale_y, 1.0)

	# 8. Pausa 3: Espera a que el rayo concluya
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return

	# 9. Final: Dispara la señal level_completed o llama a la victoria
	level_completed.emit()
	_trigger_win()

func _spawn_kidnapper_golems(offset_y: float = 0.0) -> void:
	if golem_scene == null:
		return

	# Golem Izquierdo (Vector2(-40, offset_y))
	_golem_left = golem_scene.instantiate() as Node2D
	_configure_cinematic_golem(_golem_left, Vector2(-40.0, offset_y), false)
	add_child(_golem_left)

	# Golem Derecho (Vector2(40, offset_y))
	_golem_right = golem_scene.instantiate() as Node2D
	_configure_cinematic_golem(_golem_right, Vector2(40.0, offset_y), true)
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
		elif child is AudioStreamPlayer2D or child is AudioStreamPlayer:
			child.stop()

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

class_name GoalZuko
extends Area2D

signal level_completed

@export var golem_scene: PackedScene = preload("res://src/entities/enemies/golem/Golem.tscn")

@onready var zuko_sprite: AnimatedSprite2D = $ZukoSprite
@onready var cinematic_golem_1: AnimatedSprite2D = $CinematicGolem1
@onready var cinematic_golem_2: AnimatedSprite2D = $CinematicGolem2
@onready var teleport_beam: AnimatedSprite2D = $TeleportBeam
@onready var teleport_particles: CPUParticles2D = $TeleportParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Detectar al jugador (capa 2)
	body_entered.connect(_on_body_entered)

	if teleport_beam != null:
		teleport_beam.visible = false
	if cinematic_golem_1 != null:
		cinematic_golem_1.visible = false
	if cinematic_golem_2 != null:
		cinematic_golem_2.visible = false
	if zuko_sprite != null:
		zuko_sprite.flip_h = true
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

	# 1. Desactiva los controles de Iroh (body.disable_controls())
	if player.has_method("disable_controls"):
		player.disable_controls()
	else:
		if "is_cinematic" in player:
			player.is_cinematic = true
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		if player.has_method("set_physics_process"):
			player.set_physics_process(false)

	# 2. Muestra el primer diálogo usando la HUD:
	_show_dialogue("Iroh: ¡Zuko! Al fin te encuentro...")

	# 3. Pausa 1: Ritmo dramático de inicio
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return

	# 4. Cambia la animación de Zuko a "shocked"
	if zuko_sprite != null:
		zuko_sprite.play("shocked")

	# 5. Haz visibles a los dos Golems pre-posicionados
	if cinematic_golem_1 != null:
		cinematic_golem_1.visible = true
	if cinematic_golem_2 != null:
		cinematic_golem_2.visible = true

	# 6. Muestra la advertencia de Zuko
	_show_dialogue("Zuko: ¡Tío, cuidado, es una trampa!")

	# 7. Pausa 2: Tensión dramática
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return

	# 8. Cambia la animación de Zuko a "grabbed"
	if zuko_sprite != null:
		zuko_sprite.play("grabbed")

	# 9. Oculta el diálogo
	_hide_dialogue()

	# 10. Pausa breve antes del teletransporte
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return

	# 11. Inicia la teletransportación (haz visible el rayo, activa las partículas, y lanza el Tween de desvanecimiento/escala de Zuko y los dos Golems)
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

	if cinematic_golem_1 != null:
		var target_golem_1_scale_y: float = cinematic_golem_1.scale.y * 2.0
		tween.tween_property(cinematic_golem_1, "modulate:a", 0.0, 1.0)
		tween.tween_property(cinematic_golem_1, "scale:y", target_golem_1_scale_y, 1.0)

	if cinematic_golem_2 != null:
		var target_golem_2_scale_y: float = cinematic_golem_2.scale.y * 2.0
		tween.tween_property(cinematic_golem_2, "modulate:a", 0.0, 1.0)
		tween.tween_property(cinematic_golem_2, "scale:y", target_golem_2_scale_y, 1.0)

	# 12. Espera a que el rayo y la desintegración concluyan
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return

	# 13. Llama a la pantalla de victoria/nivel completado
	level_completed.emit()
	_trigger_win()

func _show_dialogue(text: String) -> void:
	var hud: HUD = _get_hud()
	if hud != null and hud.has_method("show_dialogue"):
		hud.show_dialogue(text)

func _hide_dialogue() -> void:
	var hud: HUD = _get_hud()
	if hud != null and hud.has_method("hide_dialogue"):
		hud.hide_dialogue()

func _get_hud() -> HUD:
	if not is_inside_tree() or get_tree().current_scene == null:
		return null
	return get_tree().current_scene.get_node_or_null("HUD") as HUD

func _trigger_win() -> void:
	var hud: CanvasLayer = get_tree().current_scene.get_node_or_null("HUD") as CanvasLayer
	if hud != null and hud.has_method("show_win_screen"):
		hud.show_win_screen()
	elif get_tree().current_scene.has_method("_on_goal_level_completed"):
		get_tree().current_scene._on_goal_level_completed()
	else:
		get_tree().change_scene_to_file("res://src/ui/win/WinCredits.tscn")

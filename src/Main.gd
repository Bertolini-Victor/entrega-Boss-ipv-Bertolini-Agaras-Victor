class_name Main
extends Node

var player: Player = null
var goal: Node = null
var hud: HUD = null
@onready var background_music: AudioStreamPlayer = get_node_or_null("BackgroundMusic")

func _ready() -> void:
	if background_music:
		if not background_music.finished.is_connected(background_music.play):
			background_music.finished.connect(background_music.play)
		if not background_music.playing:
			background_music.play()

	# Búsqueda segura con fallback a rutas directas de la escena
	player = get_node_or_null("%Player") as Player
	if player == null and has_node("Environment/Entities/Player"):
		player = get_node("Environment/Entities/Player") as Player

	hud = get_node_or_null("%HUD") as HUD
	if hud == null and has_node("HUD"):
		hud = get_node("HUD") as HUD

	goal = get_node_or_null("%GoalZuko")
	if goal == null and has_node("Environment/Objects/GoalZuko"):
		goal = get_node("Environment/Objects/GoalZuko")

	if player:
		if not player.player_died.is_connected(_on_player_player_died):
			player.player_died.connect(_on_player_player_died)

	if player and hud:
		if not player.health_changed.is_connected(hud.update_health):
			player.health_changed.connect(hud.update_health)
		if not player.chi_changed.is_connected(hud.update_chi):
			player.chi_changed.connect(hud.update_chi)
		if not player.ability_unlocked.is_connected(hud.show_ability_unlocked_overlay):
			player.ability_unlocked.connect(hud.show_ability_unlocked_overlay)

		# Forzar la actualización visual al arrancar el nivel
		hud.update_health(player.health, player.max_health)
		hud.update_chi(player.chi, player.max_chi)

	if goal and goal.has_signal("level_completed"):
		if not goal.level_completed.is_connected(_on_goal_level_completed):
			goal.level_completed.connect(_on_goal_level_completed)

# Callback cuando el jugador muere.
func _on_player_player_died() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://src/ui/game_over/GameOver.tscn")

# Reposiciona al jugador tras caer al vacío y aplica penalización de daño.
func _respawn_player_from_fall(p: Player, respawn_pos: Vector2) -> void:
	p._is_invulnerable = false
	p.take_damage(1)

	if p.health > 0 and not p.dead:
		p.velocity = Vector2.ZERO
		p.h_movement_direction = 0
		p.global_position = respawn_pos
		p.last_safe_position = respawn_pos
		p.face_right()
		if p.body_animations and p.body_animations.has_animation("idle"):
			p.body_animations.play("idle")

# Callback cuando el jugador cae al vacio en FallKillzone (Zona 1 - Bottom Floor).
func _on_fall_killzone_body_entered(body: Node2D) -> void:
	if body is Player:
		var p: Player = body as Player
		var respawn_pos: Vector2 = p.spawn_position if p.spawn_position != Vector2.ZERO else Vector2(150.0, 520.0)
		_respawn_player_from_fall(p, respawn_pos)

# Callback cuando el jugador llega a la meta.
func _on_goal_level_completed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://src/ui/win/WinCredits.tscn")

# Callback cuando el jugador cae en el abismo de las plataformas del piso medio (Zona 2).
func _on_mid_floor_fall_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		_respawn_player_from_fall(body as Player, Vector2(4220.0, -135.0))

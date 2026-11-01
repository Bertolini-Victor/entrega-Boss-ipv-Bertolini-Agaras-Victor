class_name Main
extends Node

@onready var player: Player = get_node_or_null("%Player")
@onready var goal: Node = get_node_or_null("%GoalZuko") if get_node_or_null("%GoalZuko") != null else get_node_or_null("%Goal")
@onready var hud: HUD = get_node_or_null("%HUD")
@onready var background_music: AudioStreamPlayer = get_node_or_null("BackgroundMusic")

func _ready() -> void:
	if background_music:
		if not background_music.finished.is_connected(background_music.play):
			background_music.finished.connect(background_music.play)
		if not background_music.playing:
			background_music.play()
	# Fallback si no usan unique names
	if player == null and has_node("Environment/Entities/Player"):
		player = get_node("Environment/Entities/Player") as Player
	if goal == null and has_node("Environment/Objects/GoalZuko"):
		goal = get_node("Environment/Objects/GoalZuko")
	elif goal == null and has_node("Environment/Objects/Goal"):
		goal = get_node("Environment/Objects/Goal")
	if hud == null and has_node("HUD"):
		hud = get_node("HUD") as HUD

	if player:
		if not player.player_died.is_connected(_on_player_player_died):
			player.player_died.connect(_on_player_player_died)
		
		if hud:
			if not player.health_changed.is_connected(hud.update_health):
				player.health_changed.connect(hud.update_health)
			if not player.chi_changed.is_connected(hud.update_chi):
				player.chi_changed.connect(hud.update_chi)
			if not player.ability_unlocked.is_connected(hud.show_ability_unlocked_overlay):
				player.ability_unlocked.connect(hud.show_ability_unlocked_overlay)
			if not player.fireball_unlocked.is_connected(hud.show_fireball_unlocked_overlay):
				player.fireball_unlocked.connect(hud.show_fireball_unlocked_overlay)
			
			hud.update_health(player.health, player.max_health)
			hud.update_chi(player.chi, player.max_chi)

	if goal and goal.has_signal("level_completed"):
		if not goal.level_completed.is_connected(_on_goal_level_completed):
			goal.level_completed.connect(_on_goal_level_completed)

# Callback cuando el jugador muere.
func _on_player_player_died() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://src/ui/game_over/GameOver.tscn")

# Callback cuando el jugador cae al vacio en FallKillzone (Zona 1 - Bottom Floor).
func _on_fall_killzone_body_entered(body: Node2D) -> void:
	if body is Player:
		var p: Player = body as Player
		# Restamos vida (esto ya otorga i-frames internamente)
		p._is_invulnerable = false
		p.take_damage(1)

		if p.health > 0 and not p.dead:
			# Detenemos inercias e inputs residuales
			p.velocity = Vector2.ZERO
			p.h_movement_direction = 0

			# Punto de inicio del nivel
			var respawn_pos: Vector2 = p.spawn_position if p.spawn_position != Vector2.ZERO else Vector2(150.0, 520.0)
			p.global_position = respawn_pos
			p.last_safe_position = p.global_position

			# Forzar orientacion visual y logica
			p.face_right()
			if p.has_node("BodyPivot"):
				p.get_node("BodyPivot").scale.x = 1.0

			# Reiniciar animacion para destrabar frames de caida
			if p.has_node("BodyAnimations"):
				p.get_node("BodyAnimations").play("idle")

# Callback cuando el jugador llega a la meta.
func _on_goal_level_completed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://src/ui/win/WinCredits.tscn")

# Callback cuando el jugador cae en el abismo de las plataformas del piso medio (Zona 2).
func _on_mid_floor_fall_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		var p: Player = body as Player
		# Restamos vida (esto ya otorga i-frames internamente)
		p._is_invulnerable = false
		p.take_damage(1)

		if p.health > 0 and not p.dead:
			# Detenemos inercias e inputs residuales
			p.velocity = Vector2.ZERO
			p.h_movement_direction = 0

			# Teletransporte a la salida del ascensor
			var respawn_pos = Vector2(4220, -135)
			p.global_position = respawn_pos
			p.last_safe_position = p.global_position

			# Forzar orientacion visual y logica
			p.face_right()
			if p.has_node("BodyPivot"):
				p.get_node("BodyPivot").scale.x = 1.0

			# Reiniciar animacion para destrabar frames de caida
			if p.has_node("BodyAnimations"):
				p.get_node("BodyAnimations").play("idle")

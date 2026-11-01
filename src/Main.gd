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
	if body is Player or body.is_in_group("player") or body.name == "Player":
		if body.has_method("take_damage"):
			if "_is_invulnerable" in body:
				body.set("_is_invulnerable", false)
			body.take_damage(1)

		var is_alive: bool = true
		if "dead" in body and body.get("dead") == true:
			is_alive = false
		elif "_is_dead" in body and body.get("_is_dead") == true:
			is_alive = false
		elif "health" in body and int(body.get("health")) <= 0:
			is_alive = false

		if is_alive:
			if "velocity" in body:
				body.set("velocity", Vector2.ZERO)
			# Teletransporta al punto de inicio del nivel (spawn original)
			var spawn_pos: Vector2 = Vector2(150.0, 520.0)
			if "spawn_position" in body and body.get("spawn_position") != Vector2.ZERO:
				spawn_pos = body.get("spawn_position")
			body.global_position = spawn_pos
			if "last_safe_position" in body:
				body.set("last_safe_position", spawn_pos)

			# Fuerza al personaje a mirar hacia la derecha
			if body.has_method("face_right"):
				body.face_right()
			elif body.has_method("set_facing_direction"):
				body.set_facing_direction(Vector2.RIGHT)
			elif "direction" in body:
				body.set("direction", Vector2.RIGHT)

			if body.has_node("BodyPivot"):
				var pivot: Node2D = body.get_node("BodyPivot") as Node2D
				if pivot != null:
					pivot.scale.x = 1.0
			if body.has_node("AnimatedSprite2D"):
				var anim_spr: Node = body.get_node("AnimatedSprite2D")
				if "flip_h" in anim_spr:
					anim_spr.set("flip_h", false)
			if body.has_node("BodyPivot/Body"):
				var body_spr: Node = body.get_node("BodyPivot/Body")
				if "flip_h" in body_spr:
					body_spr.set("flip_h", false)

# Callback cuando el jugador llega a la meta.
func _on_goal_level_completed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://src/ui/win/WinCredits.tscn")

# Callback cuando el jugador cae en el abismo de las plataformas del piso medio (Zona 2).
func _on_mid_floor_fall_zone_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		if body.has_method("take_damage"):
			if "_is_invulnerable" in body:
				body.set("_is_invulnerable", false)
			body.take_damage(1)

		var is_alive: bool = true
		if "dead" in body and body.get("dead") == true:
			is_alive = false
		elif "_is_dead" in body and body.get("_is_dead") == true:
			is_alive = false
		elif "health" in body and int(body.get("health")) <= 0:
			is_alive = false

		if is_alive:
			if "velocity" in body:
				body.set("velocity", Vector2.ZERO)
			# Coordenadas exactas de la salida superior del Primer Ascensor (Elevator_1) en el piso medio
			var respawn_pos: Vector2 = Vector2(4220.0, -135.0)
			var elevator_1: Node = get_node_or_null("Environment/Ground/Elevator_1")
			if elevator_1 != null and elevator_1 is Node2D:
				var elevator_2d: Node2D = elevator_1 as Node2D
				var travel_h: float = float(elevator_1.get("travel_height")) if elevator_1.get("travel_height") != null else 700.0
				var base_y: float = elevator_2d.position.y if elevator_2d.position.y > 0.0 else 576.0
				respawn_pos = Vector2(elevator_2d.position.x - 100.0, base_y - travel_h - 11.0)

			body.global_position = respawn_pos
			if "last_safe_position" in body:
				body.set("last_safe_position", respawn_pos)

			# Fuerza al personaje a mirar hacia la derecha
			if body.has_method("face_right"):
				body.face_right()
			elif body.has_method("set_facing_direction"):
				body.set_facing_direction(Vector2.RIGHT)
			elif "direction" in body:
				body.set("direction", Vector2.RIGHT)

			if body.has_node("BodyPivot"):
				var pivot: Node2D = body.get_node("BodyPivot") as Node2D
				if pivot != null:
					pivot.scale.x = 1.0
			if body.has_node("AnimatedSprite2D"):
				var anim_spr: Node = body.get_node("AnimatedSprite2D")
				if "flip_h" in anim_spr:
					anim_spr.set("flip_h", false)
			if body.has_node("BodyPivot/Body"):
				var body_spr: Node = body.get_node("BodyPivot/Body")
				if "flip_h" in body_spr:
					body_spr.set("flip_h", false)

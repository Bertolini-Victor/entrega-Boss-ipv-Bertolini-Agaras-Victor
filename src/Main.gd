class_name Main
extends Node

@onready var player: Player = get_node_or_null("%Player")
@onready var goal: Goal = get_node_or_null("%Goal")
@onready var hud: HUD = get_node_or_null("%HUD")

func _ready() -> void:
	# Fallback si no usan unique names
	if player == null and has_node("Environment/Entities/Player"):
		player = get_node("Environment/Entities/Player") as Player
	if goal == null and has_node("Environment/Objects/Goal"):
		goal = get_node("Environment/Objects/Goal") as Goal
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
			if not player.fireball_unlocked.is_connected(hud.show_fireball_unlocked_overlay):
				player.fireball_unlocked.connect(hud.show_fireball_unlocked_overlay)
			
			hud.update_health(player.health, player.max_health)
			hud.update_chi(player.chi, player.max_chi)

	if goal:
		if not goal.level_completed.is_connected(_on_goal_level_completed):
			goal.level_completed.connect(_on_goal_level_completed)

# Callback cuando el jugador muere.
func _on_player_player_died() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://src/ui/game_over/GameOver.tscn")

# Callback cuando el jugador llega a la meta.
func _on_goal_level_completed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://src/ui/win/WinCredits.tscn")

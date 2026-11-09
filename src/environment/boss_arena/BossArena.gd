class_name BossArena
extends Node2D

@onready var left_shield: ShieldWall = get_node_or_null("LeftShieldWall")
@onready var right_shield: ShieldWall = get_node_or_null("RightShieldWall")
@onready var arena_trigger: Area2D = get_node_or_null("ArenaTrigger")
@onready var boss: BossMecha = get_node_or_null("BossMecha")

var _triggered: bool = false

# Conecta los detectores de entrada a la arena y el estado del jefe.
func _ready() -> void:
	if left_shield:
		left_shield.deactivate()
	if right_shield:
		right_shield.activate(false)

	if arena_trigger:
		if not arena_trigger.body_entered.is_connected(_on_arena_trigger_body_entered):
			arena_trigger.body_entered.connect(_on_arena_trigger_body_entered)

	if boss:
		if not boss.boss_defeated.is_connected(_on_boss_defeated):
			boss.boss_defeated.connect(_on_boss_defeated)

# Activa el combate al entrar el jugador en el area delimitada.
func _on_arena_trigger_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body is Player or body.is_in_group("player"):
		_triggered = true
		_activate_arena()

# Cierra los muros de proteccion y despierta al jefe.
func _activate_arena() -> void:
	# 1. Activa y hace visible LeftShieldWall detrás del jugador
	if left_shield and is_instance_valid(left_shield):
		left_shield.activate(true)

	# 2. Activa la IA del BossMecha
	if boss and is_instance_valid(boss):
		boss.activate()

	# 3. Aviso breve en el HUD
	var hud: HUD = _get_hud()
	if hud and is_instance_valid(hud):
		hud.show_dialogue("¡ALERTA! Escudos de contención activados.")
		var t := get_tree().create_timer(3.5)
		t.timeout.connect(func() -> void:
			if is_instance_valid(hud):
				hud.hide_dialogue()
		)

# Desactiva los muros de proteccion tras vencer al jefe.
func _on_boss_defeated() -> void:
	# Desactiva y desvanece con un Tween ambos escudos de fuerza
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	if left_shield and is_instance_valid(left_shield):
		tw.tween_property(left_shield, "modulate:a", 0.0, 0.8)
	if right_shield and is_instance_valid(right_shield):
		tw.tween_property(right_shield, "modulate:a", 0.0, 0.8)

	tw.chain().tween_callback(func() -> void:
		if left_shield and is_instance_valid(left_shield):
			left_shield.queue_free()
		if right_shield and is_instance_valid(right_shield):
			right_shield.queue_free()
	)

# Localiza el HUD del nivel para alertas y eventos.
func _get_hud() -> HUD:
	var root = get_tree().current_scene
	if root:
		var h = root.find_child("HUD", true, false)
		if h is HUD:
			return h
	return null

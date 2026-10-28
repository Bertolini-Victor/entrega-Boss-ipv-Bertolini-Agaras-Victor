class_name HUD
extends CanvasLayer

@onready var heart_1: Label = $MarginContainer/StatsBox/HeartContainer/Heart1
@onready var heart_2: Label = $MarginContainer/StatsBox/HeartContainer/Heart2
@onready var chi_bar: ProgressBar = $MarginContainer/StatsBox/ChiBox/ChiBar
@onready var chi_label: Label = $MarginContainer/StatsBox/ChiBox/ChiLabel

@onready var tutorial_panel: Control = $TutorialOverlay
@onready var tutorial_timer: Timer = $TutorialOverlay/TutorialTimer

@onready var fireball_panel: Control = $FireballOverlay
@onready var fireball_timer: Timer = $FireballOverlay/FireballTimer
@onready var fireball_title_label: Label = get_node_or_null("FireballOverlay/Margin/Content/Title")
@onready var fireball_hint_label: Label = get_node_or_null("FireballOverlay/Margin/Content/Hint")

func _ready() -> void:
	update_health(2, 2)
	update_chi(0, 100)
	tutorial_panel.visible = true
	fireball_panel.visible = false

func update_health(current_hp: int, _max_hp: int) -> void:
	if heart_1:
		heart_1.modulate = Color(1.0, 0.2, 0.2, 1.0) if current_hp >= 1 else Color(0.35, 0.35, 0.35, 0.5)
	if heart_2:
		heart_2.modulate = Color(1.0, 0.2, 0.2, 1.0) if current_hp >= 2 else Color(0.35, 0.35, 0.35, 0.5)

func update_chi(current_chi: int, max_chi: int) -> void:
	if chi_bar:
		chi_bar.max_value = max_chi
		chi_bar.value = current_chi
	if chi_label:
		chi_label.text = "Chi: %d / %d" % [current_chi, max_chi]

func show_ability_unlocked_overlay(title: String, hint: String) -> void:
	if fireball_title_label:
		fireball_title_label.text = title
	if fireball_hint_label:
		fireball_hint_label.text = hint
	if fireball_panel:
		fireball_panel.visible = true
		if fireball_timer:
			fireball_timer.start(5.0)

func show_fireball_unlocked_overlay() -> void:
	show_ability_unlocked_overlay("¡BOLA DE FUEGO Y RAYO CONTROL!", "Bola de fuego: Q | Ataque cargado: E")

func _on_tutorial_timer_timeout() -> void:
	if tutorial_panel:
		tutorial_panel.visible = false

func _on_fireball_timer_timeout() -> void:
	if fireball_panel:
		fireball_panel.visible = false

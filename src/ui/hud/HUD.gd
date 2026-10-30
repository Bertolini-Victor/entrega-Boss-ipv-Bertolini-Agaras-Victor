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

var _is_dismissing_hint: bool = false
var _required_actions: Dictionary = {
	"move": false,
	"jump": false,
	"melee": false,
	"parry": false
}

func _ready() -> void:
	update_health(2, 2)
	update_chi(0, 100)
	if tutorial_panel:
		tutorial_panel.visible = true
		tutorial_panel.modulate.a = 0.45
	if fireball_panel:
		fireball_panel.visible = false

func _input(event: InputEvent) -> void:
	if _is_dismissing_hint or tutorial_panel == null or not tutorial_panel.visible:
		return
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		_required_actions["move"] = true
	elif event.is_action_pressed("jump"):
		_required_actions["jump"] = true
	elif event.is_action_pressed("attack_melee"):
		_required_actions["melee"] = true
	elif event.is_action_pressed("parry"):
		_required_actions["parry"] = true

	_check_all_actions_completed()

func _check_all_actions_completed() -> void:
	for action: String in _required_actions:
		if not _required_actions[action]:
			return
	_dismiss_controls_hint()

func _dismiss_controls_hint() -> void:
	if _is_dismissing_hint or tutorial_panel == null or not tutorial_panel.visible:
		return
	_is_dismissing_hint = true
	if tutorial_timer and not tutorial_timer.is_stopped():
		tutorial_timer.stop()
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.6)
	tween.finished.connect(func() -> void:
		if tutorial_panel:
			tutorial_panel.visible = false
	)

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
	_dismiss_controls_hint()

func _on_fireball_timer_timeout() -> void:
	if fireball_panel:
		fireball_panel.visible = false

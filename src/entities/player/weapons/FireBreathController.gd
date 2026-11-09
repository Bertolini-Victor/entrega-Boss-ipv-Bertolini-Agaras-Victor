class_name FireBreathController
extends Node2D

@export var vertical_range: float = 135.0
@export var breath_width: float = 44.0
@export var attack_duration: float = 0.28
@export var fire_cooldown: float = 0.45

var _is_attacking: bool = false
var _cooldown_timer: float = 0.0
var _visual_timer: float = 0.0
var _player: CharacterBody2D = null

# Inicializa referencias del controlador de aliento de fuego.
func _ready() -> void:
	_player = _get_player()

# Obtiene el nodo CharacterBody2D del jugador.
func _get_player() -> CharacterBody2D:
	if owner is CharacterBody2D:
		return owner as CharacterBody2D
	var current: Node = get_parent()
	while current != null:
		if current is CharacterBody2D:
			return current as CharacterBody2D
		current = current.get_parent()
	return null

# Controla el enfriamiento y emite señales de disponibilidad.
func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	if _is_attacking:
		_visual_timer = maxf(0.0, _visual_timer - delta)
		queue_redraw()

# Indica si la habilidad de aliento de fuego esta disponible para usarse.
func is_ready() -> bool:
	return not _is_attacking and _cooldown_timer <= 0.0

# Indica si el aliento de fuego se encuentra activo actualmente.
func is_attacking() -> bool:
	return _is_attacking

# Ejecuta el ataque de Aliento de Fuego delegando en cast_dragon_breath() del jugador.
func attack() -> void:
	if not is_ready():
		return

	if _player == null:
		_player = _get_player()

	if _player != null and _player.has_method("cast_dragon_breath"):
		_cooldown_timer = fire_cooldown
		_player.cast_dragon_breath()

# Libera la instancia del controlador.
func die() -> void:
	queue_free()

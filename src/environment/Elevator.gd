class_name Elevator
extends AnimatableBody2D

enum State {
	IDLE_BOTTOM,
	ACTIVATING,
	MOVING_UP,
	WAITING_TOP,
	MOVING_DOWN,
}

@export var travel_height: float = 550.0
@export var travel_duration: float = 3.0
@export var wait_time_at_top: float = 3.5
@export var activation_delay: float = 0.4

var _state: State = State.IDLE_BOTTOM
var _bottom_position: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0
var _player_on_platform: bool = false

func _ready() -> void:
	sync_to_physics = true
	_bottom_position = global_position

func _physics_process(delta: float) -> void:
	var top_position: Vector2 = _bottom_position + Vector2(0.0, -travel_height)
	match _state:
		State.IDLE_BOTTOM:
			if _player_on_platform:
				_state = State.ACTIVATING
				_state_timer = 0.0
		State.ACTIVATING:
			if not _player_on_platform:
				_state = State.IDLE_BOTTOM
				_state_timer = 0.0
				return
			_state_timer += delta
			if _state_timer >= activation_delay:
				_state = State.MOVING_UP
				_state_timer = 0.0
		State.MOVING_UP:
			var speed: float = travel_height / maxf(travel_duration, 0.05)
			global_position.y = move_toward(global_position.y, top_position.y, speed * delta)
			if is_equal_approx(global_position.y, top_position.y):
				global_position = top_position
				_state = State.WAITING_TOP
				_state_timer = 0.0
		State.WAITING_TOP:
			_state_timer += delta
			if _state_timer >= wait_time_at_top:
				_state = State.MOVING_DOWN
				_state_timer = 0.0
		State.MOVING_DOWN:
			var speed: float = travel_height / maxf(travel_duration, 0.05)
			global_position.y = move_toward(global_position.y, _bottom_position.y, speed * delta)
			if is_equal_approx(global_position.y, _bottom_position.y):
				global_position = _bottom_position
				_state = State.IDLE_BOTTOM
				_state_timer = 0.0

func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_on_platform = true
		if _state == State.IDLE_BOTTOM:
			_state = State.ACTIVATING
			_state_timer = 0.0

func _on_trigger_area_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_on_platform = false

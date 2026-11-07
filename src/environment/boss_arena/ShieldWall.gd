class_name ShieldWall
extends StaticBody2D

@export var active_on_start: bool = false

@onready var outer_field: ColorRect = get_node_or_null("OuterField")
@onready var inner_core: ColorRect = get_node_or_null("InnerCore")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var _base_alpha: float = 0.65

func _ready() -> void:
	if active_on_start:
		activate(false)
	else:
		deactivate()

func _process(_delta: float) -> void:
	if not visible:
		return
	var t: float = Time.get_ticks_msec() * 0.005
	var pulse: float = _base_alpha + 0.2 * sin(t)
	if outer_field:
		outer_field.color.a = clampf(pulse, 0.25, 0.9)
	if inner_core:
		inner_core.color.a = clampf(0.8 + 0.15 * cos(t * 1.5), 0.5, 1.0)

func activate(animate: bool = true) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if animate:
		modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.35)
	else:
		modulate.a = 1.0

func deactivate() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

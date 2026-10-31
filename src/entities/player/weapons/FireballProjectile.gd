class_name FireballProjectile
extends Projectile

@export var max_range: float = 250.0
var _origin: Vector2

func initialize(spawn_position: Vector2, p_direction: Vector2) -> void:
	_origin = spawn_position
	super.initialize(spawn_position, p_direction)

# Mueve el proyectil y reproduce animación fade al superar el alcance máximo sin chocar.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _is_removing and global_position.distance_to(_origin) >= max_range:
		on_fade()

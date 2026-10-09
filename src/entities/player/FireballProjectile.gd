class_name FireballProjectile
extends Projectile

@export var max_range: float = 250.0
var _origin: Vector2

# Guarda la posición de origen e inicializa el proyectil base.
func initialize(spawn_position: Vector2, p_direction: Vector2) -> void:
	_origin = spawn_position
	super.initialize(spawn_position, p_direction)

# Mueve el proyectil y lo destruye al superar el alcance máximo.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if global_position.distance_to(_origin) >= max_range:
		remove()

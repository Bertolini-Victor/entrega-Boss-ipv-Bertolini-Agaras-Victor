class_name TurretProjectile
extends Projectile

@export var speed: float = 240.0:
	set(val):
		speed = val
		velocity_speed = val

# Proyectil de torreta enemiga. Hereda toda la lógica de animación (spawn, move, impact, fade) y daño al jugador de Projectile.

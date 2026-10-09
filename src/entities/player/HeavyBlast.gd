class_name HeavyBlast
extends Projectile

var _is_removing: bool = false

# Sobrescribe el manejo de colisiones con cuerpos físicos.
func _on_hitbox_body_entered(body: Node2D) -> void:
	if _is_removing:
		return
	if body.has_method("die"):
		body.die()
		remove()
	elif body.is_in_group("terrain") or body is StaticBody2D or body is TileMapLayer or body is RigidBody2D:
		remove()

# Maneja la detección de áreas para destruir proyectiles enemigos.
func _on_hitbox_area_entered(area: Area2D) -> void:
	if _is_removing:
		return
	var parent = area.get_parent()
	if parent is Projectile and parent != self and not parent is HeavyBlast and not parent is FireballProjectile:
		if area.collision_layer & 16 != 0 or parent.is_in_group("enemy_projectiles"):
			parent.remove()
			remove()

# Detiene el proyectil y reproduce la animación de impacto.
func remove() -> void:
	if _is_removing:
		return
	_is_removing = true
	super.remove()

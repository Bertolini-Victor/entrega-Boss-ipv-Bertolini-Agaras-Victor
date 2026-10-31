class_name LightningProjectile
extends Projectile

# Sobrescribe el manejo de colisiones con cuerpos físicos.
func _on_hitbox_body_entered(body: Node2D) -> void:
	if _is_removing:
		return
	if body.has_method("hit_by_lightning"):
		body.hit_by_lightning()
		on_impact()
	elif body.has_method("take_damage"):
		body.take_damage(1)
		on_impact()
	elif body.has_method("die"):
		body.die()
		on_impact()
	elif body.is_in_group("terrain") or body is StaticBody2D or body is TileMapLayer or body is RigidBody2D:
		on_impact()

# Maneja la detección de áreas para destruir proyectiles enemigos.
func _on_hitbox_area_entered(area: Area2D) -> void:
	if _is_removing:
		return
	var parent = area.get_parent()
	if parent is Projectile and parent != self and not parent is LightningProjectile and not parent is FireballProjectile:
		if area.collision_layer & 16 != 0 or parent.is_in_group("enemy_projectiles"):
			if parent.has_method("on_impact"):
				parent.on_impact()
			elif parent.has_method("remove"):
				parent.remove()
			on_impact()

func remove() -> void:
	on_impact()

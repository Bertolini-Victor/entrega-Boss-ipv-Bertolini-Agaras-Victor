class_name DragonBreath
extends Area2D

@export var damage: int = 5
@export var chi_cost: int = 3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var _hit_targets: Array[Node] = []

# Configura colisiones, señales y temporizador del aliento de fuego.
func _ready() -> void:
	# Deteccion de enemigos (layer 4) y proyectiles enemigos (layer 16)
	collision_layer = 0
	collision_mask = 20

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	if animated_sprite != null:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("fire")
	else:
		var timer := get_tree().create_timer(0.67)
		timer.timeout.connect(queue_free)

	call_deferred("_check_initial_overlaps")

# Verifica colisiones que ya esten superpuestas al instanciarse.
func _check_initial_overlaps() -> void:
	if not is_inside_tree():
		return
	for b in get_overlapping_bodies():
		_on_body_entered(b)
	for a in get_overlapping_areas():
		_on_area_entered(a)

# Libera el area al concluir la animacion del aliento.
func _on_animation_finished() -> void:
	queue_free()

# Aplica daño al cuerpo enemigo impactado si no ha sido dañado previamente.
func _on_body_entered(body: Node2D) -> void:
	if body in _hit_targets:
		return
	_hit_targets.append(body)

	if body.has_method("take_damage"):
		body.take_damage(damage)
	elif body.has_method("die"):
		body.die()

# Gestiona la destruccion de areas y proyectiles enemigos impactados.
func _on_area_entered(area: Area2D) -> void:
	var parent: Node = area.get_parent()
	if parent != null and parent != self:
		if parent is Projectile and not parent is FireballProjectile and not parent is LightningProjectile:
			if parent.has_method("on_impact"):
				parent.on_impact()
			elif parent.has_method("remove"):
				parent.remove()
			elif parent.has_method("queue_free"):
				parent.queue_free()
		elif area.collision_layer & 16 != 0:
			if area.has_method("take_damage"):
				area.take_damage(damage)

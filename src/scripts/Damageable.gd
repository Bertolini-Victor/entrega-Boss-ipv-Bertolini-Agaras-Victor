class_name Damageable
extends Node

signal died

var dead: bool = false

func die() -> void:
	if dead:
		return
	dead = true
	_on_die()
	died.emit()

func _on_die() -> void:
	pass     

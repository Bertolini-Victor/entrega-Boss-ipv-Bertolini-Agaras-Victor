class_name Goal
extends Area2D

signal level_completed

# Detecta cuando el jugador llega a la meta.
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		level_completed.emit() 

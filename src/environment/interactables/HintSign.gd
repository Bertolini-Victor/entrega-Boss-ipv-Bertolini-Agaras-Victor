class_name HintSign
extends Area2D

@export var hint_text: String = "Pista":
	set(value):
		hint_text = value
		if is_node_ready() and has_node("Label"):
			$Label.text = hint_text

# Inicializa el texto de la pista y oculta el cartel por defecto.
func _ready() -> void:
	$Label.text = hint_text
	$Label.hide()

# Muestra el texto flotante cuando el jugador se acerca al cartel.
func _on_body_entered(body: Node2D) -> void:
	if _is_player(body):
		$Label.show()

# Oculta el texto flotante cuando el jugador se aleja del cartel.
func _on_body_exited(body: Node2D) -> void:
	if _is_player(body):
		$Label.hide()

# Verifica si el cuerpo que interactua corresponde al jugador.
func _is_player(body: Node2D) -> bool:
	return body is Player or body.is_in_group("player") or body.name == "Player"

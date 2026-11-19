class_name Hurtbox
extends Area2D

## Área que recebe dano e repassa ao dono (por padrão, o nó pai).
## Serve para inimigos cujo ponto fraco não coincide com o corpo físico.

@export var dono: Node


func _ready() -> void:
	monitoring = false
	collision_layer = Camadas.INIMIGOS
	collision_mask = 0
	if dono == null:
		dono = get_parent()


func receber_dano(quantidade: int, origem: Vector2 = Vector2.INF) -> void:
	if dono != null and dono.has_method("receber_dano"):
		dono.receber_dano(quantidade, origem)

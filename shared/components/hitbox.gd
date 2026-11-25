class_name Hitbox
extends Area2D

## Área que causa dano. Do lado dos inimigos atinge o corpo do player;
## do lado do player atinge corpos e hurtboxes de inimigos.
## Enquanto `ativa`, quem continuar dentro dela leva dano de novo assim que puder
## (a invencibilidade de quem recebe é que define o intervalo).

signal acertou(alvo: Node)

enum Equipe { INIMIGO, PLAYER }

@export var equipe: Equipe = Equipe.INIMIGO
@export var dano: int = 1
@export var ativa: bool = true:
	set(value):
		ativa = value
		set_deferred("monitoring", value)


func _ready() -> void:
	monitorable = false
	if equipe == Equipe.INIMIGO:
		collision_layer = Camadas.DANO_INIMIGO
		collision_mask = Camadas.PLAYER
	else:
		collision_layer = Camadas.ATAQUE_PLAYER
		collision_mask = Camadas.INIMIGOS
	monitoring = ativa


func _physics_process(_delta: float) -> void:
	if not ativa or not monitoring:
		return
	for corpo in get_overlapping_bodies():
		_atingir(corpo)
	for area in get_overlapping_areas():
		_atingir(area)


func _atingir(alvo: Node) -> void:
	if dano <= 0 or not alvo.has_method("receber_dano"):
		return
	alvo.receber_dano(dano, global_position)
	acertou.emit(alvo)

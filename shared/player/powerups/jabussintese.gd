extends CharacterBody2D

## Jabussíntese: poder do Jabulani. Surge à frente do jogador, cai até o chão,
## brota e causa dano a cada inimigo atingido uma única vez.

@export var dano: int = 2 # dano por inimigo atingido
@export var velocidade_queda: float = 600.0 # px/s até tocar o chão

var _atingidos: Array[Node] = []

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var ataque: Area2D = $Ataque


func _ready() -> void:
	ataque.area_entered.connect(_on_alvo)
	ataque.body_entered.connect(_on_alvo)
	anim.animation_finished.connect(queue_free)
	anim.play("brotar")


func _physics_process(_delta: float) -> void:
	velocity = Vector2(0.0, velocidade_queda)
	move_and_slide()


func _on_alvo(alvo: Node) -> void:
	var receptor: Node = alvo
	if not receptor.has_method("receber_dano") and receptor.get_parent() != null:
		receptor = receptor.get_parent()
	if not receptor.has_method("receber_dano") or _atingidos.has(receptor):
		return
	_atingidos.append(receptor)
	receptor.receber_dano(dano)

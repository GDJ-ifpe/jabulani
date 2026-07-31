extends CharacterBody2D

class_name Urubu

## Urubu que atravessa a tela durante o ataque de canto do boss
## Movimento da direita para esquerda com ondulação senoidal

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_dano: Area2D = $AreaDano

@export var velocidade_base: float = -200.0  # negativo = direita pra esquerda
@export var amplitude_vertical: float = 30.0
@export var frequencia_vertical: float = 2.0
@export var dano: int = 1

var tempo_vida: float = 0.0
var ja_acertou: bool = false

func _ready() -> void:
	area_dano.body_entered.connect(_on_body_entered)
	area_dano.add_to_group("enemy_hitbox")
	
	# Garante que está flipado (voando pra esquerda)
	anim.flip_h = true
	
	# Começa um timer para se autodestruir se sair da tela
	var auto_destruir = get_tree().create_timer(8.0)
	auto_destruir.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	tempo_vida += delta
	
	# Movimento horizontal (da direita pra esquerda)
	velocity.x = velocidade_base
	
	# Ondulação vertical senoidal
	velocity.y = sin(tempo_vida * TAU * frequencia_vertical) * amplitude_vertical * 2
	
	move_and_slide()

func _on_body_entered(body: Node2D) -> void:
	if ja_acertou:
		return
	
	if body.is_in_group("player"):
		ja_acertou = true
		if body.has_method("receber_dano"):
			body.receber_dano(dano)

extends Node2D

class_name Pena

## Projétil de pena do boss
## Dispara em uma direção, depois retorna ao ponto de origem

@onready var area_dano: Area2D = $AreaDano
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direcao: Vector2 = Vector2.RIGHT
var velocidade: float = 250.0
var distancia_maxima: float = 300.0
var distancia_percorrida: float = 0.0

var boss_ref: Node2D = null
var posicao_origem: Vector2 = Vector2.ZERO
var retornando: bool = false
var velocidade_retorno: float = 300.0

var dano: int = 1
var ja_acertou: bool = false

func _ready() -> void:
	area_dano.body_entered.connect(_on_body_entered)
	area_dano.add_to_group("projectile")

func iniciar(dir: Vector2, vel: float, dist_max: float, boss: Node2D) -> void:
	direcao = dir
	velocidade = vel
	distancia_maxima = dist_max
	boss_ref = boss
	posicao_origem = global_position
	
	# Rotaciona sprite para apontar na direção do movimento
	rotation = dir.angle()

func retornar_ao_boss() -> void:
	retornando = true

func _physics_process(delta: float) -> void:
	if boss_ref == null:
		queue_free()
		return
	
	if retornando:
		_seguir_boss(delta)
	else:
		_mover_para_frente(delta)

func _mover_para_frente(delta: float) -> void:
	var movimento = direcao * velocidade * delta
	global_position += movimento
	distancia_percorrida += movimento.length()
	
	# Mantém a rotação alinhada com a direção do movimento
	rotation = direcao.angle()
	
	# Se atingiu distância máxima sem retornar, volta automático
	if distancia_percorrida >= distancia_maxima:
		retornando = true

func _seguir_boss(delta: float) -> void:
	if not is_instance_valid(boss_ref):
		queue_free()
		return
	
	# Move em direção ao boss
	var diff = boss_ref.global_position - global_position
	var dist = diff.length()
	
	if dist < 30:
		# Chegou no boss, some
		queue_free()
		return
	
	var direcao_boss = diff.normalized()
	global_position += direcao_boss * velocidade_retorno * delta
	# Rotaciona para apontar na direção do retorno
	rotation = direcao_boss.angle()

func _on_body_entered(body: Node2D) -> void:
	if ja_acertou:
		return
	
	if body.is_in_group("player"):
		ja_acertou = true
		if body.has_method("receber_dano"):
			body.receber_dano(dano)
		
		# Se acertou o player, mesmo assim volta ao boss
		if not retornando:
			retornando = true
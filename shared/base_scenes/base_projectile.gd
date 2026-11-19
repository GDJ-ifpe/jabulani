class_name BaseProjectile
extends Hitbox

## Base dos projéteis: direção, velocidade, dano (herdado de Hitbox) e tempo de vida.
## Modos: reta, arco (cai com a gravidade, como uma granada) e teleguiado leve
## (vira aos poucos na direção do alvo). `retornar()` faz o projétil voltar a um nó.

signal destruido

enum Modo { RETA, ARCO, TELEGUIADO }

@export var modo: Modo = Modo.RETA
@export var velocidade: float = 200.0 # px/s
@export var tempo_de_vida: float = 6.0 # s até sumir sozinho
@export var gravidade: float = 600.0 # px/s² (modo ARCO)
@export var curva_graus_por_segundo: float = 90.0 # modo TELEGUIADO
@export var some_ao_acertar: bool = true
@export var some_no_terreno: bool = true
@export var gira_com_a_direcao: bool = true
@export var distancia_de_chegada: float = 16.0 # ao retornar, some a esta distância do destino (px)

var velocidade_atual: Vector2 = Vector2.ZERO
var alvo: Node2D = null # modo TELEGUIADO
var retornando: bool = false

var _destino_do_retorno: Node2D = null
var _velocidade_de_retorno: float = 0.0
var _vida: float = 0.0
var _destruindo: bool = false


func _ready() -> void:
	super()
	add_to_group("projectile")
	if some_no_terreno:
		collision_mask |= Camadas.TERRENO
		body_entered.connect(_on_corpo)
	acertou.connect(_on_acertou)


## Dispara na direção dada. `velocidade_inicial` < 0 usa a velocidade exportada.
func lancar(direcao: Vector2, velocidade_inicial: float = -1.0) -> void:
	if velocidade_inicial >= 0.0:
		velocidade = velocidade_inicial
	velocidade_atual = direcao.normalized() * velocidade
	_alinhar()


## Passa a voar de volta até `destino` e some ao chegar.
func retornar(destino: Node2D, velocidade_de_retorno: float = -1.0) -> void:
	retornando = true
	_destino_do_retorno = destino
	_velocidade_de_retorno = velocidade_de_retorno if velocidade_de_retorno >= 0.0 else velocidade


func _physics_process(delta: float) -> void:
	super(delta)
	_vida += delta
	if _vida >= tempo_de_vida:
		destruir()
		return
	if retornando:
		_mover_de_volta(delta)
	else:
		_mover(delta)
	_alinhar()


func _mover(delta: float) -> void:
	match modo:
		Modo.ARCO:
			velocidade_atual.y += gravidade * delta
		Modo.TELEGUIADO:
			if is_instance_valid(alvo):
				var desejada: float = (alvo.global_position - global_position).angle()
				var passo: float = deg_to_rad(curva_graus_por_segundo) * delta
				velocidade_atual = Vector2.from_angle(rotate_toward(velocidade_atual.angle(), desejada, passo)) * velocidade
	global_position += velocidade_atual * delta


func _mover_de_volta(delta: float) -> void:
	if not is_instance_valid(_destino_do_retorno):
		destruir()
		return
	var diferenca: Vector2 = _destino_do_retorno.global_position - global_position
	if diferenca.length() <= distancia_de_chegada:
		destruir()
		return
	velocidade_atual = diferenca.normalized() * _velocidade_de_retorno
	global_position += velocidade_atual * delta


func _alinhar() -> void:
	if gira_com_a_direcao and velocidade_atual != Vector2.ZERO:
		rotation = velocidade_atual.angle()


func _on_corpo(corpo: Node2D) -> void:
	if not corpo.is_in_group("player"):
		_ao_tocar_terreno()


func _on_acertou(_alvo: Node) -> void:
	if some_ao_acertar:
		destruir()


## Gancho: o que acontece ao bater no cenário (padrão: some).
func _ao_tocar_terreno() -> void:
	destruir()


func destruir() -> void:
	if _destruindo:
		return
	_destruindo = true
	ativa = false
	destruido.emit()
	queue_free()

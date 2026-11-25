class_name Pena
extends BaseProjectile

## Pena do Carlitos. Vai em linha reta até a distância máxima, para um instante e é puxada
## de volta para o chefe. Fere na ida e na volta; atravessa o cenário e não some ao acertar.

@export var distancia_maxima: float = 440.0 # px
@export var pausa_antes_de_voltar: float = 0.25 # s parada no ponto mais distante
@export var velocidade_de_retorno: float = 300.0 # px/s

var dono: Node2D = null
var _percorrido: float = 0.0
var _pausa: float = -1.0 # < 0: ainda indo


func iniciar(direcao: Vector2, velocidade_de_ida: float, distancia: float, chefe: Node2D, velocidade_de_volta: float = -1.0) -> void:
	dono = chefe
	distancia_maxima = distancia
	if velocidade_de_volta >= 0.0:
		velocidade_de_retorno = velocidade_de_volta
	lancar(direcao, velocidade_de_ida)


func retornar_ao_boss() -> void:
	if not retornando:
		retornar(dono, velocidade_de_retorno)


func _mover(delta: float) -> void:
	if not is_instance_valid(dono):
		destruir()
		return
	if _pausa >= 0.0:
		_pausa -= delta
		if _pausa < 0.0:
			retornar_ao_boss()
		return
	super(delta)
	_percorrido += velocidade_atual.length() * delta
	if _percorrido >= distancia_maxima:
		_pausa = pausa_antes_de_voltar

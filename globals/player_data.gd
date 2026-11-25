extends Node

## Fonte única do estado do jogador: vida, pontos, pontos de poder e dano do golpe.
## Player, HUD e GameManager leem e escrevem aqui; ninguém guarda cópia própria.

signal hp_changed(novo_hp: int)
signal player_died
signal pontos_changed(novos_pontos: int)
signal power_changed(novo_power: int)

var max_hp: int = 6 # vida máxima (6 corações na HUD)
var max_power_points: int = 6 # pontos de poder (6 cascos na HUD)
var dano_golpe: int = 1 # dano de cada golpe de canudo

var hp: int = max_hp:
	set(value):
		var anterior: int = hp
		hp = clampi(value, 0, max_hp)
		if hp != anterior:
			hp_changed.emit(hp)
			if hp == 0:
				player_died.emit()

var pontos: int = 0:
	set(value):
		pontos = maxi(value, 0)
		pontos_changed.emit(pontos)

var power_points: int = max_power_points:
	set(value):
		power_points = clampi(value, 0, max_power_points)
		power_changed.emit(power_points)

# Pontuação no momento em que a arena atual começou (para recomeçar a arena).
var _pontos_no_inicio_da_arena: int = 0


func esta_morto() -> bool:
	return hp <= 0


func adicionar_pontos(quantidade: int) -> void:
	pontos += quantidade


func gastar_poder(quantidade: int = 1) -> bool:
	if power_points < quantidade:
		return false
	power_points -= quantidade
	return true


## Começa um jogo do zero (menu -> Jogar).
func novo_jogo() -> void:
	pontos = 0
	_pontos_no_inicio_da_arena = 0
	_restaurar_vida_e_poder()


## Chamado ao entrar numa arena: guarda os pontos e enche a vida.
func iniciar_arena() -> void:
	_pontos_no_inicio_da_arena = pontos
	_restaurar_vida_e_poder()


## Chamado ao recomeçar a arena depois de morrer: vida cheia e pontos de quando a arena começou.
func reiniciar_arena() -> void:
	pontos = _pontos_no_inicio_da_arena
	_restaurar_vida_e_poder()


func _restaurar_vida_e_poder() -> void:
	hp = max_hp
	power_points = max_power_points

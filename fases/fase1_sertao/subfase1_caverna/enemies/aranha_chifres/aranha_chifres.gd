extends BaseEnemy

## Aranha Armadeira - Chifres. Teia Inteligente: anda depressa só pelos waypoints da própria
## teia, ergue paredes temporárias em pontos pré-definidos e mantém a saída bloqueada com
## uma parede que só some quando ela é derrotada. Morde quem chega perto.

enum Estado { PARADA, ANDANDO, TECENDO, ATACANDO }

@export_group("Teia")
## Caminho da aranha, em posições globais. Editável aqui ou recebido do SpawnPoint (tipo TEIA).
@export var waypoints: Array[Vector2] = []
## Pontos (posições globais, na base da parede) onde ela pode erguer paredes temporárias.
@export var pontos_de_parede: Array[Vector2] = []
@export var cena_parede: PackedScene
@export var pausa_no_waypoint: float = 0.7 # s parada em cada ponto da teia
@export var intervalo_entre_paredes: float = 6.0 # s entre uma parede e outra
@export var duracao_parede: float = 5.0 # s de vida de cada parede temporária
@export var tempo_tecendo: float = 0.6 # s parada tecendo (aviso antes de a parede surgir)
@export var distancia_minima_do_player: float = 28.0 # não ergue parede em cima do jogador (px)
@export var cor_fio: Color = Color(1.0, 1.0, 1.0, 0.55)

@export_group("Mordida")
@export var dano_mordida: int = 1
@export var distancia_de_ataque: float = 52.0 # px
@export var tempo_preparo_mordida: float = 0.3 # aviso (início da animação) antes de a mordida valer
@export var duracao_mordida: float = 0.2 # janela em que a mordida fere (s)
@export var recarga_mordida: float = 1.6 # s

var estado: Estado = Estado.PARADA
var _tempo_estado: float = 0.0
var _indice: int = 0
var _sentido: int = 1
var _tempo_para_parede: float = 0.0
var _recarga: float = 0.0
var _parede_da_saida: Node = null
var _posicao_parede_saida: Vector2 = Vector2.INF
var _fio: Line2D = null

@onready var mordida: Hitbox = $Mordida


func configurar_spawn(ponto: SpawnPoint) -> void:
	var caminho: Array[Vector2] = ponto.obter_waypoints()
	if not caminho.is_empty():
		waypoints = caminho
	var paredes: Array[Vector2] = ponto.obter_pontos_de_parede()
	if not paredes.is_empty():
		pontos_de_parede = paredes
	if ponto.ponto_parede_saida != null:
		_posicao_parede_saida = ponto.ponto_parede_saida.global_position


func _inicializar() -> void:
	usa_gravidade = false
	collision_mask = 0 # só se move pela teia
	mordida.dano = dano_mordida
	mordida.ativa = false
	_tempo_para_parede = intervalo_entre_paredes
	if not waypoints.is_empty():
		global_position = waypoints[0]
	_desenhar_fio()
	if _posicao_parede_saida != Vector2.INF:
		_parede_da_saida = _criar_parede(_posicao_parede_saida, 0.0)
		if _parede_da_saida != null:
			_parede_da_saida.add_to_group("bloqueio_saida")
	_mudar_estado(Estado.PARADA)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tempo_estado += delta
	_recarga = maxf(_recarga - delta, 0.0)
	_tempo_para_parede = maxf(_tempo_para_parede - delta, 0.0)

	match estado:
		Estado.PARADA:
			if _pode_morder():
				_mudar_estado(Estado.ATACANDO)
			elif _tempo_para_parede <= 0.0 and _ponto_para_parede() != Vector2.INF:
				_mudar_estado(Estado.TECENDO)
			elif _tempo_estado >= pausa_no_waypoint and waypoints.size() > 1:
				_proximo_waypoint()
				_mudar_estado(Estado.ANDANDO)
		Estado.ANDANDO:
			if _pode_morder():
				_mudar_estado(Estado.ATACANDO)
			else:
				_andar(delta)
		Estado.TECENDO:
			if _tempo_estado >= tempo_tecendo:
				var ponto: Vector2 = _ponto_para_parede()
				if ponto != Vector2.INF:
					_criar_parede(ponto, duracao_parede)
				_tempo_para_parede = intervalo_entre_paredes
				_mudar_estado(Estado.PARADA)
		Estado.ATACANDO:
			var mordendo: bool = _tempo_estado >= tempo_preparo_mordida and _tempo_estado < tempo_preparo_mordida + duracao_mordida
			if mordida.ativa != mordendo:
				mordida.ativa = mordendo
			if _tempo_estado >= tempo_preparo_mordida + duracao_mordida + 0.15:
				_recarga = recarga_mordida
				_mudar_estado(Estado.PARADA)


func _andar(delta: float) -> void:
	var alvo: Vector2 = waypoints[_indice]
	if absf(alvo.x - global_position.x) > 1.0:
		direcao = signf(alvo.x - global_position.x)
		_atualizar_flip()
	global_position = global_position.move_toward(alvo, velocidade * delta)
	if global_position.distance_to(alvo) < 0.5:
		_mudar_estado(Estado.PARADA)


func _proximo_waypoint() -> void:
	if _indice + _sentido < 0 or _indice + _sentido >= waypoints.size():
		_sentido = -_sentido
	_indice += _sentido


func _pode_morder() -> bool:
	return _recarga <= 0.0 and distancia_ao_player() <= distancia_de_ataque


func _mudar_estado(novo: Estado) -> void:
	estado = novo
	_tempo_estado = 0.0
	mordida.ativa = false
	match novo:
		Estado.PARADA, Estado.TECENDO:
			_play_anim("parado")
		Estado.ANDANDO:
			_play_anim("andando")
		Estado.ATACANDO:
			if is_instance_valid(player):
				direcao = signf(player.global_position.x - global_position.x)
				_atualizar_flip()
			mordida.scale.x = direcao if direcao != 0.0 else 1.0
			anim.stop()
			anim.play("ataque")
			AudioManager.tocar_sfx(&"TODO_AUDIO_aranha_ataque", -4.0)


# ---------------------------------------------------------------- paredes de teia

## Ponto pré-definido mais próximo do jogador que não esteja em cima dele nem já ocupado.
func _ponto_para_parede() -> Vector2:
	var melhor: Vector2 = Vector2.INF
	var menor_distancia: float = INF
	var alvo: Vector2 = player.global_position if is_instance_valid(player) else global_position
	for ponto in pontos_de_parede:
		if absf(ponto.x - alvo.x) < distancia_minima_do_player:
			continue
		if _ha_parede_em(ponto):
			continue
		var distancia: float = ponto.distance_to(alvo)
		if distancia < menor_distancia:
			menor_distancia = distancia
			melhor = ponto
	return melhor


func _ha_parede_em(ponto: Vector2) -> bool:
	for parede in get_tree().get_nodes_in_group("parede_teia"):
		if (parede as Node2D).global_position.distance_to(ponto) < 4.0:
			return true
	return false


func _criar_parede(posicao: Vector2, duracao: float) -> Node:
	if cena_parede == null:
		return null
	var parede: Node2D = cena_parede.instantiate()
	parede.set("duracao", duracao)
	parede.add_to_group("parede_teia")
	get_parent().add_child(parede)
	parede.global_position = posicao
	return parede


func _desenhar_fio() -> void:
	if waypoints.size() < 2:
		return
	_fio = Line2D.new()
	_fio.name = "TODO_ARTE_teia"
	_fio.top_level = true
	_fio.width = 1.0
	_fio.default_color = cor_fio
	_fio.z_index = -1
	_fio.points = PackedVector2Array(waypoints)
	add_child(_fio)


func _ao_levar_hit() -> void:
	mordida.ativa = false
	if estado == Estado.ATACANDO or estado == Estado.TECENDO:
		_mudar_estado(Estado.PARADA)
	AudioManager.tocar_sfx(&"TODO_AUDIO_aranha_hit", -4.0)


func _ao_morrer() -> void:
	mordida.ativa = false
	# A parede da saída some quando a aranha é derrotada.
	if is_instance_valid(_parede_da_saida) and _parede_da_saida.has_method("remover"):
		_parede_da_saida.remover()
	if _fio != null:
		create_tween().tween_property(_fio, "modulate:a", 0.0, duracao_morte)
	AudioManager.tocar_sfx(&"TODO_AUDIO_aranha_morte")

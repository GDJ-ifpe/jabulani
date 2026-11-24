extends Node2D

## Gangue "Roll 17": as rolinhas sempre aparecem em grupo e atiram todas ao mesmo tempo.
## Este nó é o grupo: cria as rolinhas em formação, paira perto do jogador e comanda o
## disparo sincronizado (todas piscam no aviso e disparam juntas). Some quando a última cai.

@export var cena_rolinha: PackedScene
@export var quantidade: int = 3 # rolinhas por grupo
@export var espacamento: Vector2 = Vector2(26.0, 12.0) # distância entre vizinhas na formação (px)

@export_group("Voo")
@export var velocidade: float = 110.0 # px/s
@export var distancia_horizontal: float = 120.0 # paira a esta distância do jogador (px)
@export var deslocamento_de_altura: float = 40.0 # desce isto abaixo do ponto de entrada para pairar (px)
@export var margem_da_arena: float = 48.0 # não passa desta distância das bordas (px)

@export_group("Disparo")
@export var primeiro_disparo: float = 3.0 # s entre chegar e o primeiro disparo
@export var intervalo_entre_disparos: float = 5.0 # s
@export var tempo_de_aviso: float = 0.9 # s piscando antes de atirar
@export var alcance_de_disparo: float = 220.0 # só atira com o jogador a até esta distância horizontal (px)

var _rolinhas: Array = [] # sem tipo: pode conter rolinhas que já saíram da cena
var _player: Node2D = null
var _espera: float = 0.0
var _avisando: bool = false
var _lado: float = 1.0
var _altura: float = 0.0
var _limites: Rect2 = Rect2(0.0, 0.0, 640.0, 360.0)
var _ponto_de_spawn: SpawnPoint = null


func configurar_spawn(ponto: SpawnPoint) -> void:
	_ponto_de_spawn = ponto


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null and "limites" in arena:
		_limites = Rect2(arena.limites)
	_altura = global_position.y + deslocamento_de_altura
	_lado = -1.0 if global_position.x < _limites.get_center().x else 1.0
	_espera = primeiro_disparo
	if _ponto_de_spawn != null and _ponto_de_spawn.ocupante == self:
		_ponto_de_spawn.liberar()
	if cena_rolinha == null:
		return
	for i in quantidade:
		var rolinha: Node2D = cena_rolinha.instantiate()
		# Formação em "V": a primeira no meio, as outras alternando os lados.
		var passo: int = ceili(i * 0.5)
		var lado: float = 1.0 if i % 2 == 1 else -1.0
		rolinha.position = Vector2(lado * passo * espacamento.x, -passo * espacamento.y)
		add_child(rolinha)
		_rolinhas.append(rolinha)


func _physics_process(delta: float) -> void:
	_rolinhas = _rolinhas.filter(func(r: Variant) -> bool: return is_instance_valid(r) and not r.is_dead)
	if _rolinhas.is_empty():
		if get_child_count() == 0:
			queue_free()
		return
	_voar(delta)
	if not _avisando and not _no_alcance():
		return
	_espera -= delta
	if _espera > 0.0:
		return
	if not _avisando:
		_avisando = true
		_espera = tempo_de_aviso
		for rolinha in _rolinhas:
			rolinha.avisar(tempo_de_aviso)
	else:
		_avisando = false
		_espera = intervalo_entre_disparos
		if is_instance_valid(_player):
			for rolinha in _rolinhas:
				rolinha.disparar(_player)
			AudioManager.tocar_sfx(&"TODO_AUDIO_rolinha_disparo", -4.0)


func _no_alcance() -> bool:
	return is_instance_valid(_player) and absf(_player.global_position.x - global_position.x) <= alcance_de_disparo


func _voar(delta: float) -> void:
	if _avisando or not is_instance_valid(_player):
		return
	var alvo_x: float = _player.global_position.x + _lado * distancia_horizontal
	alvo_x = clampf(alvo_x, _limites.position.x + margem_da_arena, _limites.end.x - margem_da_arena)
	var alvo := Vector2(alvo_x, _altura)
	global_position = global_position.move_toward(alvo, velocidade * delta)
	var olhando: float = signf(_player.global_position.x - global_position.x)
	for rolinha in _rolinhas:
		rolinha.olhar_para(olhando)

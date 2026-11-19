class_name Urubu
extends BaseEnemy

## Urubu. Dois modos, na mesma cena:
## - CARNICEIRO (Superfície): voa de um lado ao outro da arena e, quando passa por cima do
##   jogador, para um instante (aviso) e solta carniça em linha reta para baixo.
## - ATRAVESSAR (canto do Carlitos): cruza o cenário uma vez, sem soltar nada, e vai embora.
##   Fere só por contato; o jogador deve desviar.

enum Modo { CARNICEIRO, ATRAVESSAR }
enum Estado { VOANDO, PREPARO }

@export var modo: Modo = Modo.CARNICEIRO

@export_group("Voo")
@export var amplitude_vertical: float = 8.0 # ondulação do voo (px)
@export var ondulacoes_por_segundo: float = 0.7
@export var margem_de_volta: float = 32.0 # distância da borda da arena em que dá meia-volta (px)
@export var margem_de_saida: float = 80.0 # modo ATRAVESSAR: some a esta distância fora da arena (px)

@export_group("Carniça")
@export var cena_carnica: PackedScene
@export var dano_carnica: int = 1 # dano da carniça
@export var tolerancia_horizontal: float = 14.0 # considera "em cima do jogador" dentro desta distância (px)
@export var tempo_preparo: float = 0.45 # aviso (piscando, parado no ar) antes de soltar (s)
@export var recarga_carnica: float = 2.5 # s até carregar outra carniça
@export var ponto_de_soltura: Vector2 = Vector2(0.0, 16.0) # de onde a carniça sai, relativo ao urubu
@export var cor_aviso: Color = Color(1.0, 0.55, 0.3)

var estado: Estado = Estado.VOANDO
var _tempo_estado: float = 0.0
var _tempo_de_voo: float = 0.0
var _altura_base: float = 0.0
var _recarga: float = 0.0
var _limites: Rect2 = Rect2(0.0, 0.0, 640.0, 360.0)
var _ponto_de_spawn: SpawnPoint = null

@onready var carga: Node2D = get_node_or_null("Carga")


func configurar_spawn(ponto: SpawnPoint) -> void:
	_ponto_de_spawn = ponto


## Prepara o urubu para cruzar o cenário uma vez (chamado antes de entrar na cena).
func preparar_travessia(sentido: float, velocidade_de_voo: float) -> void:
	modo = Modo.ATRAVESSAR
	direcao = signf(sentido) if sentido != 0.0 else -1.0
	velocidade = velocidade_de_voo
	pontos = 0


func _inicializar() -> void:
	usa_gravidade = false
	collision_mask = 0 # voa livre, sem esbarrar no cenário
	_altura_base = global_position.y
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null and "limites" in arena:
		_limites = Rect2(arena.limites)
	if modo == Modo.CARNICEIRO:
		# O ponto de entrada fica livre assim que o urubu sai voando.
		if _ponto_de_spawn != null and _ponto_de_spawn.ocupante == self:
			_ponto_de_spawn.liberar()
		direcao = 1.0 if global_position.x < _limites.get_center().x else -1.0
		_recarga = recarga_carnica * 0.5
	if carga != null:
		carga.visible = false
	_atualizar_flip()
	_play_anim("voando")


func _physics_process(delta: float) -> void:
	if is_dead:
		# Derrotado: cai girando até sumir.
		velocity.y += get_gravity().y * delta
		move_and_slide()
		return
	_tempo_estado += delta
	_tempo_de_voo += delta
	_recarga = maxf(_recarga - delta, 0.0)
	if carga != null and modo == Modo.CARNICEIRO:
		carga.visible = _recarga <= 0.0

	match estado:
		Estado.VOANDO:
			_voar()
			if modo == Modo.CARNICEIRO and _sobre_o_player():
				_mudar_estado(Estado.PREPARO)
		Estado.PREPARO:
			velocity = Vector2.ZERO
			if anim != null:
				anim.modulate = cor_aviso if fmod(_tempo_estado, 0.16) < 0.08 else Color.WHITE
			if _tempo_estado >= tempo_preparo:
				_soltar_carnica()
				_mudar_estado(Estado.VOANDO)
	move_and_slide()


func _voar() -> void:
	var alvo_y: float = _altura_base + sin(_tempo_de_voo * ondulacoes_por_segundo * TAU) * amplitude_vertical
	velocity = Vector2(direcao * velocidade, (alvo_y - global_position.y) * 6.0)
	if modo == Modo.ATRAVESSAR:
		if global_position.x < _limites.position.x - margem_de_saida or global_position.x > _limites.end.x + margem_de_saida:
			queue_free()
		return
	if direcao > 0.0 and global_position.x >= _limites.end.x - margem_de_volta:
		direcao = -1.0
		_atualizar_flip()
	elif direcao < 0.0 and global_position.x <= _limites.position.x + margem_de_volta:
		direcao = 1.0
		_atualizar_flip()


func _sobre_o_player() -> bool:
	if _recarga > 0.0 or cena_carnica == null or not is_instance_valid(player):
		return false
	if player.global_position.y <= global_position.y:
		return false
	return absf(player.global_position.x - global_position.x) <= tolerancia_horizontal


func _mudar_estado(novo: Estado) -> void:
	estado = novo
	_tempo_estado = 0.0
	if anim != null:
		anim.modulate = Color.WHITE
	if novo == Estado.PREPARO:
		AudioManager.tocar_sfx(&"TODO_AUDIO_urubu_aviso", -8.0)


func _soltar_carnica() -> void:
	_recarga = recarga_carnica
	var carnica := cena_carnica.instantiate() as BaseProjectile
	if carnica == null:
		return
	carnica.dano = dano_carnica
	get_parent().add_child(carnica)
	carnica.global_position = global_position + ponto_de_soltura
	carnica.lancar(Vector2.DOWN)
	AudioManager.tocar_sfx(&"TODO_AUDIO_urubu_carnica", -6.0)


func _ao_levar_hit() -> void:
	if estado == Estado.PREPARO:
		_recarga = recarga_carnica
		_mudar_estado(Estado.VOANDO)
	AudioManager.tocar_sfx(&"TODO_AUDIO_urubu_hit", -6.0)


func _ao_morrer() -> void:
	if carga != null:
		carga.visible = false
	if anim != null:
		anim.modulate = Color.WHITE
	AudioManager.tocar_sfx(&"TODO_AUDIO_urubu_morte")

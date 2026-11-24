extends BaseEnemy

## Morcego - Bruce. Fica pendurado na estalactite, voa até perto do jogador e solta o
## Grito Ultrassônico: um cone que desorienta e empurra (pode derrubar de plataformas).
## O cone só fica ativo na janela do grito; antes dele há um aviso visual (preparo).

enum Estado { PENDURADO, VOO, PREPARO, GRITO, RECUPERACAO }

@export_group("Comportamento")
@export var tempo_pendurado: float = 2.5 # s pendurado antes de sair voando
@export var raio_despertar: float = 120.0 # acorda antes se o jogador chegar a esta distância (px)
@export var distancia_de_ataque: float = 80.0 # distância horizontal em que paira antes de gritar (px)
@export var altura_de_voo: float = 40.0 # quanto acima do jogador ele paira (px)

@export_group("Grito Ultrassônico")
@export var tempo_preparo: float = 0.8 # aviso antes do grito (s)
@export var duracao_grito: float = 0.3 # janela em que o cone está ativo (s)
@export var tempo_recuperacao: float = 2.2 # pausa depois do grito (s)
@export var alcance_cone: float = 120.0 # comprimento do cone (px)
@export var abertura_cone_graus: float = 50.0 # ângulo total do cone
@export var duracao_desorientacao: float = 1.5 # s de desorientação no jogador
@export var forca_empurrao: float = 200.0 # impulso aplicado ao jogador (px/s)
@export var dano_grito: int = 0 # o grito desorienta e empurra; dano opcional
@export var cor_aviso: Color = Color(0.8, 0.6, 1.0, 0.25)
@export var cor_grito: Color = Color(0.9, 0.8, 1.0, 0.6)

var estado: Estado = Estado.PENDURADO
var _tempo_estado: float = 0.0
var _lado: float = 1.0 # lado do jogador em que o morcego paira
var _direcao_grito: Vector2 = Vector2.RIGHT
var _grito_acertou: bool = false
var _ponto_de_spawn: SpawnPoint = null

@onready var cone: Area2D = $ConeGrito
@onready var cone_forma: CollisionPolygon2D = $ConeGrito/CollisionPolygon2D
@onready var cone_visual: Polygon2D = $ConeGrito/ConeVisual


func configurar_spawn(ponto: SpawnPoint) -> void:
	_ponto_de_spawn = ponto


func _inicializar() -> void:
	usa_gravidade = false
	collision_mask = 0 # voa livre, sem esbarrar no cenário
	var meia_largura: float = alcance_cone * tan(deg_to_rad(abertura_cone_graus * 0.5))
	var vertices := PackedVector2Array([Vector2.ZERO, Vector2(alcance_cone, -meia_largura), Vector2(alcance_cone, meia_largura)])
	cone_forma.polygon = vertices
	cone_visual.polygon = vertices
	# O polígono do cone nunca muda de cor nem é escondido: aviso, grito e "desligado" mudam só
	# a "modulate" (transparente quando desligado). Trocar a cor ou esconder e mostrar de novo
	# recria a malha, e no navegador (WebGL) isso falha e o aviso pode não aparecer.
	cone.collision_layer = Camadas.DANO_INIMIGO
	cone.collision_mask = Camadas.PLAYER
	_desativar_cone()
	_mudar_estado(Estado.PENDURADO)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tempo_estado += delta
	match estado:
		Estado.PENDURADO:
			velocity = Vector2.ZERO
			if _tempo_estado >= tempo_pendurado or distancia_ao_player() <= raio_despertar:
				_soltar_da_estalactite()
				_mudar_estado(Estado.VOO)
		Estado.VOO:
			_voar()
		Estado.PREPARO:
			velocity = Vector2.ZERO
			# Pisca o aviso do cone.
			cone_visual.modulate.a = cor_aviso.a * (0.5 + 0.5 * sin(_tempo_estado * 30.0))
			if _tempo_estado >= tempo_preparo:
				_mudar_estado(Estado.GRITO)
		Estado.GRITO:
			velocity = Vector2.ZERO
			_verificar_cone()
			if _tempo_estado >= duracao_grito:
				_mudar_estado(Estado.RECUPERACAO)
		Estado.RECUPERACAO:
			velocity = velocity.move_toward(Vector2.ZERO, velocidade * 4.0 * delta)
			if _tempo_estado >= tempo_recuperacao:
				_mudar_estado(Estado.VOO)
	move_and_slide()


func _voar() -> void:
	if not is_instance_valid(player):
		_encontrar_player()
		velocity = Vector2.ZERO
		return
	var alvo: Vector2 = player.global_position + Vector2(_lado * distancia_de_ataque, -altura_de_voo)
	var diferenca: Vector2 = alvo - global_position
	direcao = signf(player.global_position.x - global_position.x)
	_atualizar_flip()
	if diferenca.length() <= 10.0:
		_mudar_estado(Estado.PREPARO)
		return
	velocity = diferenca.normalized() * velocidade


func _mudar_estado(novo: Estado) -> void:
	estado = novo
	_tempo_estado = 0.0
	match novo:
		Estado.PENDURADO:
			_play_anim("pendurado")
		Estado.VOO:
			_desativar_cone()
			_play_anim("voando")
			if is_instance_valid(player):
				_lado = -1.0 if global_position.x < player.global_position.x else 1.0
		Estado.PREPARO:
			_play_anim("preparo")
			_direcao_grito = Vector2(-_lado, 0.0)
			if is_instance_valid(player):
				_direcao_grito = (player.global_position - global_position).normalized()
			cone.rotation = _direcao_grito.angle()
			cone_visual.modulate = cor_aviso
		Estado.GRITO:
			_grito_acertou = false
			cone_visual.modulate = cor_grito
			cone.set_deferred("monitoring", true)
			AudioManager.tocar_sfx(&"TODO_AUDIO_grito_ultrassonico")
		Estado.RECUPERACAO:
			_desativar_cone()
			_play_anim("voando")


func _verificar_cone() -> void:
	if _grito_acertou or not cone.monitoring:
		return
	for corpo in cone.get_overlapping_bodies():
		if not corpo.is_in_group("player"):
			continue
		_grito_acertou = true
		# O inimigo decide quando; o player aplica o efeito em si mesmo.
		if corpo.has_method("aplicar_desorientacao"):
			corpo.aplicar_desorientacao(duracao_desorientacao)
		if corpo.has_method("aplicar_impulso"):
			corpo.aplicar_impulso(Vector2(signf(_direcao_grito.x) * forca_empurrao, -forca_empurrao * 0.35))
		if dano_grito > 0 and corpo.has_method("receber_dano"):
			corpo.receber_dano(dano_grito, global_position)
		return


func _desativar_cone() -> void:
	cone.set_deferred("monitoring", false)
	cone_visual.modulate.a = 0.0


func _soltar_da_estalactite() -> void:
	if _ponto_de_spawn != null and _ponto_de_spawn.ocupante == self:
		_ponto_de_spawn.liberar()
	_ponto_de_spawn = null


func _ao_levar_hit() -> void:
	# Um golpe interrompe o preparo ou o grito.
	if estado == Estado.PENDURADO:
		_soltar_da_estalactite()
	_mudar_estado(Estado.RECUPERACAO)


func _ao_morrer() -> void:
	_desativar_cone()
	_soltar_da_estalactite()
	AudioManager.tocar_sfx(&"TODO_AUDIO_morcego_morte")

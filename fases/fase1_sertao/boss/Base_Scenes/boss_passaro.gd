class_name BossPassaro
extends BaseBoss

## Carlitos, O Rasga Mortalha de Monóculo - chefe do Sertão.
## Voa por um caminho (Path2D: o chefe é filho de um PathFollow2D; sem ele, só paira) e repete o ciclo:
##   "Se Ter Pena Matasse": 5 a 7 penas em leque na direção do jogador; ao chegar à distância
##       máxima elas são puxadas de volta e também ferem na volta; faz isso 1 ou 2 vezes
##   -> CANSADO: pousa no chão, ao alcance do golpe (a brecha para o jogador atacar)
##   "Rap do Zé Felipe": canta de 5 a 10 s; 3 s depois de começar, urubus passam a atravessar
##       o cenário (cada um com aviso na borda de onde vem)
##   -> CANSADO -> repete.
## A rajada de vento tem estado reservado, mas está desligada: não faz parte dos ataques atuais.

enum Estado { APRESENTACAO, VOANDO, PENAS, CANSADO, CANTANDO, RAJADA_DE_VENTO, MORRENDO }
enum FasePenas { PREPARO, AGUARDANDO_VOLTA, INTERVALO }
enum FaseCansado { DESCENDO, NO_CHAO, SUBINDO }

@export_group("Voo")
@export var velocidade_voo: float = 70.0 # velocidade ao longo do caminho (px/s) - "velocidade média"
@export var amplitude_senoidal: float = 20.0 # sem caminho: oscilação vertical (px)
@export var frequencia_senoidal: float = 0.5 # sem caminho: oscilações por segundo
@export var tempo_entre_ataques: float = 1.5 # s voando entre o fim do cansaço e o ataque seguinte

@export_group("Se Ter Pena Matasse")
@export var cena_pena: PackedScene
@export var penas_min: int = 5 # penas por leque: de 5...
@export var penas_max: int = 7 # ...a 7
@export var leques_min: int = 1 # repete o leque 1...
@export var leques_max: int = 2 # ...ou 2 vezes antes de cansar
@export var dano_pena: int = 1 # dano por pena (ida e volta)
@export var angulo_leque: float = 60.0 # abertura total do leque (graus)
@export var velocidade_pena: float = 260.0 # px/s na ida
@export var velocidade_retorno_pena: float = 320.0 # px/s na volta
@export var distancia_pena_max: float = 440.0 # distância em que as penas são puxadas de volta (px); cobre a arena de 640 px
@export var tempo_preparo_penas: float = 0.5 # aviso: animação de disparo antes de as penas saírem (s)
@export var intervalo_entre_leques: float = 0.6 # s
@export var espera_maxima_das_penas: float = 6.0 # segurança: não espera a volta além disto (s)

@export_group("Rap do Zé Felipe")
@export var cena_urubu: PackedScene
@export var espera_urubus: float = 3.0 # s cantando antes do primeiro urubu
@export var canto_min: float = 5.0 # canta de 5...
@export var canto_max: float = 10.0 # ...a 10 s
@export var dano_urubu: int = 1 # dano por urubu
@export var intervalo_urubu: float = 1.1 # s entre um urubu e o próximo
@export var velocidade_urubu: float = 210.0 # px/s
@export var aviso_urubu: float = 0.6 # s de aviso na borda antes de cada urubu
@export var alturas_dos_urubus: Array[float] = [16.0, 80.0] # faixas de voo, em px acima do chão

@export_group("Cansado")
@export var tempo_cansado: float = 4.0 # s no chão, vulnerável
@export var velocidade_de_pouso: float = 240.0 # px/s descendo e subindo
@export var altura_do_chao: float = 328.0 # y global do topo do chão da arena
@export var altura_pousado: float = 30.0 # distância do centro do corpo ao chão quando pousado (px)
@export var margem_de_pouso: float = 70.0 # não pousa a menos disto das bordas da arena (px)
@export var cor_cansado: Color = Color(0.82, 0.82, 0.95)

@export_group("Rajada de vento")
@export var usar_rajada_de_vento: bool = false # desligada; só reserva o estado

@export_group("Animação")
@export var escala_base: float = 0.28 # escala do sprite para as folhas "Idle" e "Voando" (cópias a 25 % das originais)
## As folhas foram desenhadas em tamanhos diferentes; este fator iguala cada animação à escala base.
@export var escala_por_animacao: Dictionary = {"plumataque": 1.871, "hit": 1.871, "death": 1.871}
@export var deslocamento_do_sprite: Vector2 = Vector2(-10.0, -33.0) # posição do sprite olhando para a esquerda

var estado: Estado = Estado.APRESENTACAO
var _tempo_estado: float = 0.0
var _proximo_ataque: Estado = Estado.PENAS

var _fase_penas: FasePenas = FasePenas.PREPARO
var _tempo_fase: float = 0.0
var _leques_restantes: int = 0
var _penas_ativas: Array = [] # sem tipo: pode conter penas que já saíram da cena

var _fase_cansado: FaseCansado = FaseCansado.DESCENDO
var _posicao_de_voo: Vector2 = Vector2.ZERO

var _duracao_canto: float = 0.0
var _tempo_proximo_urubu: float = 0.0
var _urubus_agendados: Array[Dictionary] = [] # {tempo, sentido, y}

var _caminho: PathFollow2D = null
var _tempo_voo: float = 0.0
var _altura_base: float = 0.0
var _trava_de_animacao: float = 0.0
var _limites: Rect2 = Rect2(0.0, 0.0, 640.0, 360.0)


func _inicializar() -> void:
	_caminho = get_parent() as PathFollow2D
	_altura_base = global_position.y
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null and "limites" in arena:
		_limites = Rect2(arena.limites)
	_tocar("voando")
	_olhar_para_player()


func _ao_iniciar_luta() -> void:
	_mudar_estado(Estado.VOANDO)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tempo_estado += delta
	_tempo_fase += delta
	_trava_de_animacao = maxf(_trava_de_animacao - delta, 0.0)
	match estado:
		Estado.APRESENTACAO:
			pass
		Estado.VOANDO:
			_voar(delta)
			if _tempo_estado >= tempo_entre_ataques:
				_mudar_estado(_proximo_ataque)
		Estado.PENAS:
			_processar_penas()
		Estado.CANSADO:
			_processar_cansado(delta)
		Estado.CANTANDO:
			_processar_canto()
		Estado.RAJADA_DE_VENTO:
			_mudar_estado(Estado.VOANDO)
	_olhar_para_player()


func _mudar_estado(novo: Estado) -> void:
	estado = novo
	_tempo_estado = 0.0
	_tempo_fase = 0.0
	match novo:
		Estado.VOANDO:
			_tocar("voando")
		Estado.PENAS:
			_proximo_ataque = Estado.CANTANDO
			_leques_restantes = randi_range(leques_min, leques_max)
			_preparar_leque()
		Estado.CANTANDO:
			_proximo_ataque = Estado.PENAS
			_duracao_canto = randf_range(canto_min, canto_max)
			# O aviso aparece antes, para o primeiro urubu entrar exatamente em `espera_urubus`.
			_tempo_proximo_urubu = maxf(espera_urubus - aviso_urubu, 0.0)
			_urubus_agendados.clear()
			_tocar("sing")
			AudioManager.tocar_sfx(&"TODO_AUDIO_canto_carlitos")
		Estado.CANSADO:
			_fase_cansado = FaseCansado.DESCENDO
			_posicao_de_voo = global_position
			definir_cansado(true)
			_tocar("idle")
			if anim != null:
				anim.self_modulate = cor_cansado
			AudioManager.tocar_sfx(&"TODO_AUDIO_carlitos_cansado", -6.0)


# ---------------------------------------------------------------- voo

func _voar(delta: float) -> void:
	if _caminho != null:
		_caminho.progress += velocidade_voo * delta
	else:
		_tempo_voo += delta
		global_position.y = _altura_base + sin(_tempo_voo * frequencia_senoidal * TAU) * amplitude_senoidal


func _olhar_para_player() -> void:
	if anim == null or not is_instance_valid(player) or estado == Estado.MORRENDO:
		return
	var diferenca: float = player.global_position.x - global_position.x
	if absf(diferenca) > 4.0:
		# A arte olha para a esquerda; espelha quando o jogador está à direita.
		anim.flip_h = diferenca > 0.0
	anim.position = Vector2(deslocamento_do_sprite.x * (-1.0 if anim.flip_h else 1.0), deslocamento_do_sprite.y)


# ---------------------------------------------------------------- Se Ter Pena Matasse

func _preparar_leque() -> void:
	_fase_penas = FasePenas.PREPARO
	_tempo_fase = 0.0
	_tocar("plumataque", true)
	AudioManager.tocar_sfx(&"TODO_AUDIO_penas_preparo", -6.0)


func _processar_penas() -> void:
	match _fase_penas:
		FasePenas.PREPARO:
			if _tempo_fase >= tempo_preparo_penas:
				_disparar_leque()
				_leques_restantes -= 1
				_fase_penas = FasePenas.AGUARDANDO_VOLTA
				_tempo_fase = 0.0
		FasePenas.AGUARDANDO_VOLTA:
			_penas_ativas = _penas_ativas.filter(func(p: Variant) -> bool: return is_instance_valid(p))
			if _penas_ativas.is_empty() or _tempo_fase >= espera_maxima_das_penas:
				if _leques_restantes > 0:
					_fase_penas = FasePenas.INTERVALO
					_tempo_fase = 0.0
					_tocar("voando")
				else:
					_mudar_estado(Estado.CANSADO)
		FasePenas.INTERVALO:
			if _tempo_fase >= intervalo_entre_leques:
				_preparar_leque()


func _disparar_leque() -> void:
	if cena_pena == null or not is_instance_valid(player):
		return
	var origem: Vector2 = global_position
	var angulo_base: float = (player.global_position - origem).angle()
	var quantidade: int = randi_range(penas_min, penas_max)
	var passo: float = angulo_leque / float(quantidade - 1) if quantidade > 1 else 0.0
	for i in quantidade:
		var pena := cena_pena.instantiate() as Pena
		if pena == null:
			continue
		var angulo: float = angulo_base + deg_to_rad(-angulo_leque * 0.5 + passo * i)
		pena.dano = dano_pena
		_arena().add_child(pena)
		pena.global_position = origem
		pena.iniciar(Vector2.from_angle(angulo), velocidade_pena, distancia_pena_max, self, velocidade_retorno_pena)
		_penas_ativas.append(pena)
	AudioManager.tocar_sfx(&"TODO_AUDIO_penas_disparo", -4.0)


# ---------------------------------------------------------------- cansado

func _processar_cansado(delta: float) -> void:
	match _fase_cansado:
		FaseCansado.DESCENDO:
			var pouso := Vector2(
				clampf(_posicao_de_voo.x, _limites.position.x + margem_de_pouso, _limites.end.x - margem_de_pouso),
				altura_do_chao - altura_pousado)
			global_position = global_position.move_toward(pouso, velocidade_de_pouso * delta)
			if global_position.distance_to(pouso) < 1.0:
				_fase_cansado = FaseCansado.NO_CHAO
				_tempo_fase = 0.0
		FaseCansado.NO_CHAO:
			if _trava_de_animacao <= 0.0:
				_tocar("idle")
			if _tempo_fase >= tempo_cansado:
				_fase_cansado = FaseCansado.SUBINDO
				definir_cansado(false)
				if anim != null:
					anim.self_modulate = Color.WHITE
				_tocar("voando")
		FaseCansado.SUBINDO:
			global_position = global_position.move_toward(_posicao_de_voo, velocidade_de_pouso * delta)
			if global_position.distance_to(_posicao_de_voo) < 1.0:
				global_position = _posicao_de_voo
				_mudar_estado(Estado.VOANDO)


# ---------------------------------------------------------------- Rap do Zé Felipe

func _processar_canto() -> void:
	# Agenda: cada urubu é anunciado na borda `aviso_urubu` segundos antes de entrar.
	if _tempo_estado >= _tempo_proximo_urubu and _tempo_proximo_urubu < _duracao_canto:
		_tempo_proximo_urubu += intervalo_urubu
		_agendar_urubu()
	while not _urubus_agendados.is_empty() and _tempo_estado >= _urubus_agendados[0]["tempo"]:
		var dados: Dictionary = _urubus_agendados.pop_front()
		_soltar_urubu(dados["sentido"], dados["y"])
	if _tempo_estado >= _duracao_canto and _urubus_agendados.is_empty():
		_mudar_estado(Estado.CANSADO)


func _agendar_urubu() -> void:
	if alturas_dos_urubus.is_empty():
		return
	var sentido: float = 1.0 if randf() < 0.5 else -1.0 # 1 = entra pela esquerda
	var y: float = altura_do_chao - float(alturas_dos_urubus.pick_random())
	var x_borda: float = _limites.position.x + 12.0 if sentido > 0.0 else _limites.end.x - 12.0
	TelegraphWarning.criar(_arena(), Vector2(x_borda, y), Vector2(20.0, 26.0), aviso_urubu,
		TelegraphWarning.Forma.RETANGULO, Vector2(sentido, 0.0))
	_urubus_agendados.append({"tempo": _tempo_estado + aviso_urubu, "sentido": sentido, "y": y})


func _soltar_urubu(sentido: float, y: float) -> void:
	if cena_urubu == null:
		return
	var urubu := cena_urubu.instantiate() as Urubu
	if urubu == null:
		return
	urubu.preparar_travessia(sentido, velocidade_urubu)
	urubu.dano_contato = dano_urubu
	var x: float = _limites.position.x - 30.0 if sentido > 0.0 else _limites.end.x + 30.0
	urubu.position = _arena().to_local(Vector2(x, y)) if _arena() is Node2D else Vector2(x, y)
	_arena().add_child(urubu)


# ---------------------------------------------------------------- reações

func _ao_levar_hit() -> void:
	if estado == Estado.CANSADO:
		_tocar("hit", true)
		_trava_de_animacao = 0.35
	AudioManager.tocar_sfx(&"TODO_AUDIO_carlitos_hit", -4.0)


func _ao_morrer() -> void:
	estado = Estado.MORRENDO
	for pena in _penas_ativas:
		if is_instance_valid(pena):
			pena.queue_free()
	_penas_ativas.clear()
	_urubus_agendados.clear()
	for inimigo in get_tree().get_nodes_in_group("enemy"):
		if inimigo is Urubu:
			inimigo.queue_free()
	if anim != null:
		anim.self_modulate = Color.WHITE
		create_tween().tween_property(anim, "modulate:a", 0.0, duracao_morte).set_delay(0.6)
	_tocar("death", true)
	AudioManager.tocar_sfx(&"TODO_AUDIO_carlitos_morte")


# ---------------------------------------------------------------- utilidades

func _arena() -> Node:
	return get_tree().current_scene


## Toca a animação já com a escala certa para a folha dela.
func _tocar(nome: String, do_inicio: bool = false) -> void:
	if anim == null or anim.sprite_frames == null or not anim.sprite_frames.has_animation(nome):
		return
	var fator: float = float(escala_por_animacao.get(nome, 1.0))
	anim.scale = Vector2.ONE * escala_base * fator
	if do_inicio:
		anim.stop()
		anim.play(nome)
	elif anim.animation != nome or not anim.is_playing():
		anim.play(nome)

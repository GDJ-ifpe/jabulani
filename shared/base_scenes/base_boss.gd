class_name BaseBoss
extends CharacterBody2D

## Base dos chefes: vida, sinais para a barra de vida, apresentação com câmera, dano de contato,
## estado "cansado" (brecha para o jogador atacar), fases por porcentagem de vida e derrota.
## Cada chefe herda e implementa os ataques nos ganchos _inicializar(), _ao_iniciar_luta(),
## _ao_levar_hit(), _ao_mudar_de_fase() e _ao_morrer().

signal hp_changed(hp_atual: int, hp_maximo: int)
signal cansaco_mudou(esta_cansado: bool)
signal fase_mudou(fase: int)
signal derrotado(chefe: BaseBoss)

@export_group("Identidade")
@export var id: StringName = &"chefe" # enviado em Events.boss_defeated
@export var nome_exibido: String = "" # texto da barra de vida

@export_group("Atributos")
@export var max_hp: int = 50
@export var dano_contato: int = 1
@export var pontos: int = 0 # pontos ao ser derrotado
@export var tamanho_dano_contato: Vector2 = Vector2(48.0, 48.0)
@export var deslocamento_dano_contato: Vector2 = Vector2.ZERO

@export_group("Fases")
## Frações de vida (entre 1 e 0, em ordem decrescente) em que o chefe muda de fase.
## Vazio = o chefe tem uma fase só.
@export var limiares_de_fase: Array[float] = []

@export_group("Reações")
@export var duracao_hit: float = 0.3 # s sem poder levar outro golpe
@export var duracao_morte: float = 1.5 # s entre a derrota e o aviso ao resto do jogo
@export var cor_hit: Color = Color(1.0, 0.35, 0.35)

@export_group("Apresentação")
@export var tempo_intro: float = 2.0 # s mostrando o chefe antes de a luta começar
@export var zoom_intro: Vector2 = Vector2(1.3, 1.3)
@export var duracao_transicao_camera: float = 0.6 # s

var hp: int
var fase_atual: int = 0
var is_dead: bool = false
var is_hurt: bool = false
var invulneravel: bool = true # verdadeiro durante a apresentação
var cansado: bool = false
var luta_iniciada: bool = false
var player: CharacterBody2D = null
var dano_area: Hitbox = null

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	add_to_group("boss")
	collision_layer = Camadas.INIMIGOS
	collision_mask = 0
	hp = max_hp
	_configurar_hitbox_dano()
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	_inicializar()
	_apresentar.call_deferred()


func _configurar_hitbox_dano() -> void:
	if dano_contato <= 0:
		return
	dano_area = Hitbox.new()
	dano_area.name = "DanoDeContato"
	dano_area.equipe = Hitbox.Equipe.INIMIGO
	dano_area.dano = dano_contato
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho_dano_contato
	forma.shape = retangulo
	forma.position = deslocamento_dano_contato
	dano_area.add_child(forma)
	add_child(dano_area)


func _apresentar() -> void:
	Events.boss_spawned.emit(self)
	hp_changed.emit(hp, max_hp)
	var camera: Camera2D = null
	if is_instance_valid(player):
		camera = player.get_node_or_null("Camera2D") as Camera2D
	if camera != null and tempo_intro > 0.0:
		var ida: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		ida.set_parallel()
		ida.tween_property(camera, "zoom", zoom_intro, duracao_transicao_camera)
		# Move a câmera (e não o offset) para que os limites da arena continuem valendo.
		ida.tween_property(camera, "position", global_position - player.global_position, duracao_transicao_camera)
	if tempo_intro > 0.0:
		await get_tree().create_timer(tempo_intro, false).timeout
	if is_instance_valid(camera):
		var volta: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		volta.set_parallel()
		volta.tween_property(camera, "zoom", Vector2.ONE, duracao_transicao_camera)
		volta.tween_property(camera, "position", Vector2.ZERO, duracao_transicao_camera)
	if is_dead:
		return
	invulneravel = false
	luta_iniciada = true
	_ao_iniciar_luta()


func receber_dano(quantidade: int, _origem: Vector2 = Vector2.INF) -> void:
	if is_dead or is_hurt or invulneravel:
		return
	hp = maxi(hp - quantidade, 0)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		_morrer()
		return
	_verificar_fase()
	_levar_hit()


func definir_cansado(valor: bool) -> void:
	if cansado == valor:
		return
	cansado = valor
	cansaco_mudou.emit(cansado)


func _verificar_fase() -> void:
	var fracao: float = float(hp) / float(max_hp)
	var nova_fase: int = 0
	for limiar in limiares_de_fase:
		if fracao <= limiar:
			nova_fase += 1
	if nova_fase != fase_atual:
		fase_atual = nova_fase
		fase_mudou.emit(fase_atual)
		_ao_mudar_de_fase(fase_atual)


func _levar_hit() -> void:
	is_hurt = true
	_ao_levar_hit()
	_piscar()
	await get_tree().create_timer(duracao_hit, false).timeout
	is_hurt = false


func _piscar() -> void:
	if anim == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(anim, "modulate", cor_hit, 0.05)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.15)


func _morrer() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	definir_cansado(false)
	if dano_area != null:
		dano_area.ativa = false
	collision_layer = 0
	PlayerData.adicionar_pontos(pontos)
	_ao_morrer()
	derrotado.emit(self)
	await get_tree().create_timer(duracao_morte, false).timeout
	Events.boss_defeated.emit(id)


## Gancho: configuração própria de cada chefe (antes da apresentação).
func _inicializar() -> void:
	pass


## Gancho: a apresentação acabou; começar o ciclo de ataques.
func _ao_iniciar_luta() -> void:
	pass


## Gancho: reação ao golpe.
func _ao_levar_hit() -> void:
	pass


## Gancho: a vida cruzou um dos limiares de fase.
func _ao_mudar_de_fase(_fase: int) -> void:
	pass


## Gancho: derrota (parar ataques, remover projéteis, tocar a animação de morte).
func _ao_morrer() -> void:
	pass


func _play_anim(nome: String) -> void:
	if not is_instance_valid(anim):
		return
	if anim.sprite_frames and anim.sprite_frames.has_animation(nome):
		if anim.animation != nome:
			anim.play(nome)

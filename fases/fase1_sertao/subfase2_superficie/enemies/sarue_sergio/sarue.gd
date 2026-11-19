extends BaseEnemy

## Saruê - Sergio (e os Serginhos). "Eu mordo": persegue o jogador pelo chão e, ao chegar
## perto, morde na direção em que está olhando (a boca abre antes, como aviso).
## Ao ser derrotado fica tonto por um instante, com a área de perigo piscando, e explode:
## fere quem não se afastar a tempo.

enum Estado { PERSEGUINDO, MORDENDO }

@export_group("Mordida")
@export var dano_mordida: int = 1
@export var distancia_de_mordida: float = 28.0 # começa a morder a esta distância (px)
@export var altura_de_mordida: float = 24.0 # só morde se o jogador estiver nesta faixa vertical (px)
@export var tempo_preparo_mordida: float = 0.33 # aviso: a boca abrindo antes de a mordida valer (s)
@export var duracao_mordida: float = 0.17 # janela em que a mordida fere (s)
@export var recarga_mordida: float = 1.2 # s

@export_group("Explosão")
@export var tempo_ate_explodir: float = 0.8 # aviso entre a derrota e a explosão (s)
@export var raio_explosao: float = 36.0 # px
@export var dano_explosao: int = 1
@export var duracao_explosao: float = 0.2 # janela em que a explosão fere (s)

@export_group("Movimento")
@export var distancia_para_virar: float = 10.0 # folga antes de virar para o jogador (px)
@export var tempo_minimo_entre_viradas: float = 0.35 # s

var estado: Estado = Estado.PERSEGUINDO
var _tempo_estado: float = 0.0
var _recarga: float = 0.0
var _tempo_desde_virada: float = 0.0
var _explosao: Hitbox = null

@onready var mordida: Hitbox = $Mordida


func _inicializar() -> void:
	mordida.dano = dano_mordida
	mordida.ativa = false
	duracao_morte = tempo_ate_explodir + 0.6
	if is_instance_valid(player):
		direcao = signf(player.global_position.x - global_position.x)
	if direcao == 0.0:
		direcao = 1.0
	_atualizar_flip()
	_play_anim("walk")


func _physics_process(delta: float) -> void:
	_aplicar_gravidade(delta)
	if is_dead:
		velocity.x = 0.0
		move_and_slide()
		return
	_tempo_estado += delta
	_tempo_desde_virada += delta
	_recarga = maxf(_recarga - delta, 0.0)

	match estado:
		Estado.PERSEGUINDO:
			_perseguir()
			if _pode_morder():
				_mudar_estado(Estado.MORDENDO)
		Estado.MORDENDO:
			velocity.x = 0.0
			var mordendo: bool = _tempo_estado >= tempo_preparo_mordida and _tempo_estado < tempo_preparo_mordida + duracao_mordida
			if mordida.ativa != mordendo:
				mordida.ativa = mordendo
			if _tempo_estado >= tempo_preparo_mordida + duracao_mordida + 0.16:
				_recarga = recarga_mordida
				_mudar_estado(Estado.PERSEGUINDO)
	move_and_slide()


func _perseguir() -> void:
	if not is_instance_valid(player):
		velocity.x = 0.0
		_play_anim("idle")
		return
	var diferenca: float = player.global_position.x - global_position.x
	if _tempo_desde_virada >= tempo_minimo_entre_viradas:
		var nova: float = direcao
		if is_on_wall():
			nova = -direcao
		elif absf(diferenca) > distancia_para_virar:
			nova = signf(diferenca)
		if nova != direcao:
			direcao = nova
			_tempo_desde_virada = 0.0
			_atualizar_flip()
	# Embaixo do jogador (ele está numa plataforma): espera parado em vez de tremer.
	if absf(diferenca) <= distancia_para_virar:
		velocity.x = 0.0
		_play_anim("idle")
	else:
		velocity.x = 0.0 if is_hurt else direcao * velocidade
		_play_anim("walk")


func _pode_morder() -> bool:
	if _recarga > 0.0 or is_hurt or not is_instance_valid(player):
		return false
	var diferenca: Vector2 = player.global_position - global_position
	return absf(diferenca.x) <= distancia_de_mordida and absf(diferenca.y) <= altura_de_mordida


func _mudar_estado(novo: Estado) -> void:
	estado = novo
	_tempo_estado = 0.0
	mordida.ativa = false
	if novo == Estado.MORDENDO:
		# Morde para o lado em que já está olhando.
		mordida.scale.x = direcao if direcao != 0.0 else 1.0
		anim.stop()
		anim.play("mordida")
		AudioManager.tocar_sfx(&"TODO_AUDIO_sarue_mordida", -6.0)
	else:
		_play_anim("walk")


func _ao_levar_hit() -> void:
	mordida.ativa = false
	if estado == Estado.MORDENDO:
		_recarga = recarga_mordida
		_mudar_estado(Estado.PERSEGUINDO)
	AudioManager.tocar_sfx(&"TODO_AUDIO_sarue_hit", -6.0)


func _ao_morrer() -> void:
	mordida.ativa = false


## Em vez de só sumir: fica tonto, avisa e explode.
func _animar_morte() -> void:
	_play_anim("atordoado")
	TelegraphWarning.criar(self, global_position, Vector2(raio_explosao * 2.0, 0.0),
		tempo_ate_explodir, TelegraphWarning.Forma.CIRCULO)
	await get_tree().create_timer(tempo_ate_explodir, false).timeout
	if not is_inside_tree():
		return
	_explodir()


func _explodir() -> void:
	anim.stop()
	anim.play("explosao")
	AudioManager.tocar_sfx(&"TODO_AUDIO_sarue_explosao")
	_explosao = Hitbox.new()
	_explosao.name = "Explosao"
	_explosao.equipe = Hitbox.Equipe.INIMIGO
	_explosao.dano = dano_explosao
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = raio_explosao
	forma.shape = circulo
	_explosao.add_child(forma)
	add_child(_explosao)
	await get_tree().create_timer(duracao_explosao, false).timeout
	if is_instance_valid(_explosao):
		_explosao.ativa = false

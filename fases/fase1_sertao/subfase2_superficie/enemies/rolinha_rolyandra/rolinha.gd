extends BaseEnemy

## Rolinha - Rolyandra, integrante da gangue "Roll 17". Quem decide o voo e a hora do disparo
## é o grupo (gangue_roll17.gd); a rolinha pisca no aviso e atira a pedra quando mandam.

@export var cena_projetil: PackedScene
@export var dano_projetil: int = 1
@export var cor_aviso: Color = Color(1.0, 0.6, 0.2)
@export var amplitude_de_voo: float = 3.0 # balanço no ar (px)

var _tempo: float = 0.0
var _aviso_restante: float = 0.0
var _altura_do_sprite: float = 0.0


func _inicializar() -> void:
	usa_gravidade = false
	collision_mask = 0
	_tempo = randf() * TAU
	if anim != null:
		_altura_do_sprite = anim.position.y
	_play_anim("voando")


func _process(delta: float) -> void:
	if is_dead or anim == null:
		return
	_tempo += delta
	anim.position.y = _altura_do_sprite + sin(_tempo * 6.0) * amplitude_de_voo
	if _aviso_restante > 0.0:
		_aviso_restante -= delta
		anim.self_modulate = cor_aviso if fmod(_aviso_restante, 0.16) < 0.08 else Color.WHITE
		if _aviso_restante <= 0.0:
			anim.self_modulate = Color.WHITE


func olhar_para(lado: float) -> void:
	if lado != 0.0 and lado != direcao:
		direcao = lado
		_atualizar_flip()


## Aviso antes do disparo: pisca durante `duracao` segundos.
func avisar(duracao: float) -> void:
	if not is_dead:
		_aviso_restante = duracao


func disparar(alvo: Node2D) -> void:
	if is_dead or cena_projetil == null:
		return
	var projetil := cena_projetil.instantiate() as BaseProjectile
	if projetil == null:
		return
	projetil.dano = dano_projetil
	projetil.alvo = alvo
	# O projétil entra na arena (não no grupo), para não se mover junto com as rolinhas.
	get_parent().get_parent().add_child(projetil)
	projetil.global_position = global_position
	var lado: float = signf(alvo.global_position.x - global_position.x)
	projetil.lancar(Vector2(lado * 0.6, -1.0))


func _ao_morrer() -> void:
	if anim != null:
		anim.self_modulate = Color.WHITE
	AudioManager.tocar_sfx(&"TODO_AUDIO_rolinha_morte", -4.0)

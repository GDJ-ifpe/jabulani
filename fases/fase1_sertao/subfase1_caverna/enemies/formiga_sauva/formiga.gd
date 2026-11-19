extends BaseEnemy

## Formiga saúva - Lucas. Sai do ninho, anda pelo chão atrás do jogador e morde ao encostar
## (dano de contato). Dá meia-volta em paredes.

@export var tempo_minimo_entre_viradas: float = 0.4 # s (evita ficar tremendo embaixo do jogador)
@export var distancia_para_virar: float = 12.0 # px de folga antes de virar para o jogador

var _tempo_desde_virada: float = 0.0


func _inicializar() -> void:
	_play_anim("andando")
	if is_instance_valid(player):
		direcao = signf(player.global_position.x - global_position.x)
	if direcao == 0.0:
		direcao = 1.0
	_atualizar_flip()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_aplicar_gravidade(delta)
	_tempo_desde_virada += delta

	if _tempo_desde_virada >= tempo_minimo_entre_viradas:
		var nova_direcao: float = direcao
		if is_on_wall():
			nova_direcao = -direcao
		elif is_instance_valid(player):
			var diferenca: float = player.global_position.x - global_position.x
			if absf(diferenca) > distancia_para_virar:
				nova_direcao = signf(diferenca)
		if nova_direcao != direcao:
			direcao = nova_direcao
			_tempo_desde_virada = 0.0
			_atualizar_flip()

	velocity.x = 0.0 if is_hurt else direcao * velocidade
	move_and_slide()


func _ao_morrer() -> void:
	AudioManager.tocar_sfx(&"TODO_AUDIO_formiga_morte", -6.0)

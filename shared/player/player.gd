extends CharacterBody2D

## Jabulani. Vida, pontos e poder ficam no autoload PlayerData.
## Valores calibrados para a resolução base 640x360 (Jabulani com ~40 px de altura).

signal player_died
signal player_hit(hp_restante: int)

@export var anim: AnimatedSprite2D

@export_group("Movimento")
@export var velocidade: float = 170.0 # velocidade horizontal normal (px/s)
@export var velocidade_agachado: float = 136.0 # velocidade ao agachar (80% da normal)

@export_group("Pulo")
@export var altura_pulo: float = 72.0 # altura máxima do pulo (px) - alcança degraus de até 64 px
@export var tempo_ate_apice: float = 0.38 # tempo da saída do chão até o ponto mais alto (s)
@export var multiplicador_gravidade_queda: float = 1.3 # gravidade extra na descida
@export var velocidade_queda_max: float = 600.0 # limite da velocidade de queda (px/s)
@export_range(0.0, 1.0) var corte_pulo_curto: float = 0.5 # fração da velocidade mantida ao soltar o pulo
@export var tempo_coyote: float = 0.12 # janela de pulo após sair da plataforma (s)
@export var tempo_buffer_pulo: float = 0.10 # janela de input antes de pousar (s)
@export var tempo_descer_plataforma: float = 0.25 # agachar + pular: tempo ignorando plataformas vazadas (s)

@export_group("Dash")
@export var velocidade_dash: float = 620.0 # px/s (620 x 0.18 s = ~112 px por dash)
@export var duracao_dash: float = 0.18 # duração do dash (s)
@export var recarga_dash: float = 0.75 # cooldown do dash (s)

@export_group("Combate")
@export var duracao_ataque: float = 0.35 # duração da animação de ataque (s)
@export var duracao_invencibilidade: float = 1.0 # invencibilidade ao levar dano (s)
@export var duracao_atordoamento: float = 0.4 # tempo sem controle ao levar dano ou impulso (s)
@export var recuo_dano: Vector2 = Vector2(150.0, -150.0) # impulso ao levar dano (x = para longe da origem, y = para cima)

@export_group("Jabussíntese")
@export var cena_jabussintese: PackedScene
@export var custo_jabussintese: int = 1 # pontos de poder gastos por uso
@export var recarga_jabussintese: float = 4.0 # intervalo mínimo entre usos (s)
@export var distancia_jabussintese: float = 40.0 # distância à frente do Jabulani onde o poder surge (px)

@export_group("Desorientação")
@export var desorientacao_inverte_controles: bool = true # esquerda/direita trocados enquanto durar
@export_range(0.1, 1.0) var desorientacao_fator_velocidade: float = 0.7 # resposta do movimento enquanto durar
@export var cor_desorientado: Color = Color(0.75, 0.6, 1.0) # tinta aplicada ao sprite enquanto durar

enum State { IDLE, RUNNING, JUMPING, FALLING, CROUCHING, DASHING, ATTACKING, HIT, DEAD }
var state: State = State.IDLE

var facing_right: bool = true
var can_dash: bool = true
var is_invincible: bool = false
var is_dead: bool = false

var _dash_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _attack_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _invincibility_timer: float = 0.0
var _atordoamento_timer: float = 0.0
var _descer_timer: float = 0.0
var _jabussintese_timer: float = 0.0
var _desorientacao_timer: float = 0.0

var _was_on_floor: bool = false
var _alvos_do_golpe: Array[Node] = []
var _tween_piscar: Tween

# Derivados de altura_pulo e tempo_ate_apice (recalculados em _ready).
var _gravidade: float = 0.0
var _velocidade_pulo: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackHitbox

# Compatibilidade: outros scripts leem estes valores do player.
var max_hp: int:
	get:
		return PlayerData.max_hp
var hp: int:
	get:
		return PlayerData.hp


func _ready() -> void:
	collision_layer = Camadas.PLAYER
	collision_mask = Camadas.CHAO
	attack_area.collision_layer = Camadas.ATAQUE_PLAYER
	attack_area.collision_mask = Camadas.INIMIGOS
	_calcular_fisica_pulo()
	attack_area.monitoring = false
	attack_area.area_entered.connect(_on_attack_hit)
	attack_area.body_entered.connect(_on_attack_hit)
	if PlayerData.esta_morto():
		PlayerData.iniciar_arena()


func _calcular_fisica_pulo() -> void:
	# Cinemática do pulo: h = g*t²/2 e v0 = g*t  ->  g = 2h/t², v0 = 2h/t
	var tempo: float = maxf(tempo_ate_apice, 0.05)
	_gravidade = 2.0 * altura_pulo / (tempo * tempo)
	_velocidade_pulo = -2.0 * altura_pulo / tempo


func _physics_process(delta: float) -> void:
	_atualizar_timers(delta)
	_aplicar_gravidade(delta)

	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, velocidade * 4.0 * delta)
		move_and_slide()
		return

	_processar_coyote_time()
	_processar_input()
	_atualizar_animacao()

	move_and_slide()

	_was_on_floor = is_on_floor()


# ---------------------------------------------------------------- timers e física

func _atualizar_timers(delta: float) -> void:
	if _dash_timer > 0.0:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_terminar_dash()

	if _dash_cooldown > 0.0:
		_dash_cooldown -= delta
		if _dash_cooldown <= 0.0:
			can_dash = true

	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_terminar_ataque()

	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	_jabussintese_timer = maxf(_jabussintese_timer - delta, 0.0)

	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			is_invincible = false
			_parar_de_piscar()

	if _atordoamento_timer > 0.0:
		_atordoamento_timer -= delta
		if _atordoamento_timer <= 0.0 and state == State.HIT:
			state = State.IDLE

	if _descer_timer > 0.0:
		_descer_timer -= delta
		if _descer_timer <= 0.0:
			set_collision_mask_value(7, true)

	if _desorientacao_timer > 0.0:
		_desorientacao_timer -= delta
		if _desorientacao_timer <= 0.0:
			_terminar_desorientacao()


func _aplicar_gravidade(delta: float) -> void:
	if state == State.DASHING:
		return
	if not is_on_floor():
		var gravidade: float = _gravidade
		if velocity.y > 0.0:
			gravidade *= multiplicador_gravidade_queda
		velocity.y = minf(velocity.y + gravidade * delta, velocidade_queda_max)


func _processar_coyote_time() -> void:
	if _was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		_coyote_timer = tempo_coyote


# ---------------------------------------------------------------- input

func _processar_input() -> void:
	if state == State.DASHING:
		return
	if state == State.HIT:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, 10.0)
		return

	_processar_jabussintese()
	_processar_ataque()
	_processar_dash()
	if state == State.DASHING:
		return # o dash recém-iniciado não pode ter a velocidade sobrescrita pelo movimento normal
	_processar_agachar()
	_processar_pulo()
	_processar_movimento()


func _processar_ataque() -> void:
	if state == State.ATTACKING:
		return
	if Input.is_action_just_pressed("attack"):
		_iniciar_ataque()


func _iniciar_ataque() -> void:
	state = State.ATTACKING
	_attack_timer = duracao_ataque
	_alvos_do_golpe.clear()
	_posicionar_hitbox_ataque()
	attack_area.monitoring = true
	_tocar_do_inicio("attack")


func _terminar_ataque() -> void:
	attack_area.set_deferred("monitoring", false)
	if state == State.ATTACKING:
		state = State.IDLE


func _processar_dash() -> void:
	if Input.is_action_just_pressed("dash") and can_dash and is_on_floor():
		_iniciar_dash()


func _iniciar_dash() -> void:
	if state == State.ATTACKING:
		_terminar_ataque()
	state = State.DASHING
	can_dash = false
	_dash_timer = duracao_dash
	_dash_cooldown = recarga_dash
	velocity.y = 0.0
	velocity.x = velocidade_dash * (1.0 if facing_right else -1.0)
	is_invincible = true
	_invincibility_timer = maxf(_invincibility_timer, duracao_dash)
	_tocar_do_inicio("dash")


func _terminar_dash() -> void:
	velocity.x = 0.0
	if state == State.DASHING:
		state = State.IDLE


func _processar_agachar() -> void:
	var agachando: bool = Input.is_action_pressed("crouch")
	if agachando and is_on_floor() and state != State.ATTACKING:
		state = State.CROUCHING
	elif state == State.CROUCHING and not agachando:
		state = State.IDLE


func _processar_pulo() -> void:
	if Input.is_action_just_pressed("jump"):
		if state == State.CROUCHING and is_on_floor():
			_descer_da_plataforma()
			return
		_jump_buffer_timer = tempo_buffer_pulo

	var pode_pular: bool = is_on_floor() or _coyote_timer > 0.0
	var quer_pular: bool = _jump_buffer_timer > 0.0

	if quer_pular and pode_pular and state != State.CROUCHING:
		velocity.y = _velocidade_pulo
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		if state != State.ATTACKING:
			state = State.JUMPING

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= corte_pulo_curto


## Agachar + pular: atravessa a plataforma vazada em que está apoiado.
## No chão sólido não acontece nada, porque só a camada das plataformas vazadas é ignorada.
func _descer_da_plataforma() -> void:
	set_collision_mask_value(7, false)
	_descer_timer = tempo_descer_plataforma
	state = State.FALLING


func _processar_movimento() -> void:
	var direction: float = Input.get_axis("left", "right")
	var speed_atual: float = velocidade_agachado if state == State.CROUCHING else velocidade

	if _desorientacao_timer > 0.0:
		speed_atual *= desorientacao_fator_velocidade
		if desorientacao_inverte_controles:
			direction = -direction

	if direction != 0.0:
		velocity.x = direction * speed_atual
		facing_right = direction > 0.0
		anim.flip_h = facing_right
		if state == State.IDLE:
			state = State.RUNNING
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed_atual * 1.5)
		if is_on_floor() and state == State.RUNNING:
			state = State.IDLE

	if state == State.ATTACKING:
		return
	if not is_on_floor():
		state = State.JUMPING if velocity.y < 0.0 else State.FALLING
	elif state == State.JUMPING or state == State.FALLING:
		state = State.IDLE


# ---------------------------------------------------------------- ataque

func _posicionar_hitbox_ataque() -> void:
	attack_area.scale.x = 1.0 if facing_right else -1.0


func _on_attack_hit(alvo: Node) -> void:
	# Hurtbox (Area2D) repassa ao dono; corpos de inimigos recebem direto.
	var receptor: Node = alvo
	if not receptor.has_method("receber_dano") and receptor.get_parent() != null:
		receptor = receptor.get_parent()
	if receptor == self or not receptor.has_method("receber_dano"):
		return
	if _alvos_do_golpe.has(receptor):
		return
	_alvos_do_golpe.append(receptor)
	receptor.receber_dano(PlayerData.dano_golpe)


# ---------------------------------------------------------------- Jabussíntese

func _processar_jabussintese() -> void:
	if not Input.is_action_just_pressed("power_up"):
		return
	if cena_jabussintese == null or _jabussintese_timer > 0.0:
		return
	if not PlayerData.gastar_poder(custo_jabussintese):
		return
	_jabussintese_timer = recarga_jabussintese
	var poder: Node2D = cena_jabussintese.instantiate()
	var lado: float = 1.0 if facing_right else -1.0
	get_parent().add_child(poder)
	poder.global_position = global_position + Vector2(distancia_jabussintese * lado, 0.0)


# ---------------------------------------------------------------- dano, impulso e desorientação

## Dano vindo de inimigos. `origem` (posição global de quem causou) define o lado do recuo.
func receber_dano(quantidade: int, origem: Vector2 = Vector2.INF) -> void:
	if is_invincible or is_dead:
		return

	PlayerData.hp -= quantidade
	player_hit.emit(PlayerData.hp)

	if PlayerData.esta_morto():
		_morrer()
		return

	var lado: float = -1.0 if facing_right else 1.0
	if origem != Vector2.INF and not is_equal_approx(origem.x, global_position.x):
		lado = signf(global_position.x - origem.x)
	_atordoar(Vector2(recuo_dano.x * lado, recuo_dano.y))
	is_invincible = true
	_invincibility_timer = duracao_invencibilidade
	_piscar()


## Empurrão sem dano (grito do morcego, vento): mesmo mecanismo do recuo do dano.
func aplicar_impulso(impulso: Vector2) -> void:
	if is_dead:
		return
	_atordoar(impulso)


## Efeito de desorientação aplicado pelo próprio player; o inimigo só decide quando.
func aplicar_desorientacao(duracao: float) -> void:
	if is_dead or duracao <= 0.0:
		return
	_desorientacao_timer = maxf(_desorientacao_timer, duracao)
	anim.self_modulate = cor_desorientado


func esta_desorientado() -> bool:
	return _desorientacao_timer > 0.0


func _terminar_desorientacao() -> void:
	_desorientacao_timer = 0.0
	anim.self_modulate = Color.WHITE


func _atordoar(impulso: Vector2) -> void:
	if state == State.ATTACKING:
		_terminar_ataque()
	_dash_timer = 0.0
	state = State.HIT
	_atordoamento_timer = duracao_atordoamento
	velocity = impulso
	_tocar_do_inicio("hit")


func _piscar() -> void:
	_parar_de_piscar()
	_tween_piscar = create_tween().set_loops()
	_tween_piscar.tween_property(anim, "modulate:a", 0.3, 0.06)
	_tween_piscar.tween_property(anim, "modulate:a", 1.0, 0.06)


func _parar_de_piscar() -> void:
	if _tween_piscar != null:
		_tween_piscar.kill()
		_tween_piscar = null
	anim.modulate.a = 1.0


func _morrer() -> void:
	is_dead = true
	state = State.DEAD
	velocity.x = 0.0
	attack_area.set_deferred("monitoring", false)
	_terminar_desorientacao()
	_parar_de_piscar()
	_tocar_do_inicio("death")
	player_died.emit()


# ---------------------------------------------------------------- animação

func _atualizar_animacao() -> void:
	match state:
		State.IDLE:
			_play_anim("idle")
		State.RUNNING:
			_play_anim("walk")
		State.CROUCHING:
			_play_anim("crouch")
		State.JUMPING:
			_play_anim("jump")
		State.FALLING:
			_play_anim("fall" if _tem_anim("fall") else "jump")


func _play_anim(nome: String) -> void:
	if _tem_anim(nome) and anim.animation != nome:
		anim.play(nome)


func _tocar_do_inicio(nome: String) -> void:
	if _tem_anim(nome):
		anim.stop()
		anim.play(nome)


func _tem_anim(nome: String) -> bool:
	return anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation(nome)

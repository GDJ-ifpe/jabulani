extends CharacterBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@export var anim: AnimatedSprite2D

const SPEED = 150.0 # velocidade horizontal normal
const SPEED_CROUCH = 120.0 # velocidade ao agachar
const JUMP_VELOCITY = -650.0 # força do pulo (negativo = sobe)
const DASH_SPEED = 700.0 # velocidade do dash
const DASH_DURATION = 0.18 # duração do dash (segundos)
const DASH_COOLDOWN = 0.9 # cooldown do dash
const ATTACK_DURATION = 0.35 # duração da animação de ataque
const INVINCIBILITY_DURATION = 0.6 # frames de invencibilidade ao levar dano
const COYOTE_TIME = 0.12 # janela de pulo após sair da plataforma
const JUMP_BUFFER = 0.10 # janela de input antes de pousar

@export var max_hp: int = 5
@export var hp: int

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

var _was_on_floor: bool = false
var attack_area: Area2D

signal player_died
signal player_hit(hp_restante: int)

func _ready() -> void:
	hp = max_hp
	_criar_hitbox_ataque()

func _criar_hitbox_ataque() -> void:
	attack_area = Area2D.new()
	attack_area.name = "AttackHitbox"
	attack_area.monitoring = false

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(55, 40)
	shape.shape = rect

	attack_area.add_child(shape)
	add_child(attack_area)

	attack_area.area_entered.connect(_on_attack_hit_area)
	attack_area.body_entered.connect(_on_attack_hit_body)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_atualizar_timers(delta)
	_aplicar_gravidade(delta)
	_processar_coyote_time()
	_processar_input(delta)
	_atualizar_hitbox_ataque()
	_atualizar_animacao()

	move_and_slide()

	_was_on_floor = is_on_floor()

func _atualizar_timers(delta: float) -> void:
	if _dash_timer > 0:
		_dash_timer -= delta
		if _dash_timer <= 0:
			_terminar_dash()

	if _dash_cooldown > 0:
		_dash_cooldown -= delta
		if _dash_cooldown <= 0:
			can_dash = true

	if _attack_timer > 0:
		_attack_timer -= delta
		if _attack_timer <= 0:
			_terminar_ataque()

	if _coyote_timer > 0:
		_coyote_timer -= delta

	if _jump_buffer_timer > 0:
		_jump_buffer_timer -= delta

	if _invincibility_timer > 0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			is_invincible = false
			anim.modulate.a = 1.0

func _aplicar_gravidade(delta: float) -> void:
	if state == State.DASHING:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

func _processar_coyote_time() -> void:
	if _was_on_floor and not is_on_floor():
		_coyote_timer = COYOTE_TIME

func _processar_input(_delta: float) -> void:
	if state == State.DASHING or state == State.HIT or state == State.DEAD:
		return

	_processar_ataque()
	_processar_dash()
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
	_attack_timer = ATTACK_DURATION
	attack_area.monitoring = true
	_posicionar_hitbox_ataque()
	_play_anim("attack")

func _terminar_ataque() -> void:
	attack_area.monitoring = false
	if state == State.ATTACKING:
		state = State.IDLE

func _processar_dash() -> void:
	if Input.is_action_just_pressed("dash") and can_dash and is_on_floor():
		_iniciar_dash()

func _iniciar_dash() -> void:
	state = State.DASHING
	can_dash = false
	_dash_timer = DASH_DURATION
	_dash_cooldown = DASH_COOLDOWN
	velocity.y = 0
	velocity.x = DASH_SPEED * (1.0 if facing_right else -1.0)
	is_invincible = true
	_invincibility_timer = DASH_DURATION
	_play_anim("dash")

func _terminar_dash() -> void:
	velocity.x = 0
	state = State.IDLE

func _processar_agachar() -> void:
	var agachando = Input.is_action_pressed("crouch")
	if agachando and is_on_floor() and state != State.ATTACKING:
		state = State.CROUCHING
	elif state == State.CROUCHING and not agachando:
		state = State.IDLE

func _processar_pulo() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER

	var pode_pular = is_on_floor() or _coyote_timer > 0
	var quer_pular = _jump_buffer_timer > 0

	if quer_pular and pode_pular and state != State.CROUCHING:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		state = State.JUMPING

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

func _processar_movimento() -> void:
	if state == State.HIT:
		velocity.x = move_toward(velocity.x, 0, 4.0)
		return

	var direction := Input.get_axis("left", "right")
	var speed_atual = SPEED_CROUCH if state == State.CROUCHING else SPEED

	if direction != 0:
			velocity.x = direction * speed_atual

			if direction > 0:
				facing_right = true
				if anim != null:
					anim.flip_h = true
			else:
				facing_right = false
				if anim != null:
					anim.flip_h = false

			if state == State.IDLE:
				state = State.RUNNING
			
	else:
		velocity.x = move_toward(velocity.x, 0, speed_atual * 1.5)
		if is_on_floor() and state == State.RUNNING:
			state = State.IDLE

	if not is_on_floor() and state != State.DASHING and state != State.ATTACKING:
		if velocity.y < 0:
			state = State.JUMPING
		elif velocity.y > 0:
			state = State.FALLING
	elif is_on_floor() and (state == State.JUMPING or state == State.FALLING):
		state = State.IDLE

func _posicionar_hitbox_ataque() -> void:
	var offset_x = 55.0 if facing_right else -55.0
	attack_area.position = Vector2(offset_x, 0)

func _atualizar_hitbox_ataque() -> void:
	if attack_area.monitoring:
		_posicionar_hitbox_ataque()

func _on_attack_hit_area(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var enemy = area.get_parent()
		if enemy.has_method("receber_dano"):
			enemy.receber_dano(1)

func _on_attack_hit_body(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("receber_dano"):
			body.receber_dano(1)

func receber_dano(quantidade: int) -> void:
	if is_invincible or is_dead:
		return

	hp -= quantidade
	hp = max(hp, 0)
	print("Sofreu dano HP atual: ", hp, "/", max_hp)
	emit_signal("player_hit", hp)

	if hp <= 0:
		_morrer()
	else:
		_aplicar_hit()

func _aplicar_hit() -> void:
	state = State.HIT
	is_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	_play_anim("hit")

	velocity = Vector2.ZERO 

	velocity.x = -50.0 if facing_right else 50.0
	velocity.y = -50.0

	if anim != null:
		var tween = create_tween().set_loops(5)
		tween.tween_property(anim, "modulate:a", 0.3, 0.06)
		tween.tween_property(anim, "modulate:a", 1.0, 0.06)

	await get_tree().create_timer(0.4).timeout
	if state == State.HIT:
		state = State.IDLE

func _morrer() -> void:
	is_dead = true
	state = State.DEAD
	velocity = Vector2.ZERO
	_play_anim("death")
	emit_signal("player_died")

	await get_tree().create_timer(0.5).timeout
	collision_shape.disabled = true

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

func _tem_anim(nome: String) -> bool:
	if anim == null or anim.sprite_frames == null:
		return false
	return anim.sprite_frames != null and anim.sprite_frames.has_animation(nome)

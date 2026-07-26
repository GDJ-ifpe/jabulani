extends CharacterBody2D

class_name BossPassaro

## SISTEMA DE MOVIMENTAÇÃO VIA PATH2D
## O boss deve ser filho de um PathFollow2D na cena da fase.
## O PathFollow2D controla a posição do boss ao longo do Path2D.
## Se não houver PathFollow2D como pai, usa movimento senoidal como fallback.

signal boss_died

# ---------- MOVIMENTAÇÃO ----------
@export var velocidade_voo: float = 40.0
@export var amplitude_senoidal: float = 50.0
@export var frequencia_senoidal: float = 1.5

# ---------- COMBATE ----------
@export var max_hp: int = 8
@export var dano_contato: int = 1

# ---------- ATAQUE PENAS ----------
@export var penas_por_leque: int = 10
@export var angulo_leque: float = 60.0  # graus totais do leque
@export var velocidade_pena: float = 250.0
@export var distancia_pena_max: float = 300.0
@export var tempo_retorno_penas: float = 1.5  # segundos até puxar de volta

# ---------- ATAQUE CANTO ----------
@export var urubus_por_canto: int = 4
@export var intervalo_spawn_urubu: float = 0.4  # entre cada urubu
@export var velocidade_urubu: float = -200.0  # negativo = da direita pra esquerda

# ---------- PADRÃO RÍTMICO ----------
@export var intervalo_penas: float = 2.5  # tempo entre cada ataque de penas
@export var intervalo_canto: float = 1.5  # tempo entre cantos
@export var ciclo_penas_antes_canto: int = 2  # quantas vezes atirar penas antes do canto

# ---------- NÓS ----------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var spawn_penas: Marker2D = $SpawnPenas

var hp: int
var is_dead: bool = false
var is_hurt: bool = false
var player: CharacterBody2D = null

# Máquina de estados
enum BossState { IDLE, VOANDO, ATACANDO_PENAS, CANTANDO, RECUO, MORRENDO }
var state: BossState = BossState.IDLE

# Controle de voo
var tempo_voo: float = 0.0
var base_y: float = 0.0
var usar_path: bool = false
var path_follow_ref: PathFollow2D = null

# Ciclo de ataques
var ataques_penas_realizados: int = 0
var timer_ataque: float = 0.0
var is_in_attack: bool = false

# Penas ativas (para puxar de volta)
var penas_ativas: Array = []

func _ready() -> void:
	hp = max_hp
	_configurar_damage_area()
	_encontrar_player()
	_configurar_movimentacao()
	
	print("[BOSS] Boss Pássaro iniciado!")
	state = BossState.VOANDO

func _configurar_movimentacao() -> void:
	"""Tenta encontrar PathFollow2D como pai, senão usa senoidal"""
	path_follow_ref = get_parent() as PathFollow2D
	usar_path = path_follow_ref != null
	if not usar_path:
		base_y = global_position.y
		print("[BOSS] Sem PathFollow2D como pai. Usando movimento senoidal.")
	else:
		print("[BOSS] PathFollow2D encontrado como pai. Seguindo caminho.")

func _configurar_damage_area() -> void:
	damage_area.add_to_group("enemy_hitbox")
	damage_area.body_entered.connect(_on_damage_area_body_entered)

func _encontrar_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("receber_dano"):
			body.receber_dano(dano_contato)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_processar_movimento(delta)
	_processar_ciclo_ataque(delta)
	_atualizar_animacao()
	_olhar_para_player()
	
	move_and_slide()

func _processar_movimento(delta: float) -> void:
	if state == BossState.MORRENDO:
		velocity = Vector2.ZERO
		return
	
	# Durante o canto, o boss fica parado
	if state == BossState.CANTANDO or state == BossState.RECUO:
		velocity.x = move_toward(velocity.x, 0, velocidade_voo * 2 * delta)
		velocity.y = move_toward(velocity.y, 0, velocidade_voo * 2 * delta)
		return
	
	# Durante ataque de penas, boss continua se movendo
	if usar_path:
		_processar_path_movement(delta)
	else:
		_processar_senoidal_movement(delta)

func _processar_path_movement(delta: float) -> void:
	# Move o PathFollow2D pai ao longo do Path2D
	# O boss é filho do PathFollow2D, então se move junto automaticamente
	path_follow_ref.progress += velocidade_voo * delta
	
	# Para a velocity do CharacterBody2D (não precisa se mover por conta própria)
	velocity = Vector2.ZERO
	
	# Se passou do fim do path, volta ao início (loop)
	if path_follow_ref.progress_ratio >= 1.0:
		path_follow_ref.progress = 0.0

func _processar_senoidal_movement(delta: float) -> void:
	# Movimento senoidal (fallback)
	tempo_voo += delta
	
	# Fica parado no X, oscila no Y
	var seno_y = sin(tempo_voo * frequencia_senoidal * TAU) * amplitude_senoidal
	var target_y = base_y + seno_y
	
	var diff_y = target_y - global_position.y
	velocity.y = diff_y * 5 * delta
	velocity.x = move_toward(velocity.x, 0, velocidade_voo * 2 * delta)

func _olhar_para_player() -> void:
	if player == null:
		return
	# Boss sempre vira para o player
	# A sprite está virada para a esquerda por padrão (flip_h = false)
	# Quando o player está à direita, flip_h = true para virar para a direita
	var diff_x = player.global_position.x - global_position.x
	if diff_x > 0:
		anim.flip_h = true
	elif diff_x < 0:
		anim.flip_h = false

func _processar_ciclo_ataque(delta: float) -> void:
	if is_dead or state == BossState.RECUO or is_in_attack:
		return
	
	timer_ataque -= delta
	
	if timer_ataque <= 0:
		_executar_proximo_ataque()

func _executar_proximo_ataque() -> void:
	if ataques_penas_realizados >= ciclo_penas_antes_canto:
		# Hora do canto!
		ataques_penas_realizados = 0
		_iniciar_ataque_canto()
	else:
		# Atira penas
		ataques_penas_realizados += 1
		_iniciar_ataque_penas()

func _iniciar_ataque_penas() -> void:
	is_in_attack = true
	state = BossState.ATACANDO_PENAS
	
	print("[BOSS] Ataque de penas!")
	
	# Dispara penas em direção ao player (boss continua se movendo)
	_disparar_penas_para_player()
	
	# Aguarda o tempo de retorno e puxa as penas
	await get_tree().create_timer(tempo_retorno_penas).timeout
	
	if not is_dead:
		_puxar_penas_de_volta()
	
	await get_tree().create_timer(1.0).timeout
	
	if not is_dead:
		_terminar_ataque()

func _disparar_penas_para_player() -> void:
	var pena_scene = preload("res://fases/fase1_sertao/boss/Base_Scenes/Pena.tscn")
	if not pena_scene:
		push_error("[BOSS] Cena Pena.tscn não encontrada!")
		return
	
	if player == null:
		_encontrar_player()
	if player == null:
		return
	
	# Calcula direção base para o player
	var dir_base = (player.global_position - spawn_penas.global_position).normalized()
	var angulo_base = dir_base.angle()
	
	var angulo_inicial = -angulo_leque / 2.0
	var passo_angulo = angulo_leque / float(penas_por_leque - 1) if penas_por_leque > 1 else 0
	
	for i in range(penas_por_leque):
		var pena: Node2D = pena_scene.instantiate()
		pena.global_position = spawn_penas.global_position
		
		# Calcula direção do leque centrado no player
		var angulo_rad = angulo_base + deg_to_rad(angulo_inicial + passo_angulo * i)
		var direcao = Vector2(cos(angulo_rad), sin(angulo_rad)).normalized()
		pena.iniciar(direcao, velocidade_pena, distancia_pena_max, self)
		
		get_tree().current_scene.add_child(pena)
		penas_ativas.append(pena)
		
		# Pequeno delay entre cada pena
		await get_tree().create_timer(0.05).timeout

func _puxar_penas_de_volta() -> void:
	for pena in penas_ativas:
		if is_instance_valid(pena):
			pena.retornar_ao_boss()
	penas_ativas.clear()

func _iniciar_ataque_canto() -> void:
	is_in_attack = true
	state = BossState.CANTANDO
	_play_anim("sing")
	
	print("[BOSS] Rap do Zé Felipe!")
	
	# Spawna urubus em sequência
	for i in range(urubus_por_canto):
		if is_dead:
			return
		_spawnar_urubu()
		await get_tree().create_timer(intervalo_spawn_urubu).timeout
	
	# A cena dura um pouco mais
	await get_tree().create_timer(1.5).timeout
	
	if not is_dead:
		_terminar_ataque()

func _spawnar_urubu() -> void:
	var urubu_scene = preload("res://fases/fase1_sertao/boss/Base_Scenes/Urubu.tscn")
	if not urubu_scene:
		push_error("[BOSS] Cena Urubu.tscn não encontrada!")
		return
	
	if player == null:
		_encontrar_player()
	
	# Calcula posição de spawn baseada na altura do player
	var spawn_x: float
	if player != null:
		# Spawna à direita da tela, na altura do player com variação
		var viewport_size = get_viewport_rect().size
		spawn_x = max(global_position.x + 200, player.global_position.x + 400)
	else:
		spawn_x = global_position.x + 400
	
	# Spawna na altura do player (com pequena variação)
	var altura_player = player.global_position.y if player != null else global_position.y
	var altura_spawn = altura_player + randf_range(-20, 20)
	
	var spawn_pos = Vector2(spawn_x, altura_spawn)
	
	var urubu: Node2D = urubu_scene.instantiate()
	urubu.global_position = spawn_pos
	urubu.velocidade_base = velocidade_urubu
	
	get_tree().current_scene.add_child(urubu)

func _terminar_ataque() -> void:
	is_in_attack = false
	state = BossState.VOANDO
	timer_ataque = intervalo_penas

func _atualizar_animacao() -> void:
	if is_dead:
		return
	
	match state:
		BossState.VOANDO, BossState.ATACANDO_PENAS:
			_play_anim("voando")
		BossState.CANTANDO:
			_play_anim("sing")
		BossState.RECUO:
			_play_anim("hit")
		BossState.MORRENDO:
			_play_anim("death")
		_:
			_play_anim("idle")

func receber_dano(quantidade: int) -> void:
	if is_dead or is_hurt:
		return
	
	hp -= quantidade
	hp = max(hp, 0)
	print("[BOSS] HP: ", hp, "/", max_hp)
	
	if hp <= 0:
		_morrer()
	else:
		_levar_hit()

func _levar_hit() -> void:
	is_hurt = true
	state = BossState.RECUO
	_play_anim("hit")
	
	# Efeito visual de hit
	var tween = create_tween()
	tween.tween_property(anim, "modulate:a", 0.2, 0.05)
	tween.tween_property(anim, "modulate:a", 1.0, 0.05)
	
	await get_tree().create_timer(0.3).timeout
	
	if not is_dead:
		is_hurt = false
		state = BossState.VOANDO

func _morrer() -> void:
	is_dead = true
	state = BossState.MORRENDO
	velocity = Vector2.ZERO
	_play_anim("death")
	
	# Desativa dano de contato
	damage_area.monitoring = false
	
	# Destrói penas ativas
	for pena in penas_ativas:
		if is_instance_valid(pena):
			pena.queue_free()
	penas_ativas.clear()
	
	emit_signal("boss_died", global_position)
	
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _play_anim(nome: String) -> void:
	if not is_instance_valid(anim):
		return
	if anim.sprite_frames and anim.sprite_frames.has_animation(nome):
		if anim.animation != nome:
			anim.play(nome)

class_name BaseEnemy
extends CharacterBody2D

## Base de todo inimigo comum: vida, dano de contato, hit, morte, pontos e camadas de física.
## Cada inimigo herda, define os próprios estados e sobrescreve os ganchos _inicializar(),
## _ao_levar_hit() e _ao_morrer().

signal morreu(inimigo: BaseEnemy)
signal inimigo_morreu(pos: Vector2)

@export_group("Atributos")
@export var max_hp: int = 2
@export var dano_contato: int = 1
@export var velocidade: float = 80.0
@export var pontos: int = 10 # pontos ao ser derrotado (cada inimigo comum vale 10)

@export_group("Dano de contato")
@export var tamanho_dano_contato: Vector2 = Vector2(24.0, 24.0) # área que fere o player ao encostar
@export var deslocamento_dano_contato: Vector2 = Vector2.ZERO

@export_group("Reações")
@export var duracao_hit: float = 0.3 # s sem poder levar outro golpe
@export var duracao_morte: float = 0.6 # s entre morrer e sumir
@export var cor_hit: Color = Color(1.0, 0.35, 0.35) # usado quando não há animação "hit"
@export var usa_gravidade: bool = true
@export var sprite_olha_para_esquerda: bool = false # arte desenhada virada para a esquerda

var hp: int
var is_dead: bool = false
var is_hurt: bool = false
var player: CharacterBody2D = null
var direcao: float = 1.0
var dano_area: Hitbox = null

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = Camadas.INIMIGOS
	collision_mask = Camadas.CHAO
	hp = max_hp
	_configurar_hitbox_dano()
	_encontrar_player()
	_inicializar()


func _encontrar_player() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _configurar_hitbox_dano() -> void:
	if dano_contato <= 0:
		return
	dano_area = Hitbox.new()
	dano_area.name = "DamageArea"
	dano_area.equipe = Hitbox.Equipe.INIMIGO
	dano_area.dano = dano_contato
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho_dano_contato
	forma.shape = retangulo
	forma.position = deslocamento_dano_contato
	dano_area.add_child(forma)
	add_child(dano_area)


## Gancho: configuração própria de cada inimigo.
func _inicializar() -> void:
	pass


func _aplicar_gravidade(delta: float) -> void:
	if usa_gravidade and not is_on_floor():
		velocity += get_gravity() * delta


## Verdadeiro se não há chão logo à frente (para não andar para fora de plataformas).
func _na_borda(alcance: float = 12.0, profundidade: float = 24.0) -> bool:
	var espaco: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var origem: Vector2 = global_position + Vector2(direcao * alcance, 0.0)
	var consulta := PhysicsRayQueryParameters2D.create(origem, origem + Vector2(0.0, profundidade), Camadas.CHAO)
	consulta.exclude = [get_rid()]
	return espaco.intersect_ray(consulta).is_empty()


func distancia_ao_player() -> float:
	if not is_instance_valid(player):
		return INF
	return global_position.distance_to(player.global_position)


func receber_dano(quantidade: int, _origem: Vector2 = Vector2.INF) -> void:
	if is_dead or is_hurt:
		return
	hp = maxi(hp - quantidade, 0)
	if hp <= 0:
		_morrer()
	else:
		_levar_hit()


func _levar_hit() -> void:
	is_hurt = true
	_ao_levar_hit()
	_play_anim("hit")
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
	if dano_area != null:
		dano_area.ativa = false
	collision_layer = 0
	PlayerData.adicionar_pontos(pontos)
	_ao_morrer()
	morreu.emit(self)
	inimigo_morreu.emit(global_position)
	Events.enemy_defeated.emit(self)
	remove_from_group("enemy")
	_animar_morte()
	await get_tree().create_timer(duracao_morte, false).timeout
	queue_free()


## Gancho: reação ao golpe (interromper ataque, recuar...).
func _ao_levar_hit() -> void:
	pass


## Gancho: limpeza ao morrer (remover teias, soltar ponto de spawn...).
func _ao_morrer() -> void:
	pass


## Animação "death" se existir; senão, cai e desaparece.
func _animar_morte() -> void:
	if anim == null:
		return
	if anim.sprite_frames != null and anim.sprite_frames.has_animation("death"):
		anim.play("death")
	else:
		var tween: Tween = create_tween().set_parallel()
		tween.tween_property(anim, "position:y", anim.position.y + 24.0, duracao_morte).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(anim, "modulate:a", 0.0, duracao_morte)
		tween.tween_property(anim, "rotation", PI * 0.5 * direcao, duracao_morte)


func _atualizar_flip() -> void:
	if anim != null:
		anim.flip_h = (direcao > 0.0) if sprite_olha_para_esquerda else (direcao < 0.0)


func _play_anim(nome: String) -> void:
	if not is_instance_valid(anim):
		return
	if anim.sprite_frames and anim.sprite_frames.has_animation(nome):
		if anim.animation != nome:
			anim.play(nome)

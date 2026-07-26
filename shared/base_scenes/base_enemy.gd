extends CharacterBody2D

class_name BaseEnemy

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@export var max_hp: int = 2
@export var dano_contato: int = 1
@export var velocidade: float = 80.0

var hp: int
var is_dead: bool = false
var is_hurt: bool = false

var player: CharacterBody2D = null

var direcao: float = 1.0

signal inimigo_morreu(pos: Vector2)

func _ready() -> void:
	hp = max_hp
	_configurar_hitbox_dano()
	_encontrar_player()
	_inicializar()
	print("[SISTEMA] Inimigo instanciado. O Player não é null? ", player != null)

func _encontrar_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func _configurar_hitbox_dano() -> void:
	var area = Area2D.new()
	area.name = "DamageArea"
	area.add_to_group("enemy_hitbox")

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(50, 60)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_damage_area_body_entered)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("receber_dano"):
			body.receber_dano(dano_contato)

func _inicializar() -> void:
	pass

func _aplicar_gravidade(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _na_borda() -> bool:
	var space = get_world_2d().direct_space_state
	var from = global_position + Vector2(direcao * 30, 0)
	var to = from + Vector2(0, 40)
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	var result = space.intersect_ray(query)
	return result.is_empty()

func receber_dano(quantidade: int) -> void:
	if is_dead or is_hurt:
		return

	hp -= quantidade
	hp = max(hp, 0)

	if hp <= 0:
		_morrer()
	else:
		_levar_hit()

func _levar_hit() -> void:
	is_hurt = true
	_play_anim("hit")

	var tween = create_tween()
	tween.tween_property(anim, "modulate:a", 0.2, 0.05)
	tween.tween_property(anim, "modulate:a", 1.0, 0.05)

	await get_tree().create_timer(0.3).timeout
	is_hurt = false

func _morrer() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	emit_signal("inimigo_morreu", global_position)
	_play_anim("death")

	await get_tree().create_timer(0.6).timeout
	queue_free()

func _atualizar_flip() -> void:
	anim.flip_h = direcao < 0

func _play_anim(nome: String) -> void:
	if not is_instance_valid(anim):
		return
	if anim.sprite_frames and anim.sprite_frames.has_animation(nome):
		if anim.animation != nome:
			anim.play(nome)

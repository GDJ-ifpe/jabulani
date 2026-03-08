extends CharacterBody2D

# MUITO CUIDADO AO MEXER NAS CONSTANTES PODE OCASIONAR BUGS DE GRAVIDADE
@export var SPEED = 250.0
const air_friction := 1

var jabusintese := preload("res://shared/player/scenes/powerups/jabusintese.tscn") # preload para power up
var knockback_vector := Vector2.ZERO
var direction
var is_hurted := false
@export var altura_pulo = 200
@export var tempo_ate_topo_salto := 0.5
@export var jabu = false
var jump_velocity
var gravity
var fall_gravity
var delay = true
var player_position = position
@onready var ray_d := $RayCast2D_D as RayCast2D
@onready var ray_e := $RayCast2D_E as RayCast2D
@onready var anim := $anim as AnimatedSprite2D
@onready var remote_transform := $remote as RemoteTransform2D
@onready var atacando := false
signal player_has_died()

func _ready() -> void:
	jump_velocity = (altura_pulo * 2) / tempo_ate_topo_salto
	gravity = (altura_pulo * 2) / pow(tempo_ate_topo_salto, 2)
	fall_gravity = gravity 
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_select") and jabu and delay: # spawn do powerup jabusintese (adptar para receber outros powerups)
		spawn_jabusintese()
		await get_tree().create_timer(5).timeout
		delay = true
	if Input.is_action_just_pressed("ui_accept"): # chama func de ataque
		ataque()
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.x = 0
	if velocity.y > 0 or not Input.is_action_pressed("ui_up"):
		velocity.y += fall_gravity * delta
	else:
		velocity.y += gravity * delta
		
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = -jump_velocity
	direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = lerp(velocity.x, direction * SPEED, air_friction)
		anim.scale.x = direction
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if knockback_vector != Vector2.ZERO:
			velocity = knockback_vector
	_set_state()
	move_and_slide()
	for platforms in get_slide_collision_count(): # verificação constante de colisao
		var collision = get_slide_collision(platforms)
		if collision.get_collider().has_method("has_collided_with"):
			collision.get_collider().has_collided_with(collision, self)

func _on_hurtbox_body_entered(body: Node2D) -> void: # sistema de knockback personalizavel
	if body.is_in_group("limites"):
		emit_signal("player_has_died")
	if body.is_in_group("pilar"):
		take_damage(Vector2(0, -1000))
	if body.is_in_group("inimigos"):
		take_damage(Vector2(100, -100))
	if body.is_in_group("projetil"):
		body.queue_free()
		take_damage(Vector2(-150, -100))
	if PlayerManager.player_life <= 0:
		_set_state()
	else:
		if ray_d.is_colliding():
			take_damage(Vector2(-1200, -1200))
		elif ray_e.is_colliding():
			take_damage(Vector2(1200, -1200))
		elif $RayCast2D_B.is_colliding() and !SceneManagerLitoral.boss:
			take_damage(Vector2(0, -1200))
		elif $RayCast2D_C.is_colliding():
			take_damage(Vector2(1200, -1200))

func ataque():
	var porradao = $ataque.get_overlapping_areas()
	for area in porradao: # dano em inimigos
		var parent = area.get_parent()
		parent.vida -= 1
		if parent.nome == "boss": # controle de visualização de hit em inimigos
			SceneManagerLitoral.anim.modulate = Color(1,0,0,1)
			await get_tree().create_timer(0.02).timeout
			SceneManagerLitoral.anim.modulate = Color(1,1,1,1)
		else:
			parent.anim.modulate = Color(1,0,0,1)
			await get_tree().create_timer(0.05).timeout
			parent.anim.modulate = Color(1,1,1,1)
	atacando = true
	anim.play("ataque")

func take_damage(knockback_force := Vector2.ZERO, duration := 0.25): # knockback e gerencimento de vida
	PlayerManager.player_life -= 1
	if knockback_force != Vector2.ZERO:
		knockback_vector = knockback_force
		var knockback_tween := get_tree().create_tween()
		knockback_tween.parallel().tween_property(self, "knockback_vector", Vector2.ZERO, duration)
		anim.modulate = Color(1,0,0,1)
		knockback_tween.parallel().tween_property(anim, "modulate", Color(1,1,1,1), duration)
	is_hurted = true
	await get_tree().create_timer(.3).timeout
	is_hurted = false

func _set_state(): # controle de animação do player
	if PlayerManager.player_life <= 0: # animação de morte
		anim.play("morte")
		await get_tree().create_timer(1.0).timeout
		queue_free()
		emit_signal("player_has_died")
		
	else:
		if !atacando:
			var state = "idle-pre-ataque"
			if SceneManagerLitoral.boss:
				state = "idle-pos-ataque"
			if !is_on_floor():
				state = "salto"
			elif direction != 0 and is_on_floor():
				state = "correndo"
			if is_hurted:
				state = "hitado"
			if anim.name != state:
				anim.play(state)

func follow_camera(camera): # camera basica (melhorar depois)
	var camera_path = camera.get_path()
	remote_transform.remote_path = camera_path

func _on_anim_animation_finished() -> void: # controle de animaçao de ataque
	atacando = false

func spawn_jabusintese(): 
	var new_jabu = jabusintese.instantiate()
	get_tree().current_scene.add_child(new_jabu)
	new_jabu.position = global_position
	delay = false
	PlayerManager.player_power -= 1
	if PlayerManager.player_power == 0:
		jabu = false

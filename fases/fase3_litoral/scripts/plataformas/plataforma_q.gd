extends AnimatableBody2D

@onready var anim := $anim as AnimationPlayer
@onready var respawn_timer := $respawn_timer as Timer
@onready var respawn_position := global_position
@export var reset_timer := 3.0
var velocity = Vector2.ZERO
var gravity = 500.0
var is_triggered := false

func _ready() -> void:
	set_physics_process(false)

func _physics_process(_delta: float) -> void:
	velocity.y += gravity * _delta
	position += velocity * _delta

func has_collided_with(_collision: KinematicCollision2D,_collider: CharacterBody2D):
	if !is_triggered:
		is_triggered = true
		anim.play("tremor")
		velocity = Vector2.ZERO


func _on_anim_animation_finished(_anim_name: StringName) -> void:
	set_physics_process(true)
	respawn_timer.start(reset_timer)


func _on_respawn_timer_timeout() -> void:
	set_physics_process(false)
	global_position = respawn_position
	if is_triggered:
		var spawn_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
		spawn_tween.tween_property($Sprite2D, "scale", Vector2(2,2), 0.2).from(Vector2(0,0))
	is_triggered = false

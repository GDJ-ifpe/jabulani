extends CharacterBody2D

var vida = 3
const SPEED = 400.0
var direction := -1
var nome := "inimigos"
@onready var wall_detector := $wall_detector as RayCast2D
@onready var anim := $AnimatedSprite2D as AnimatedSprite2D
func _process(_delta: float) -> void:
	if vida == 0:
		$AnimatedSprite2D.play("morte")
		await get_tree().create_timer(1.5).timeout
		queue_free()
func _physics_process(_delta: float) -> void:
	if wall_detector.is_colliding():
		direction *= -1
		wall_detector.scale.x *= -1
	if direction == 1:
		anim.flip_h = true
	else:
		anim.flip_h = false
	velocity.x = direction * SPEED
	move_and_slide()

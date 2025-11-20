extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
var vida = 3
var nome := "inimigos"
const SPEED = 00.0
var direction := -1
func _process(_delta: float) -> void:
	if vida == 0:
		$AnimatedSprite2D.play("morte")
		await get_tree().create_timer(1.0).timeout
		queue_free()
func _physics_process(_delta: float) -> void:
	velocity.x = direction * SPEED
	move_and_slide()

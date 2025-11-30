extends CharacterBody2D

var vida = 3
const SPEED = 400.0

var direction := -1 # não mexer, evitar bug de animação
var nome := "inimigos" # para detecção de colisao

@onready var wall_detector := $wall_detector as RayCast2D
@onready var anim := $AnimatedSprite2D as AnimatedSprite2D

func _process(_delta: float) -> void: # gerenciamento de vida
	if vida == 0:
		$AnimatedSprite2D.play("morte")
		PlayerManager.pontos += 10
		await get_tree().create_timer(1.5).timeout
		queue_free()
func _physics_process(_delta: float) -> void: # detecção de colisao e split de animaçao
	if wall_detector.is_colliding():
		direction *= -1
		wall_detector.scale.x *= -1
	if direction == 1:
		anim.flip_h = true
	else:
		anim.flip_h = false
	velocity.x = direction * SPEED
	move_and_slide()

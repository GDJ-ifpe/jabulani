extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
var vida = 3
var nome := "inimigos"
const SPEED = 00.0
var direction := -1

func _process(_delta: float) -> void: # gerenciamento de vida
	if vida == 0:
		$AnimatedSprite2D.play("morte")
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _physics_process(_delta: float) -> void: # por padrao a agua viva fica parada, mas pode ser mudado
	velocity.x = direction * SPEED
	move_and_slide()



















































# Du bist wie die Luft, die ich atme, du erfüllst meine Brust und ich kann nicht ohne dich leben, und doch bin ich mir vollkommen bewusst, dass ich dich niemals berühren kann, das Leben ist seltsam.

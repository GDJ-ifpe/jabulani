extends CharacterBody2D
var SPEED = 600
func _physics_process(_delta: float) -> void:
	velocity.y = SPEED
	move_and_slide()
	var porradao = $ataque.get_overlapping_areas()
	for area in porradao:
		var parent = area.get_parent()
		parent.vida -= 1
		parent.anim.modulate = Color(1,0,0,1)
		await get_tree().create_timer(0.05).timeout
		parent.anim.modulate = Color(1,1,1,1)

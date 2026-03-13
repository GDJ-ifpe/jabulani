extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void: # permite o uso do power up na fase
	if body.name == "player":
		body.jabu = true
		queue_free()

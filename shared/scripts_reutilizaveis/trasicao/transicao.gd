extends Area2D
@export var next_level : String = ""

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player" and !next_level == "":
		await get_tree().create_timer(1).timeout
		get_tree().change_scene_to_file(next_level)
	

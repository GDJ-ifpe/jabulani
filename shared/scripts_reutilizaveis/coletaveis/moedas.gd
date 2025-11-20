extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if "player" in body.name:
		await $Area2D/CollisionShape2D.call_deferred("queue_free")
		PlayerManager.pontos += 15
		queue_free()

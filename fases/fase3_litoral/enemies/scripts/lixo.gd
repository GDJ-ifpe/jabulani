extends CharacterBody2D

var move_speed := 400.0
var direction := -1
var vida := 1
var nome = "boss"
func _process(_delta: float) -> void:
	
	position.x += move_speed * direction * _delta
	if vida <= 0:
		queue_free()

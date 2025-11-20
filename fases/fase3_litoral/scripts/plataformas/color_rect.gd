extends ColorRect

var threshold = 0.0

func _process(_delta: float) -> void:
	material.set("shader_parameter/threshold", threshold)

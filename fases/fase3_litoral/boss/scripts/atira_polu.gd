extends CharacterBody2D
var vida = 20
var nome = "boss"
const LIXO = preload("uid://be565oo6n812d")
func _process(_delta: float) -> void:
	if vida <= 0:
		SceneManagerLitoral.olhos = true
		SceneManagerLitoral.morte_adm = true
		await get_tree().create_timer(0.75).timeout
		SceneManagerLitoral.adm = true
		queue_free()

	

func spawn_lixo():
	var new_lixo = LIXO.instantiate()
	add_child(new_lixo) 


func _on_timer_timeout() -> void:
	SceneManagerLitoral.ataque_lixo = true
	await get_tree().create_timer(0.4).timeout
	spawn_lixo()
	SceneManagerLitoral.ataque_lixo = false

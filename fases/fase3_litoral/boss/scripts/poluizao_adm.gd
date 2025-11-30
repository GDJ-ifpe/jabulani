extends Node2D

var pilar = [0,1,2]
var pilarP1 = 0
var pilarP2 = 0
var vida = 20
var nome = "boss" # para detecção de colisao
func _ready() -> void:
	pass

func _process(_delta: float) -> void: # gerenciamento de morte da cabeça pilar
	if vida <= 0:
		SceneManagerLitoral.morte_pilar = true
		SceneManagerLitoral.adm = false
		SceneManagerLitoral.olhos = false
		await get_tree().create_timer(0.75).timeout
		SceneManagerLitoral.morte = true
		queue_free()

func _on_timer_timeout() -> void: # gerenciamento dos ataques do pilar
	SceneManagerLitoral.olhos = true
	pilar.shuffle()
	pilarP1 = pilar[0]
	pilarP2 = pilar[1]

	if pilarP1 == 0 or pilarP2 == 0:
		$"../pilar".start_flash()
		await get_tree().create_timer(2.0).timeout
		$"../pilar".move_platform()
	if pilarP1 == 1 or pilarP2 == 1:
		$"../pilar2".start_flash()
		await get_tree().create_timer(2.0).timeout
		$"../pilar2".move_platform()
	if pilarP1 == 2 or pilarP2 == 2:
		$"../pilar3".start_flash()
		await get_tree().create_timer(2.0).timeout
		$"../pilar3".move_platform()
	SceneManagerLitoral.olhos = false
	await get_tree().create_timer(3.0).timeout
	_on_timer_timeout()
	

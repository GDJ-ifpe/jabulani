extends Node2D

@onready var _anim := $AnimatedSprite2D as AnimatedSprite2D

var state
func _ready() -> void:
	pass
func _process(_delta: float) -> void:
	SceneManagerLitoral.anim = _anim
	SceneManagerLitoral.boss = true
	_set_state()
	if SceneManagerLitoral.olhos and SceneManagerLitoral.adm:
		await get_tree().create_timer(1.5).timeout
		if !SceneManagerLitoral.morte:
			$"../cabeca_adm".process_mode = Node.PROCESS_MODE_INHERIT
func _set_state():
	#ataque atira()
	if !SceneManagerLitoral.adm and !SceneManagerLitoral.morte_adm and !SceneManagerLitoral.ataque_lixo:
		state = "idle"
	if !SceneManagerLitoral.olhos and SceneManagerLitoral.adm and !SceneManagerLitoral.morte_adm: 
		state = "idle_2"
	if SceneManagerLitoral.olhos and SceneManagerLitoral.adm and !SceneManagerLitoral.morte_adm:
		state = "ataque_pilar"
	if SceneManagerLitoral.ataque_lixo and !SceneManagerLitoral.adm:
		state = "ataque_adm"
	if SceneManagerLitoral.morte_adm:
		state = "morte_adm"
		SceneManagerLitoral.morte_adm = false
	if SceneManagerLitoral.morte_pilar:
		state = "morte_pilar"
		SceneManagerLitoral.morte_pilar = false
	if SceneManagerLitoral.morte and !SceneManagerLitoral.morte_pilar:
		state = "morte_final"
	if _anim.name != state:
		_anim.play(state)
		if SceneManagerLitoral.morte and state == "morte_final":
			await get_tree().create_timer(0.75).timeout
			_anim.play("idle_3")

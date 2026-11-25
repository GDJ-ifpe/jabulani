class_name Arena
extends Node2D

## Raiz de uma arena de ondas: limita a câmera do player, toca música/ambiente
## e mostra os avisos de onda e de saída aberta.

@export var limites: Rect2i = Rect2i(0, 0, 1280, 360) # área visível da arena (padrão: 2 telas de largura)
@export var titulo_conclusao: String = "Subfase concluída" # título da tela mostrada ao sair
@export var musica: AudioStream
@export var ambiente: AudioStream
@export var aviso: Label # texto central temporário ("Onda 1", "Saída aberta!")
@export var duracao_aviso: float = 2.0

var _tween_aviso: Tween


func _ready() -> void:
	add_to_group("arena")
	_limitar_camera()
	if musica != null:
		AudioManager.tocar_musica(musica)
	else:
		AudioManager.parar_musica()
	if ambiente != null:
		AudioManager.tocar_ambiente(ambiente)
	else:
		AudioManager.parar_ambiente()
	if aviso != null:
		aviso.modulate.a = 0.0
	Events.wave_started.connect(_on_onda)
	Events.spawner_finished.connect(_mostrar_aviso.bind("Derrote os inimigos restantes!"))
	_conectar_saidas.call_deferred()


func _conectar_saidas() -> void:
	for porta in get_tree().get_nodes_in_group("exit_gate"):
		if porta is ExitGate:
			(porta as ExitGate).abriu.connect(_mostrar_aviso.bind("Saída aberta!"))


func _limitar_camera() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = limites.position.x
	camera.limit_top = limites.position.y
	camera.limit_right = limites.end.x
	camera.limit_bottom = limites.end.y
	camera.reset_smoothing()


func _on_onda(numero: int) -> void:
	_mostrar_aviso("Onda %d" % numero)


func _mostrar_aviso(texto: String) -> void:
	if aviso == null:
		return
	aviso.text = texto
	if _tween_aviso != null:
		_tween_aviso.kill()
	_tween_aviso = create_tween()
	_tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	_tween_aviso.tween_interval(duracao_aviso)
	_tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)

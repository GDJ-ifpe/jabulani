class_name ExitGate
extends Area2D

## Saída da arena. Fica fechada (com barreira sólida) até a arena ser limpa e não haver
## nenhum bloqueio no grupo "bloqueio_saida" (ex.: parede de teia da aranha).
## Quando o player atravessa a saída aberta, avisa o jogo por Events.exit_reached.

signal abriu

@export_file("*.tscn") var proxima_cena: String = ""
@export var barreira: CollisionObject2D # corpo sólido que fecha a passagem
@export var visual_fechada: CanvasItem
@export var visual_aberta: CanvasItem

var arena_limpa: bool = false
var aberta: bool = false
var _usada: bool = false


func _ready() -> void:
	add_to_group("exit_gate")
	collision_layer = 0
	collision_mask = Camadas.PLAYER
	body_entered.connect(_on_body_entered)
	Events.arena_cleared.connect(_on_arena_limpa)
	_atualizar_visual()


func _process(_delta: float) -> void:
	if arena_limpa and not aberta and not _ha_bloqueio():
		_abrir()


func _on_arena_limpa() -> void:
	arena_limpa = true


func _ha_bloqueio() -> bool:
	return not get_tree().get_nodes_in_group("bloqueio_saida").is_empty()


func _abrir() -> void:
	aberta = true
	if barreira != null:
		barreira.collision_layer = 0
	_atualizar_visual()
	AudioManager.tocar_sfx(&"TODO_AUDIO_saida_aberta")
	abriu.emit()
	for corpo in get_overlapping_bodies():
		_on_body_entered(corpo)


func _atualizar_visual() -> void:
	if visual_fechada != null:
		visual_fechada.visible = not aberta
	if visual_aberta != null:
		visual_aberta.visible = aberta


func _on_body_entered(corpo: Node2D) -> void:
	if not aberta or _usada or not corpo.is_in_group("player"):
		return
	_usada = true
	Events.exit_reached.emit(proxima_cena)

class_name TemporaryPlatform
extends StaticBody2D

## Plataforma que some depois de ser pisada e reaparece no mesmo lugar.
## Antes de sumir ela avisa: treme e pisca durante `tempo_ate_sumir`.
## A origem do nó é o canto superior esquerdo da plataforma.
## Visual provisório (TODO_ARTE_plataforma_poeira) quando `visual` não é informado.

signal sumiu
signal reapareceu

enum Estado { FIRME, AVISANDO, SUMIDA }

@export var tamanho: Vector2 = Vector2(96.0, 8.0) # largura e espessura da parte sólida (px)
@export var tempo_ate_sumir: float = 0.6 # s de aviso entre ser pisada e sumir
@export var tempo_para_reaparecer: float = 3.0 # s sumida antes de voltar
@export var visual: CanvasItem
@export var cor_provisoria: Color = Color(0.98, 0.93, 0.78, 0.95)

var estado: Estado = Estado.FIRME
var _tempo: float = 0.0
var _forma: CollisionShape2D
var _sensor: Area2D
var _posicao_visual: Vector2 = Vector2.ZERO


func _ready() -> void:
	collision_layer = Camadas.PLATAFORMA_VAZADA
	collision_mask = 0

	_forma = CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho
	_forma.shape = retangulo
	_forma.position = tamanho * 0.5
	_forma.one_way_collision = true
	add_child(_forma)

	# Faixa fina logo acima da plataforma: detecta quem está apoiado nela.
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = Camadas.PLAYER
	_sensor.monitorable = false
	var forma_sensor := CollisionShape2D.new()
	var retangulo_sensor := RectangleShape2D.new()
	retangulo_sensor.size = Vector2(tamanho.x, 6.0)
	forma_sensor.shape = retangulo_sensor
	forma_sensor.position = Vector2(tamanho.x * 0.5, -3.0)
	_sensor.add_child(forma_sensor)
	add_child(_sensor)

	if visual == null:
		visual = _criar_visual_provisorio()
	if visual is Node2D:
		_posicao_visual = (visual as Node2D).position


func _criar_visual_provisorio() -> CanvasItem:
	var poligono := Polygon2D.new()
	poligono.name = "TODO_ARTE_plataforma_poeira"
	poligono.color = cor_provisoria
	poligono.polygon = PackedVector2Array([
		Vector2(4.0, 0.0), Vector2(tamanho.x - 4.0, 0.0), Vector2(tamanho.x, tamanho.y * 0.5),
		Vector2(tamanho.x - 6.0, tamanho.y), Vector2(6.0, tamanho.y), Vector2(0.0, tamanho.y * 0.5),
	])
	add_child(poligono)
	return poligono


func _physics_process(delta: float) -> void:
	match estado:
		Estado.FIRME:
			if _alguem_pisando():
				_avisar()
		Estado.AVISANDO:
			_tempo -= delta
			_tremer()
			if _tempo <= 0.0:
				_sumir()
		Estado.SUMIDA:
			_tempo -= delta
			if _tempo <= 0.0:
				_reaparecer()


func _alguem_pisando() -> bool:
	for corpo in _sensor.get_overlapping_bodies():
		var personagem := corpo as CharacterBody2D
		if personagem != null and personagem.is_on_floor() and personagem.velocity.y >= 0.0:
			return true
	return false


func _avisar() -> void:
	estado = Estado.AVISANDO
	_tempo = tempo_ate_sumir
	AudioManager.tocar_sfx(&"TODO_AUDIO_plataforma_poeira", -8.0)


func _tremer() -> void:
	if visual == null:
		return
	visual.modulate.a = 0.55 + 0.45 * sin(_tempo * 40.0)
	if visual is Node2D:
		(visual as Node2D).position = _posicao_visual + Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5))


func _sumir() -> void:
	estado = Estado.SUMIDA
	_tempo = tempo_para_reaparecer
	_forma.set_deferred("disabled", true)
	if visual != null:
		visual.modulate.a = 0.0
		if visual is Node2D:
			(visual as Node2D).position = _posicao_visual
	sumiu.emit()


func _reaparecer() -> void:
	estado = Estado.FIRME
	_forma.set_deferred("disabled", false)
	if visual != null:
		create_tween().tween_property(visual, "modulate:a", 1.0, 0.2)
	reapareceu.emit()

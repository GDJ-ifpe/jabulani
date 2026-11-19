extends Node2D

## Palco da cena depois do Carlitos ("O canto da morte..."): a água brota do chão rachado,
## plantas verdes crescem e nuvens de chuva se formam; Carlitos fala, vira água e dá origem
## a um lago; começa uma chuva fraca e o narrador encerra.
## Cada método público é uma ação chamada por um passo do CutscenePlayer.
## Sem ilustrações próprias: formas simples marcadas com TODO_ARTE_*.

const FUNDO_SERTAO: PackedScene = preload("res://fases/fase1_sertao/assets/backgrounds/sertao/fundo_sertao.tscn")
const QUADROS_CARLITOS: SpriteFrames = preload("res://fases/fase1_sertao/boss/Base_Scenes/carlitos_frames.tres")
const QUADROS_JABULANI: SpriteFrames = preload("res://shared/player/jabulani_frames.tres")

@export var altura_do_chao: float = 330.0 # y do chão na tela
@export var posicao_carlitos: Vector2 = Vector2(430.0, 258.0) # centro da cartola
@export var cor_agua: Color = Color(0.3, 0.62, 0.9, 0.85)
@export var cor_planta: Color = Color(0.25, 0.7, 0.25)
@export var cor_nuvem: Color = Color(0.3, 0.33, 0.42, 0.35) # o céu fecha: a tela inteira escurece um pouco

var _carlitos: AnimatedSprite2D
var _nuvens: ColorRect
var _lago: Polygon2D
var _chuva: CPUParticles2D


func _ready() -> void:
	add_child(FUNDO_SERTAO.instantiate())

	_lago = Polygon2D.new()
	_lago.name = "TODO_ARTE_lago"
	_lago.color = cor_agua
	_lago.polygon = PackedVector2Array([Vector2(-90, 0), Vector2(-60, -8), Vector2(0, -11), Vector2(60, -8), Vector2(90, 0), Vector2(60, 7), Vector2(0, 9), Vector2(-60, 7)])
	_lago.position = Vector2(posicao_carlitos.x, altura_do_chao)
	_lago.scale = Vector2.ZERO
	add_child(_lago)

	_carlitos = AnimatedSprite2D.new()
	_carlitos.sprite_frames = QUADROS_CARLITOS
	_carlitos.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_carlitos.scale = Vector2(0.28, 0.28)
	_carlitos.position = posicao_carlitos
	add_child(_carlitos)
	_carlitos.play("idle")

	var jabulani := AnimatedSprite2D.new()
	jabulani.sprite_frames = QUADROS_JABULANI
	jabulani.scale = Vector2(0.22, 0.22)
	jabulani.position = Vector2(230.0, altura_do_chao - 26.0)
	jabulani.flip_h = true
	add_child(jabulani)
	jabulani.play("idle")

	_nuvens = ColorRect.new()
	_nuvens.name = "TODO_ARTE_nuvens_de_chuva"
	_nuvens.color = Color(cor_nuvem.r, cor_nuvem.g, cor_nuvem.b, 0.0)
	_nuvens.size = Vector2(640.0, 360.0)
	add_child(_nuvens)

	_chuva = CPUParticles2D.new()
	_chuva.name = "TODO_ARTE_chuva"
	_chuva.position = Vector2(320.0, -10.0)
	_chuva.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_chuva.emission_rect_extents = Vector2(340.0, 1.0)
	_chuva.direction = Vector2(-0.15, 1.0)
	_chuva.spread = 2.0
	_chuva.gravity = Vector2.ZERO
	_chuva.initial_velocity_min = 260.0
	_chuva.initial_velocity_max = 320.0
	_chuva.amount = 40 # chuva fraca
	_chuva.lifetime = 1.4
	_chuva.scale_amount_min = 1.0
	_chuva.scale_amount_max = 2.0
	_chuva.color = Color(0.75, 0.85, 1.0, 0.7)
	_chuva.emitting = false
	add_child(_chuva)


# ---------------------------------------------------------------- ações dos passos

## Água brota do chão rachado, plantas verdes crescem e nuvens de chuva se formam.
func brotar_agua() -> void:
	for x in [90.0, 180.0, 300.0, 520.0, 590.0]:
		_jorro(x)
	for x in [60.0, 140.0, 260.0, 350.0, 490.0, 560.0, 610.0]:
		_planta(x)
	create_tween().tween_property(_nuvens, "color:a", cor_nuvem.a, 2.0)
	AudioManager.tocar_sfx(&"TODO_AUDIO_agua_brotando", -4.0)


## Carlitos se transforma em água e dá origem a um lago; chuva fraca começa.
func virar_lago() -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_carlitos, "modulate", Color(cor_agua.r, cor_agua.g, cor_agua.b, 0.0), 1.6)
	tween.tween_property(_carlitos, "scale", Vector2(0.36, 0.08), 1.6)
	tween.tween_property(_carlitos, "position:y", altura_do_chao - 4.0, 1.6)
	tween.tween_property(_lago, "scale", Vector2.ONE, 1.8).set_delay(0.6)
	_chuva.emitting = true
	AudioManager.tocar_sfx(&"TODO_AUDIO_chuva", -6.0)


# ---------------------------------------------------------------- apoio

func _jorro(x: float) -> void:
	var agua := Polygon2D.new()
	agua.name = "TODO_ARTE_agua_brotando"
	agua.color = cor_agua
	agua.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(-2, -22), Vector2(0, -26), Vector2(2, -22), Vector2(5, 0)])
	agua.position = Vector2(x, altura_do_chao)
	agua.scale = Vector2(1.0, 0.0)
	add_child(agua)
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(agua, "scale:y", 1.0, 0.5).set_delay(randf() * 0.6)
	tween.tween_property(agua, "scale:y", 0.55, 0.4)


func _planta(x: float) -> void:
	var planta := Polygon2D.new()
	planta.name = "TODO_ARTE_planta"
	planta.color = cor_planta
	planta.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(-9, -10), Vector2(-3, -5), Vector2(0, -16), Vector2(3, -5), Vector2(9, -10), Vector2(6, 0)])
	planta.position = Vector2(x, altura_do_chao)
	planta.scale = Vector2.ZERO
	add_child(planta)
	create_tween().tween_property(planta, "scale", Vector2.ONE, 1.2).set_delay(0.5 + randf() * 1.0)

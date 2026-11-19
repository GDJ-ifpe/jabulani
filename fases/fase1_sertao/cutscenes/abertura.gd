extends Node2D

## Palco da abertura ("O chamado das águas..."): mostra as imagens que acompanham a narração.
## Cada método público é uma ação chamada por uma fala do CutscenePlayer.
## Ilustrações próprias ainda não existem: usa os fundos do jogo.

const FUNDO_SERTAO: PackedScene = preload("res://fases/fase1_sertao/assets/backgrounds/sertao/fundo_sertao.tscn")
const FUNDO_LITORAL: Texture2D = preload("res://fases/fase3_litoral/assets/backgrounds/litoral_up.png")
const FUNDO_CAVERNA: Texture2D = preload("res://fases/fase1_sertao/assets/backgrounds/caverna/camada_5.png")
const FRENTE_CAVERNA: Texture2D = preload("res://fases/fase1_sertao/assets/backgrounds/caverna/camada_2.png")
const QUADROS_JABULANI: SpriteFrames = preload("res://shared/player/jabulani_frames.tres")

const TELA: Vector2 = Vector2(640.0, 360.0)

@export var duracao_fade: float = 0.6 # s
@export var cor_zona_da_mata: Color = Color(0.16, 0.3, 0.14)
@export var cor_poluicao: Color = Color(0.5, 0.42, 0.36)

var _cena_atual: Node2D = null
var _escuro: ColorRect
var _tween: Tween
var _pedido: int = 0


func _ready() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 5
	add_child(camada)
	_escuro = ColorRect.new()
	_escuro.color = Color.BLACK
	_escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(_escuro)


# ---------------------------------------------------------------- ações das falas

## "Antes tudo era verde...": as regiões ainda preservadas.
func mostrar_regioes_verdes() -> void:
	_trocar(_imagem(FUNDO_LITORAL, Color.WHITE))


## "Até que um dia": a tela escurece.
func escurecer() -> void:
	_pedido += 1
	_fade(1.0)


## "...veio a seca": o sertão de terra rachada.
func mostrar_seca() -> void:
	_trocar(FUNDO_SERTAO.instantiate())


## "o lixo": a zona da mata cheia de resíduos.
func mostrar_lixo() -> void:
	var fundo := Node2D.new()
	var cor := ColorRect.new()
	cor.color = cor_zona_da_mata
	cor.size = TELA
	fundo.add_child(cor)
	_trocar(fundo)


## "a poluição": o litoral com manchas de óleo e peixes mortos.
func mostrar_poluicao() -> void:
	_trocar(_imagem(FUNDO_LITORAL, cor_poluicao))


## Fim da narração: Jabulani acorda na caverna e levanta o canudo.
func acordar_jabulani() -> void:
	var fundo := Node2D.new()
	fundo.add_child(_imagem(FUNDO_CAVERNA, Color.WHITE))
	fundo.add_child(_imagem(FRENTE_CAVERNA, Color.WHITE))
	var jabulani := AnimatedSprite2D.new()
	jabulani.sprite_frames = QUADROS_JABULANI
	jabulani.scale = Vector2(0.5, 0.5)
	jabulani.position = Vector2(TELA.x * 0.5, 250.0)
	jabulani.flip_h = true
	fundo.add_child(jabulani)
	jabulani.play("crouch")
	_trocar(fundo)
	await get_tree().create_timer(1.2, false).timeout
	if not is_instance_valid(jabulani):
		return
	jabulani.play("idle")
	await get_tree().create_timer(0.7, false).timeout
	if not is_instance_valid(jabulani):
		return
	jabulani.play("attack")


# ---------------------------------------------------------------- apoio

func _imagem(textura: Texture2D, cor: Color) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = textura
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = TELA / textura.get_size()
	sprite.modulate = cor
	return sprite


## Escurece, troca a imagem e clareia. Se outra troca for pedida no meio, a mais nova vence.
func _trocar(nova: Node2D) -> void:
	_pedido += 1
	var meu_pedido: int = _pedido
	_fade(1.0)
	await get_tree().create_timer(duracao_fade, false).timeout
	if meu_pedido != _pedido:
		nova.queue_free()
		return
	if is_instance_valid(_cena_atual):
		_cena_atual.queue_free()
	_cena_atual = nova
	add_child(nova)
	_fade(0.0)


func _fade(alfa: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_escuro, "color:a", alfa, duracao_fade)

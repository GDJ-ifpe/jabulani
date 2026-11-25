extends Node2D

## Palco da abertura ("O chamado das águas..."): mostra as imagens que acompanham a narração.
## Cada método público é uma ação chamada por uma fala do CutscenePlayer.
## Ilustrações próprias ainda não existem: usa os fundos do jogo.
## Todas as imagens são montadas e desenhadas uma vez durante a tela preta inicial; depois as
## falas só trocam qual está visível. Assim nenhuma textura é enviada à placa de vídeo no meio
## da narração, o que travava a cena no navegador em máquinas mais fracas.

const FUNDO_SERTAO: PackedScene = preload("res://fases/fase1_sertao/assets/backgrounds/sertao/fundo_sertao.tscn")
const FUNDO_LITORAL: Texture2D = preload("res://fases/fase3_litoral/assets/backgrounds/litoral_up.png")
const FUNDO_CAVERNA: Texture2D = preload("res://fases/fase1_sertao/assets/backgrounds/caverna/camada_5.png")
const FRENTE_CAVERNA: Texture2D = preload("res://fases/fase1_sertao/assets/backgrounds/caverna/camada_2.png")
const QUADROS_JABULANI: SpriteFrames = preload("res://shared/player/jabulani_frames.tres")

const TELA: Vector2 = Vector2(640.0, 360.0)

@export var duracao_fade: float = 0.6 # s
@export var cor_zona_da_mata: Color = Color(0.16, 0.3, 0.14)
@export var cor_poluicao: Color = Color(0.5, 0.42, 0.36)

var _quadros: Dictionary[StringName, Node2D] = {}
var _quadro_atual: Node2D = null
var _jabulani: AnimatedSprite2D
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
	_montar_quadros()
	_aquecer()


# ---------------------------------------------------------------- ações das falas

## "Antes tudo era verde...": as regiões ainda preservadas.
func mostrar_regioes_verdes() -> void:
	_trocar(&"verdes")


## "Até que um dia": a tela escurece.
func escurecer() -> void:
	_pedido += 1
	_fade(1.0)


## "...veio a seca": o sertão de terra rachada.
func mostrar_seca() -> void:
	_trocar(&"seca")


## "o lixo": a zona da mata cheia de resíduos.
func mostrar_lixo() -> void:
	_trocar(&"lixo")


## "a poluição": o litoral com manchas de óleo e peixes mortos.
func mostrar_poluicao() -> void:
	_trocar(&"poluicao")


## Fim da narração: Jabulani acorda na caverna e levanta o canudo.
func acordar_jabulani() -> void:
	_jabulani.play("crouch")
	var meu_pedido: int = await _trocar(&"caverna")
	await get_tree().create_timer(1.2, false).timeout
	if meu_pedido != _pedido:
		return
	_jabulani.play("idle")
	await get_tree().create_timer(0.7, false).timeout
	if meu_pedido != _pedido:
		return
	_jabulani.play("attack")


# ---------------------------------------------------------------- apoio

func _montar_quadros() -> void:
	_adicionar_quadro(&"verdes", _com(_imagem(FUNDO_LITORAL, Color.WHITE)))
	_adicionar_quadro(&"seca", FUNDO_SERTAO.instantiate())

	var cor := ColorRect.new()
	cor.color = cor_zona_da_mata
	cor.size = TELA
	cor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_adicionar_quadro(&"lixo", _com(cor))

	_adicionar_quadro(&"poluicao", _com(_imagem(FUNDO_LITORAL, cor_poluicao)))

	var caverna := _com(_imagem(FUNDO_CAVERNA, Color.WHITE))
	caverna.add_child(_imagem(FRENTE_CAVERNA, Color.WHITE))
	_jabulani = AnimatedSprite2D.new()
	_jabulani.sprite_frames = QUADROS_JABULANI
	_jabulani.scale = Vector2(0.5, 0.5)
	_jabulani.position = Vector2(TELA.x * 0.5, 250.0)
	_jabulani.flip_h = true
	caverna.add_child(_jabulani)
	_adicionar_quadro(&"caverna", caverna)


## Desenha todos os quadros por dois quadros de tela, escondidos sob o preto, para a placa de
## vídeo receber as texturas antes da narração; depois esconde todos.
func _aquecer() -> void:
	for animacao in [&"crouch", &"idle", &"attack"]:
		_jabulani.play(animacao)
		await get_tree().process_frame
	_jabulani.stop()
	await get_tree().process_frame
	for quadro in _quadros.values():
		if quadro != _quadro_atual:
			quadro.visible = false


func _adicionar_quadro(nome: StringName, quadro: Node2D) -> void:
	quadro.name = String(nome).capitalize()
	_quadros[nome] = quadro
	add_child(quadro)


func _com(filho: CanvasItem) -> Node2D:
	var raiz := Node2D.new()
	raiz.add_child(filho)
	return raiz


func _imagem(textura: Texture2D, cor: Color) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = textura
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = TELA / textura.get_size()
	sprite.modulate = cor
	return sprite


## Escurece, troca o quadro visível e clareia. Se outra troca for pedida no meio, a mais nova
## vence. Devolve o número do pedido, para quem continuar uma animação depois dele.
func _trocar(nome: StringName) -> int:
	_pedido += 1
	var meu_pedido: int = _pedido
	_fade(1.0)
	await get_tree().create_timer(duracao_fade, false).timeout
	if meu_pedido != _pedido:
		return meu_pedido
	if _quadro_atual != null:
		_quadro_atual.visible = false
	_quadro_atual = _quadros[nome]
	_quadro_atual.visible = true
	_fade(0.0)
	return meu_pedido


func _fade(alfa: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_escuro, "color:a", alfa, duracao_fade)

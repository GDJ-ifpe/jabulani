class_name ControlesToque
extends CanvasLayer

## Botões de toque para jogar pelo navegador do celular. São criados quando a tela é de
## toque ou no primeiro toque recebido (caso o navegador não informe), então no PC nada muda.
## Cada botão aperta a mesma ação do teclado (left, right, jump, attack, dash, power_up, ui_cancel):
## o player não precisa saber que eles existem.

const SETA_ESQUERDA: Texture2D = preload("res://shared/ui/ui_sprites/toque/seta_esquerda.png")
const SETA_ESQUERDA_PRESSIONADA: Texture2D = preload("res://shared/ui/ui_sprites/toque/seta_esquerda_pressionada.png")
const SETA_DIREITA: Texture2D = preload("res://shared/ui/ui_sprites/toque/seta_direita.png")
const SETA_DIREITA_PRESSIONADA: Texture2D = preload("res://shared/ui/ui_sprites/toque/seta_direita_pressionada.png")
const SETA_CIMA: Texture2D = preload("res://shared/ui/ui_sprites/toque/seta_cima.png")
const SETA_CIMA_PRESSIONADA: Texture2D = preload("res://shared/ui/ui_sprites/toque/seta_cima_pressionada.png")
const ATACAR: Texture2D = preload("res://shared/ui/ui_sprites/toque/atacar.png")
const ATACAR_PRESSIONADO: Texture2D = preload("res://shared/ui/ui_sprites/toque/atacar_pressionado.png")
const CASCO: Texture2D = preload("res://shared/ui/ui_sprites/Elements/Shell.png")

const TELA: Vector2 = Vector2(640.0, 360.0)

@export var opacidade: float = 0.65
@export var margem: float = 10.0 # px da borda da tela
@export var tamanho_seta: float = 60.0 # px
@export var tamanho_ataque: float = 68.0 # px
@export var tamanho_especial: float = 50.0 # px
@export var tamanho_dash: float = 50.0 # px
@export var tamanho_pausa: float = 26.0 # px
@export var forcar_exibicao: bool = false # mostra mesmo sem tela de toque (para testar no PC)


func _ready() -> void:
	layer = 50
	# A pausa precisa responder com o jogo parado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if forcar_exibicao or DisplayServer.is_touchscreen_available():
		_criar_botoes()


func _input(event: InputEvent) -> void:
	# Plano B: se o navegador não disse que a tela é de toque, cria os botões no primeiro toque.
	if get_child_count() == 0 and event is InputEventScreenTouch:
		_criar_botoes()


func _criar_botoes() -> void:
	if get_child_count() > 0:
		return
	var base_y: float = TELA.y - margem
	# Esquerda da tela: andar.
	_botao(&"left", SETA_ESQUERDA, SETA_ESQUERDA_PRESSIONADA, Vector2(margem, base_y - tamanho_seta), tamanho_seta)
	_botao(&"right", SETA_DIREITA, SETA_DIREITA_PRESSIONADA, Vector2(margem * 2.0 + tamanho_seta, base_y - tamanho_seta), tamanho_seta)
	# Direita da tela: ataque no canto, pulo acima dele, especial à esquerda dele.
	var x_ataque: float = TELA.x - margem - tamanho_ataque
	_botao(&"attack", ATACAR, ATACAR_PRESSIONADO, Vector2(x_ataque, base_y - tamanho_ataque), tamanho_ataque)
	var x_pulo: float = x_ataque + (tamanho_ataque - tamanho_seta) * 0.5
	_botao(&"jump", SETA_CIMA, SETA_CIMA_PRESSIONADA, Vector2(x_pulo, base_y - tamanho_ataque - margem - tamanho_seta), tamanho_seta)
	var x_especial: float = x_ataque - margem * 1.5 - tamanho_especial
	_botao(&"power_up", CASCO, null, Vector2(x_especial, base_y - tamanho_especial), tamanho_especial)
	# Dash acima do especial, na altura do pulo.
	var y_dash: float = base_y - tamanho_ataque - margem - tamanho_seta + (tamanho_seta - tamanho_dash) * 0.5
	_botao(&"dash", _textura_dash(), null, Vector2(x_especial, y_dash), tamanho_dash)
	var pausa: ImageTexture = _textura_pausa()
	_botao(&"ui_cancel", pausa, null, Vector2(TELA.x - margem - tamanho_pausa, margem), tamanho_pausa)


func _botao(acao: StringName, normal: Texture2D, pressionado: Texture2D, posicao: Vector2, tamanho: float) -> TouchScreenButton:
	var botao := TouchScreenButton.new()
	botao.name = "botao_" + String(acao)
	botao.action = acao
	botao.texture_normal = normal
	botao.texture_pressed = pressionado
	botao.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	var lado: float = maxf(normal.get_width(), normal.get_height())
	botao.scale = Vector2.ONE * (tamanho / lado)
	botao.position = posicao
	botao.modulate.a = opacidade
	add_child(botao)
	return botao


## Ícone de pausa (duas barras sobre um quadrado escuro), gerado para não depender de arte.
func _textura_pausa() -> ImageTexture:
	var imagem := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	imagem.fill(Color(0.0, 0.0, 0.0, 0.55))
	imagem.fill_rect(Rect2i(9, 7, 5, 18), Color.WHITE)
	imagem.fill_rect(Rect2i(18, 7, 5, 18), Color.WHITE)
	return ImageTexture.create_from_image(imagem)


## Ícone de dash (duas setas ">>" sobre um quadrado escuro), gerado para não depender de arte.
func _textura_dash() -> ImageTexture:
	var imagem := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	imagem.fill(Color(0.0, 0.0, 0.0, 0.55))
	for inicio in [6, 15]:
		for y in range(7, 25):
			var x: int = inicio + 8 - absi(y - 16)
			imagem.fill_rect(Rect2i(x, y, 4, 1), Color.WHITE)
	return ImageTexture.create_from_image(imagem)

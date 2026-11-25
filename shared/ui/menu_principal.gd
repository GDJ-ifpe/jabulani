extends Control

## Menu principal: Jogar, Opções, Créditos, Sair.

const CENA_OPCOES: PackedScene = preload("res://shared/ui/opcoes.tscn")
const CENA_CREDITOS: PackedScene = preload("res://shared/ui/creditos.tscn")
const LOGO_GRUPO: Texture2D = preload("res://icones/logo_gdj.png")

@export var tamanho_logo: float = 32.0 # altura do logo do grupo no canto, em px
@export var margem_logo: float = 6.0

@onready var painel: PainelMenu = $Painel

var _sobreposta: Control = null # Opções ou Créditos em exibição


func _enter_tree() -> void:
	# No navegador não existe "sair": encerrar o motor trava a página. Lá o botão some
	# (antes de o painel montar os botões); quem joga fecha a aba.
	if OS.has_feature("web"):
		var painel_menu: PainelMenu = get_node("Painel")
		painel_menu.opcoes = painel_menu.opcoes.slice(0, painel_menu.opcoes.size() - 1)


func _ready() -> void:
	painel.opcao_escolhida.connect(_on_opcao)
	_adicionar_logo_grupo()


## Logo do GDJ-IFPE, pequeno no canto inferior direito.
func _adicionar_logo_grupo() -> void:
	var logo := TextureRect.new()
	logo.texture = LOGO_GRUPO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var largura: float = tamanho_logo * LOGO_GRUPO.get_width() / LOGO_GRUPO.get_height()
	logo.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	logo.offset_left = -largura - margem_logo
	logo.offset_top = -tamanho_logo - margem_logo
	logo.offset_right = -margem_logo
	logo.offset_bottom = -margem_logo
	add_child(logo)


func _on_opcao(indice: int) -> void:
	match indice:
		0:
			GameManager.novo_jogo()
		1:
			_abrir(CENA_OPCOES)
		2:
			_abrir(CENA_CREDITOS)
		3:
			GameManager.sair_do_jogo()


func _abrir(cena: PackedScene) -> void:
	if _sobreposta != null:
		return
	_sobreposta = cena.instantiate()
	add_child(_sobreposta)
	_sobreposta.tree_exited.connect(_on_sobreposta_fechada)
	painel.visible = false


func _on_sobreposta_fechada() -> void:
	_sobreposta = null
	painel.visible = true
	painel.focar()

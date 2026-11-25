class_name PainelMenu
extends Control

## Painel de menu genérico: fundo escurecido, título, texto opcional e uma coluna de botões.
## Usado pelo menu principal, pausa, game over e tela de conclusão.

signal opcao_escolhida(indice: int)

@export var titulo: String = ""
@export_multiline var texto: String = ""
@export var opcoes: PackedStringArray = PackedStringArray()
@export var cor_fundo: Color = Color(0.0, 0.0, 0.0, 0.6)
@export var tamanho_titulo: int = 28

var _coluna: VBoxContainer
var _rotulo_texto: Label
var _botoes: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fundo := ColorRect.new()
	fundo.color = cor_fundo
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	_coluna = VBoxContainer.new()
	_coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	_coluna.add_theme_constant_override("separation", 8)
	centro.add_child(_coluna)

	var rotulo_titulo := Label.new()
	rotulo_titulo.text = titulo
	rotulo_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_titulo.add_theme_font_size_override("font_size", tamanho_titulo)
	rotulo_titulo.add_theme_color_override("font_outline_color", Color.BLACK)
	rotulo_titulo.add_theme_constant_override("outline_size", 6)
	_coluna.add_child(rotulo_titulo)

	_rotulo_texto = Label.new()
	_rotulo_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coluna.add_child(_rotulo_texto)
	definir_texto(texto)

	for i in opcoes.size():
		var botao := Button.new()
		botao.text = opcoes[i]
		botao.custom_minimum_size = Vector2(180.0, 0.0)
		botao.pressed.connect(_on_botao.bind(i))
		_coluna.add_child(botao)
		_botoes.append(botao)

	focar()


func definir_texto(novo_texto: String) -> void:
	texto = novo_texto
	if _rotulo_texto != null:
		_rotulo_texto.text = novo_texto
		_rotulo_texto.visible = novo_texto != ""


func focar() -> void:
	if not _botoes.is_empty():
		_botoes[0].grab_focus.call_deferred()


func _on_botao(indice: int) -> void:
	AudioManager.tocar_sfx(&"TODO_AUDIO_ui_confirmar", -8.0)
	opcao_escolhida.emit(indice)

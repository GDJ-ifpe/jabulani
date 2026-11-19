class_name DialogueBox
extends Control

## Caixa de diálogo: nome de quem fala, retrato opcional e o texto aparecendo letra a letra.

signal texto_completo

@export var caracteres_por_segundo: float = 40.0
@export var altura: float = 96.0 # px
@export var margem: float = 12.0 # px
@export var cor_fundo: Color = Color(0.05, 0.04, 0.06, 0.85)
@export var cor_falante: Color = Color(1.0, 0.85, 0.45)
@export var tamanho_fonte: int = 12

var _painel: Panel
var _rotulo_falante: Label
var _rotulo_texto: Label
var _retrato: TextureRect
var _indicador: Label
var _visiveis: float = 0.0
var _total: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	_painel = Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor_fundo
	estilo.set_corner_radius_all(4)
	estilo.set_border_width_all(1)
	estilo.border_color = Color(1.0, 1.0, 1.0, 0.35)
	_painel.add_theme_stylebox_override("panel", estilo)
	_painel.anchor_left = 0.0
	_painel.anchor_right = 1.0
	_painel.anchor_top = 1.0
	_painel.anchor_bottom = 1.0
	_painel.offset_left = margem
	_painel.offset_right = -margem
	_painel.offset_top = -altura - margem
	_painel.offset_bottom = -margem
	add_child(_painel)

	var linha := HBoxContainer.new()
	linha.set_anchors_preset(Control.PRESET_FULL_RECT)
	linha.offset_left = 10.0
	linha.offset_top = 6.0
	linha.offset_right = -10.0
	linha.offset_bottom = -6.0
	linha.add_theme_constant_override("separation", 10)
	_painel.add_child(linha)

	_retrato = TextureRect.new()
	_retrato.custom_minimum_size = Vector2(64.0, 64.0)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.visible = false
	linha.add_child(_retrato)

	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.add_theme_constant_override("separation", 2)
	linha.add_child(coluna)

	_rotulo_falante = Label.new()
	_rotulo_falante.add_theme_font_size_override("font_size", tamanho_fonte + 1)
	_rotulo_falante.add_theme_color_override("font_color", cor_falante)
	coluna.add_child(_rotulo_falante)

	_rotulo_texto = Label.new()
	_rotulo_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rotulo_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rotulo_texto.add_theme_font_size_override("font_size", tamanho_fonte)
	_rotulo_texto.add_theme_constant_override("line_spacing", 0)
	coluna.add_child(_rotulo_texto)

	_indicador = Label.new()
	# Diz como avançar: no celular é tocar na tela; no PC, tecla U, Enter ou clique.
	_indicador.text = "toque para continuar >" if DisplayServer.is_touchscreen_available() else "U ou clique para continuar >"
	_indicador.add_theme_font_size_override("font_size", 8)
	_indicador.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.75))
	_indicador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_indicador.anchor_left = 1.0
	_indicador.anchor_right = 1.0
	_indicador.anchor_top = 1.0
	_indicador.anchor_bottom = 1.0
	_indicador.offset_left = -200.0
	_indicador.offset_right = -6.0
	_indicador.offset_top = -14.0
	_painel.add_child(_indicador)

	esconder()


func mostrar(fala: DialogueLine) -> void:
	_painel.visible = true
	_rotulo_falante.text = fala.falante
	_rotulo_falante.visible = fala.falante != ""
	_retrato.texture = fala.retrato
	_retrato.visible = fala.retrato != null
	_rotulo_texto.text = fala.texto
	_rotulo_texto.visible_characters = 0
	_total = fala.texto.length()
	_visiveis = 0.0
	_indicador.visible = false
	set_process(true)


func esconder() -> void:
	_painel.visible = false
	set_process(false)


func esta_completo() -> bool:
	return _visiveis >= float(_total)


func completar() -> void:
	_visiveis = float(_total)
	_rotulo_texto.visible_characters = -1
	_indicador.visible = true
	set_process(false)
	texto_completo.emit()


func _process(delta: float) -> void:
	_visiveis += caracteres_por_segundo * delta
	if _visiveis >= float(_total):
		completar()
	else:
		_rotulo_texto.visible_characters = int(_visiveis)

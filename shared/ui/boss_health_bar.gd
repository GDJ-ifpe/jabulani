extends Control

## Barra de vida do chefe, dentro da HUD. Aparece quando um chefe se apresenta
## (Events.boss_spawned), acompanha a vida dele e some quando ele é derrotado.

const TEXTURA_FUNDO: Texture2D = preload("res://shared/ui/ui_sprites/Hud generica/Background.png")
const TEXTURA_VIDA: Texture2D = preload("res://shared/ui/ui_sprites/Hud generica/Fill_00.png")

@export var largura: float = 220.0 # largura da barra na tela (px)
@export var margem: Vector2 = Vector2(8.0, 6.0) # distância do canto superior direito da tela (px)
@export var deslocamento_do_preenchimento: Vector2 = Vector2(32.0, 40.0) # posição do preenchimento dentro da moldura (px da textura)
@export var duracao_animacao: float = 0.2 # s para a barra acompanhar a vida

var _barra: TextureProgressBar
var _nome: Label
var _chefe: Node = null
var _tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	var escala: float = largura / float(TEXTURA_FUNDO.get_width())
	var altura: float = TEXTURA_FUNDO.get_height() * escala
	var tela: Vector2 = get_viewport_rect().size

	_barra = TextureProgressBar.new()
	_barra.texture_under = TEXTURA_FUNDO
	_barra.texture_progress = TEXTURA_VIDA
	_barra.texture_progress_offset = deslocamento_do_preenchimento
	_barra.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	_barra.min_value = 0.0
	_barra.max_value = 1.0
	_barra.step = 0.0
	_barra.value = 1.0
	_barra.scale = Vector2(escala, escala)
	_barra.position = Vector2(tela.x - largura - margem.x, margem.y)
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_barra)

	_nome = Label.new()
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_nome.add_theme_font_size_override("font_size", 11)
	_nome.add_theme_color_override("font_outline_color", Color.BLACK)
	_nome.add_theme_constant_override("outline_size", 4)
	_nome.position = Vector2(0.0, _barra.position.y + altura)
	_nome.size = Vector2(tela.x - margem.x, 16.0)
	add_child(_nome)

	Events.boss_spawned.connect(_on_chefe_apresentado)
	Events.boss_defeated.connect(_on_chefe_derrotado)


func _on_chefe_apresentado(chefe: Node) -> void:
	_chefe = chefe
	_nome.text = String(chefe.get("nome_exibido")) if "nome_exibido" in chefe else ""
	if chefe.has_signal("hp_changed"):
		chefe.connect("hp_changed", _on_vida_mudou)
	if "hp" in chefe and "max_hp" in chefe:
		_barra.value = _fracao(chefe.get("hp"), chefe.get("max_hp"))
	visible = true


func _on_vida_mudou(hp_atual: int, hp_maximo: int) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_barra, "value", _fracao(hp_atual, hp_maximo), duracao_animacao)


func _on_chefe_derrotado(_id: StringName) -> void:
	_chefe = null
	visible = false


func _fracao(hp_atual: int, hp_maximo: int) -> float:
	return clampf(float(hp_atual) / float(maxi(hp_maximo, 1)), 0.0, 1.0)

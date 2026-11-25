extends Control

## Créditos: equipe e assets de terceiros (os que exigem crédito e os de domínio público,
## como agradecimento). Esc ou "Voltar" fecha.

const TEXTO: String = """Jabulani, o Casco no Mundo
Equipe GDJ - IFPE

Arte e som de terceiros

Morcego: "Bat (32x32)" por MoikMellah - OpenGameArt.org
Rolinha: "Pigeons Pixel Asset Pack" por Pop Shop Packs - itch.io
Lixo: Recycle items art by Clint Bellanger - OpenGameArt.org (CC-BY 3.0)

Agradecimentos (domínio público, CC0)
Formigas: ARoachIFoundOnMyPillow
Cenário da caverna: Baldur / Foozle
Música da caverna: cynicmusic
Ambiente da caverna: JaggedStone"""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fundo := ColorRect.new()
	fundo.color = Color(0.0, 0.0, 0.0, 0.85)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 10)
	centro.add_child(coluna)

	var titulo := Label.new()
	titulo.text = "Créditos"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 24)
	coluna.add_child(titulo)

	var texto := Label.new()
	texto.text = TEXTO
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 11)
	coluna.add_child(texto)

	var voltar := Button.new()
	voltar.text = "Voltar"
	voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	voltar.custom_minimum_size = Vector2(120.0, 0.0)
	voltar.pressed.connect(queue_free)
	coluna.add_child(voltar)
	voltar.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()

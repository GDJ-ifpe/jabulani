extends Control

## Opções: volumes de Música e SFX (o ambiente segue o SFX). Esc ou "Voltar" fecha.

const BARRAS: Array[Array] = [["Música", &"Musica"], ["SFX", &"SFX"]]

var _primeiro: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fundo := ColorRect.new()
	fundo.color = Color(0.0, 0.0, 0.0, 0.75)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	centro.add_child(coluna)

	var titulo := Label.new()
	titulo.text = "Opções"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	coluna.add_child(titulo)

	for barra in BARRAS:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 12)
		coluna.add_child(linha)

		var rotulo := Label.new()
		rotulo.text = barra[0]
		rotulo.custom_minimum_size = Vector2(70.0, 0.0)
		linha.add_child(rotulo)

		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(180.0, 0.0)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value = AudioManager.obter_volume(barra[1])
		slider.value_changed.connect(_on_volume.bind(barra[1]))
		linha.add_child(slider)
		if _primeiro == null:
			_primeiro = slider

	var voltar := Button.new()
	voltar.text = "Voltar"
	voltar.pressed.connect(queue_free)
	coluna.add_child(voltar)

	_primeiro.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()


func _on_volume(valor: float, bus: StringName) -> void:
	AudioManager.definir_volume(bus, valor)
	if bus == &"SFX":
		AudioManager.tocar_sfx(&"TODO_AUDIO_ui_confirmar", -8.0)

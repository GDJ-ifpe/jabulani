extends Control

## HUD do jogador. Fica dentro de um CanvasLayer (não sofre zoom nem movimento da câmera)
## e reflete o autoload PlayerData: corações, face, cascos de poder e pontuação.

signal vida_alterada(hp_atual: int)

@onready var contador_pontos: Label = $MarginContainer/pontos_coluna/contador_pontos
@onready var vidas_container: HBoxContainer = $MarginContainer/VBoxContainer/status_coluna/HBoxContainer
@onready var powerup_container: HBoxContainer = $MarginContainer/VBoxContainer/status_coluna2/HBoxContainer

# Faces aninhadas: vidas_icon (100%) > vidas_icon2 (80%) > ... > vidas_icon6 (0%).
@onready var faces: Array[TextureRect] = [
	$MarginContainer/VBoxContainer/status_coluna/vidas_icon,
	$MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2,
	$MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2/vidas_icon3,
	$MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2/vidas_icon3/vidas_icon4,
	$MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2/vidas_icon3/vidas_icon4/vidas_icon5,
	$MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2/vidas_icon3/vidas_icon4/vidas_icon5/vidas_icon6,
]

var vidas_textures: Array[TextureRect] = []
var powerup_textures: Array[TextureRect] = []


func _ready() -> void:
	for child in vidas_container.get_children():
		if child is TextureRect:
			vidas_textures.append(child)
	for child in powerup_container.get_children():
		if child is TextureRect:
			powerup_textures.append(child)

	PlayerData.hp_changed.connect(atualizar_vidas)
	PlayerData.power_changed.connect(atualizar_powerups)
	PlayerData.pontos_changed.connect(atualizar_pontos)

	atualizar_vidas(PlayerData.hp)
	atualizar_powerups(PlayerData.power_points)
	atualizar_pontos(PlayerData.pontos)

	# Botões de toque (só aparecem no celular).
	add_child(ControlesToque.new())


func atualizar_pontos(pontos: int) -> void:
	contador_pontos.text = "%05d" % pontos


func atualizar_vidas(hp_atual: int) -> void:
	# Os ícones somem sem sair do layout, para a fileira não se deslocar ao perder vida.
	for i in vidas_textures.size():
		vidas_textures[i].modulate.a = 1.0 if i < hp_atual else 0.0
	_atualizar_face(hp_atual)
	vida_alterada.emit(hp_atual)


func _atualizar_face(hp_atual: int) -> void:
	if PlayerData.max_hp <= 0:
		return
	var perdido: float = 1.0 - float(hp_atual) / float(PlayerData.max_hp)
	# Vida cheia = face 0; a cada 20% perdidos aparece a face seguinte.
	# Como são aninhadas, todas as anteriores precisam ficar visíveis.
	var max_indice: int = clampi(ceili(perdido * 5.0 - 0.001), 0, faces.size() - 1)
	for i in faces.size():
		faces[i].visible = i <= max_indice


func atualizar_powerups(power_points: int) -> void:
	for i in powerup_textures.size():
		powerup_textures[i].modulate.a = 1.0 if i < power_points else 0.0

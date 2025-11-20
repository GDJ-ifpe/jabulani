extends Control
@onready var contador_pontos: Label = $MarginContainer/pontos_coluna/contador_pontos as Label
@onready var vidas: Label = $MarginContainer/VBoxContainer/status_coluna/vidas_icon as Label
@onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/status_coluna/HBoxContainer/TextureRect
@onready var texture_rect_2: TextureRect = $MarginContainer/VBoxContainer/status_coluna/HBoxContainer/TextureRect2
@onready var texture_rect_4: TextureRect = $MarginContainer/VBoxContainer/status_coluna/HBoxContainer/TextureRect4
@onready var texture_rect_5: TextureRect = $MarginContainer/VBoxContainer/status_coluna/HBoxContainer/TextureRect5
@onready var texture_rect_6: TextureRect = $MarginContainer/VBoxContainer/status_coluna/HBoxContainer/TextureRect6
@onready var texture_rect_3: TextureRect = $MarginContainer/VBoxContainer/status_coluna/HBoxContainer/TextureRect3

@onready var powerup: TextureRect = $MarginContainer/VBoxContainer/status_coluna2/HBoxContainer/powerup
@onready var powerup_2: TextureRect = $MarginContainer/VBoxContainer/status_coluna2/HBoxContainer/powerup2
@onready var powerup_3: TextureRect = $MarginContainer/VBoxContainer/status_coluna2/HBoxContainer/powerup3
@onready var powerup_4: TextureRect = $MarginContainer/VBoxContainer/status_coluna2/HBoxContainer/powerup4
@onready var powerup_5: TextureRect = $MarginContainer/VBoxContainer/status_coluna2/HBoxContainer/powerup5
@onready var powerup_6: TextureRect = $MarginContainer/VBoxContainer/status_coluna2/HBoxContainer/powerup6


func _ready():
	contador_pontos.text = str("%05d" % PlayerManager.pontos)
func _process(_delta: float) -> void:
	contador_pontos.text = str("%05d" % PlayerManager.pontos)
	if PlayerManager.player_life == 6:
		pass
	if PlayerManager.player_life == 5:
		texture_rect_6.visible = false
	if PlayerManager.player_life == 4:
		texture_rect_5.visible = false
	if PlayerManager.player_life == 3:
		texture_rect_4.visible = false
	if PlayerManager.player_life == 2:
		texture_rect_3.visible = false
	if PlayerManager.player_life == 1:
		texture_rect_2.visible = false
	if PlayerManager.player_power == 6:
		powerup_6.visible = false
	if PlayerManager.player_power == 5:
		powerup.visible = false
	if PlayerManager.player_power == 4:
		powerup_2.visible = false
	if PlayerManager.player_power == 3:
		powerup_3.visible = false
	if PlayerManager.player_power == 2:
		powerup_4.visible = false
	if PlayerManager.player_power == 1:
		powerup_5.visible = false

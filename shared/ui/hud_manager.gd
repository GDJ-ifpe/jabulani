extends Control

## HUD Manager - Gerencia a interface do jogador
## A HUD está dentro de um CanvasLayer, então não é afetada por zoom da câmera
## Suporta qualquer quantidade de vidas/powerups automaticamente

signal vida_alterada(hp_atual: int)

@onready var contador_pontos: Label = $MarginContainer/pontos_coluna/contador_pontos as Label

# Container de vidas (corações)
@onready var vidas_container: HBoxContainer = $MarginContainer/VBoxContainer/status_coluna/HBoxContainer
# Container de powerups (cascos)
@onready var powerup_container: HBoxContainer = $MarginContainer/VBoxContainer/status_coluna2/HBoxContainer

# Ícones de face (vida em porcentagem)
# Estrutura: vidas_icon (100%) > vidas_icon2 (80%) > vidas_icon3 (60%) > vidas_icon4 (40%) > vidas_icon5 (20%) > vidas_icon6 (0%)
@onready var face_100: TextureRect = $MarginContainer/VBoxContainer/status_coluna/vidas_icon
@onready var face_80: TextureRect = $MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2
@onready var face_60: TextureRect = $MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2/vidas_icon3
@onready var face_40: TextureRect = $MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2/vidas_icon3/vidas_icon4
@onready var face_20: TextureRect = $MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2/vidas_icon3/vidas_icon4/vidas_icon5
@onready var face_0: TextureRect = $MarginContainer/VBoxContainer/status_coluna/vidas_icon/vidas_icon2/vidas_icon3/vidas_icon4/vidas_icon5/vidas_icon6

# Array de faces em ordem (do mais cheio ao mais vazio)
var faces: Array[TextureRect] = []

# Array dinâmico de TextureRects de vidas (corações)
var vidas_textures: Array[TextureRect] = []
# Array dinâmico de TextureRects de powerups
var powerup_textures: Array[TextureRect] = []

var max_hp: int = 5  # Será atualizado quando conectar ao player

func _ready():
	# Monta array de faces na ordem correta
	faces = [face_100, face_80, face_60, face_40, face_20, face_0]
	
	# Pega todos os TextureRects filhos dos containers
	_coletar_textures()
	
	# Atualiza estado inicial
	contador_pontos.text = str("%05d" % PlayerData.pontos)
	atualizar_vidas(PlayerData.hp)
	atualizar_powerups(PlayerData.power_points)
	
	# Conecta ao sinal do player para atualizar quando tomar dano
	_conectar_ao_player()

func _coletar_textures():
	"""Coleta todos os TextureRect dos containers em arrays"""
	for child in vidas_container.get_children():
		if child is TextureRect:
			vidas_textures.append(child)
	
	for child in powerup_container.get_children():
		if child is TextureRect:
			powerup_textures.append(child)
	
	print("[HUD] Vidas encontradas: ", vidas_textures.size())
	print("[HUD] Powerups encontrados: ", powerup_textures.size())

func _conectar_ao_player():
	"""Conecta ao sinal player_hit do player"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("player_hit"):
			player.player_hit.connect(_on_player_hit)
			print("[HUD] Conectado ao sinal player_hit")
		else:
			print("[HUD] Player não tem sinal player_hit")
		
		# Pega o max_hp do player
		if "max_hp" in player:
			max_hp = player.max_hp
			print("[HUD] max_hp do player: ", max_hp)
	else:
		print("[HUD] Player não encontrado para conectar")

func _on_player_hit(hp_restante: int):
	"""Callback quando o player toma dano"""
	atualizar_vidas(hp_restante)

func _process(_delta: float) -> void:
	contador_pontos.text = str("%05d" % PlayerData.pontos)

func atualizar_vidas(hp_atual: int) -> void:
	"""Atualiza a exibição de vidas baseado no HP atual
	- Corações: mostra/oculta baseado no HP
	- Face: mostra o ícone correspondente à porcentagem de vida"""
	
	# 1. Atualiza corações
	for i in range(vidas_textures.size()):
		vidas_textures[i].visible = i < hp_atual
	
	# 2. Atualiza face baseada na porcentagem de vida
	_atualizar_face(hp_atual)
	
	emit_signal("vida_alterada", hp_atual)

func _atualizar_face(hp_atual: int) -> void:
	"""Atualiza os ícones de face conforme o dano
	As faces são aninhadas (cada uma filha da anterior).
	Para mostrar uma face de dano, TODAS as anteriores precisam estar visíveis.
	
	- HP=5 (100%) → mostra só face_100
	- HP=4 (80%)  → mostra face_100 + face_80
	- HP=3 (60%)  → mostra face_100 + face_80 + face_60
	- HP=2 (40%)  → mostra até face_40
	- HP=1 (20%)  → mostra até face_20
	- HP=0 (0%)   → mostra todas (face_0)
	"""
	if max_hp <= 0:
		return
	
	# Calcula porcentagem (0.0 a 1.0)
	var porcentagem = float(hp_atual) / float(max_hp)
	
	# Determina quantas faces mostrar (índice máximo visível)
	# 100% = 0, 80% = 1, 60% = 2, 40% = 3, 20% = 4, 0% = 5
	var max_indice: int
	if porcentagem >= 1.0:
		max_indice = 0
	elif porcentagem >= 0.8:
		max_indice = 1
	elif porcentagem >= 0.6:
		max_indice = 2
	elif porcentagem >= 0.4:
		max_indice = 3
	elif porcentagem >= 0.2:
		max_indice = 4
	else:
		max_indice = 5
	
	# Mostra faces do índice 0 até max_indice (inclusive)
	# Como são aninhadas, todas precisam estar visíveis
	for i in range(faces.size()):
		faces[i].visible = i <= max_indice

func atualizar_powerups(power_points: int) -> void:
	"""Atualiza a exibição de powerups
	Suporta qualquer quantidade de powerups dinamicamente"""
	
	for i in range(powerup_textures.size()):
		powerup_textures[i].visible = i < power_points
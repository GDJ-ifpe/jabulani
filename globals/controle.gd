extends Node

## Suporte a controle (gamepad). Acrescenta os botões do controle às mesmas ações do teclado
## e reconhece controles genéricos de PS4 que o Godot não conhece de fábrica.
##
## Layout (nomes do PS4; entre parênteses, o nome padrão do Godot):
##   Analógico esquerdo / direcional: andar e agachar
##   X (A): pular             Quadrado (X): golpe
##   Bola (B): dash           R1 / R2: dash
##   Triângulo (Y): Jabussíntese   L1: Jabussíntese
##   Options (Start): pausa   Nos menus: X confirma, Bola volta

signal controle_conectado(dispositivo: int, nome: String)
signal controle_desconectado(dispositivo: int)

## Mapeamento SDL do DualShock 4 via DirectInput (Windows). Controles genéricos de PS4 que chegam
## sem mapeamento conhecido costumam usar esta mesma ordem de botões e eixos.
const MAPEAMENTO_PS4_WINDOWS: String = "a:b1,b:b2,x:b0,y:b3,back:b8,guide:b12,start:b9,leftstick:b10,rightstick:b11,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,rightx:a2,righty:a5,lefttrigger:a3,righttrigger:a4,touchpad:b13,platform:Windows,"
## O mesmo controle no Linux (driver hid-sony / joydev).
const MAPEAMENTO_PS4_LINUX: String = "a:b0,b:b1,x:b3,y:b2,back:b8,guide:b10,start:b9,leftstick:b11,rightstick:b12,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,platform:Linux,"

@export var zona_morta_andar: float = 0.25 # inclinação mínima do analógico para andar
@export var zona_morta_agachar: float = 0.5 # analógico para baixo: mais firme, para não agachar sem querer ao andar
@export var mapear_desconhecidos: bool = true # aplica o mapeamento de PS4 a qualquer controle que o Godot não reconheça

var _ja_mapeados: Dictionary = {} # guid -> true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_registrar_acoes()
	Input.joy_connection_changed.connect(_on_conexao)
	for dispositivo in Input.get_connected_joypads():
		_on_conexao(dispositivo, true)


func tem_controle() -> bool:
	return not Input.get_connected_joypads().is_empty()


# ---------------------------------------------------------------- ações

func _registrar_acoes() -> void:
	_botoes(&"jump", [JOY_BUTTON_A])
	_botoes(&"attack", [JOY_BUTTON_X])
	_botoes(&"dash", [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER])
	_eixo(&"dash", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_botoes(&"power_up", [JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER])
	_botoes(&"pausar", [JOY_BUTTON_START])

	_botoes(&"left", [JOY_BUTTON_DPAD_LEFT])
	_eixo(&"left", JOY_AXIS_LEFT_X, -1.0)
	_botoes(&"right", [JOY_BUTTON_DPAD_RIGHT])
	_eixo(&"right", JOY_AXIS_LEFT_X, 1.0)
	_botoes(&"crouch", [JOY_BUTTON_DPAD_DOWN])
	_eixo(&"crouch", JOY_AXIS_LEFT_Y, 1.0)

	InputMap.action_set_deadzone(&"left", zona_morta_andar)
	InputMap.action_set_deadzone(&"right", zona_morta_andar)
	InputMap.action_set_deadzone(&"crouch", zona_morta_agachar)

	# Menus: X confirma e Bola volta já vêm no Godot (ui_accept / ui_cancel); garante os dois
	# caso o projeto troque os padrões.
	_botoes(&"ui_accept", [JOY_BUTTON_A])
	_botoes(&"ui_cancel", [JOY_BUTTON_B])
	_botoes(&"ui_up", [JOY_BUTTON_DPAD_UP])
	_eixo(&"ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_botoes(&"ui_down", [JOY_BUTTON_DPAD_DOWN])
	_eixo(&"ui_down", JOY_AXIS_LEFT_Y, 1.0)
	_botoes(&"ui_left", [JOY_BUTTON_DPAD_LEFT])
	_eixo(&"ui_left", JOY_AXIS_LEFT_X, -1.0)
	_botoes(&"ui_right", [JOY_BUTTON_DPAD_RIGHT])
	_eixo(&"ui_right", JOY_AXIS_LEFT_X, 1.0)


func _botoes(acao: StringName, botoes: Array) -> void:
	_garantir_acao(acao)
	for botao in botoes:
		var evento := InputEventJoypadButton.new()
		evento.device = -1 # qualquer controle
		evento.button_index = botao
		_adicionar(acao, evento)


func _eixo(acao: StringName, eixo: JoyAxis, sentido: float) -> void:
	_garantir_acao(acao)
	var evento := InputEventJoypadMotion.new()
	evento.device = -1
	evento.axis = eixo
	evento.axis_value = sentido
	_adicionar(acao, evento)


func _garantir_acao(acao: StringName) -> void:
	if not InputMap.has_action(acao):
		InputMap.add_action(acao)


func _adicionar(acao: StringName, evento: InputEvent) -> void:
	if not InputMap.action_has_event(acao, evento):
		InputMap.action_add_event(acao, evento)


# ---------------------------------------------------------------- detecção

func _on_conexao(dispositivo: int, conectado: bool) -> void:
	if not conectado:
		print("Controle desconectado (dispositivo %d)" % dispositivo)
		controle_desconectado.emit(dispositivo)
		return
	var nome: String = Input.get_joy_name(dispositivo)
	var guid: String = Input.get_joy_guid(dispositivo)
	var conhecido: bool = Input.is_joy_known(dispositivo)
	print("Controle conectado: \"%s\" (dispositivo %d, guid %s, %s)" % [
		nome, dispositivo, guid, "reconhecido" if conhecido else "sem mapeamento"])
	if not conhecido and _deve_mapear(nome):
		_mapear_como_ps4(dispositivo, nome, guid)
	controle_conectado.emit(dispositivo, nome)


func _deve_mapear(nome: String) -> bool:
	if mapear_desconhecidos:
		return true
	var n: String = nome.to_lower()
	for pista in ["ps4", "ps3/ps4", "dualshock", "playstation", "sony", "wireless controller"]:
		if n.contains(pista):
			return true
	return false


func _mapear_como_ps4(dispositivo: int, nome: String, guid: String) -> void:
	if guid == "" or _ja_mapeados.has(guid):
		return
	var base: String
	match OS.get_name():
		"Windows":
			base = MAPEAMENTO_PS4_WINDOWS
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			base = MAPEAMENTO_PS4_LINUX
		_:
			return # Web, Android e macOS já entregam o controle no layout padrão
	var nome_limpo: String = nome.replace(",", " ") if nome != "" else "Controle generico PS4"
	Input.add_joy_mapping("%s,%s,%s" % [guid, nome_limpo, base], true)
	_ja_mapeados[guid] = true
	print("Mapeamento de PS4 aplicado ao controle \"%s\" (dispositivo %d)" % [nome, dispositivo])

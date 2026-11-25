class_name CutscenePlayer
extends Node

## Toca uma cena de história: uma lista de falas (DialogueLine), cada uma podendo disparar
## uma ação do palco. Atacar, confirmar, clicar ou tocar na tela completa o texto e avança; a pausa (Esc) oferece
## "Pular cena". Ao terminar avisa por Events.cutscene_finished e entrega o fluxo ao GameManager.

signal fala_iniciada(indice: int)
signal terminou

@export var id: StringName = &"cutscene"
@export var falas: Array[DialogueLine] = []
## Cena seguinte. Vazio = fim da fase (o GameManager mostra a tela de conclusão).
@export_file("*.tscn") var proxima_cena: String = ""
@export var musica: AudioStream
@export var ambiente: AudioStream
## Nó que executa as ações das falas (métodos com o nome de `acao`). Padrão: o pai.
@export var palco: Node
@export var atraso_inicial: float = 1.0 # s antes da primeira fala
@export var iniciar_sozinho: bool = true

var indice: int = -1
var terminado: bool = false

var _caixa: DialogueBox
var _espera: float = 0.0
var _aguardando_tempo: bool = false
var _rodando: bool = false


func _ready() -> void:
	add_to_group("cutscene")
	if palco == null:
		palco = get_parent()
	var camada := CanvasLayer.new()
	camada.layer = 20
	add_child(camada)
	_caixa = DialogueBox.new()
	camada.add_child(_caixa)
	if musica != null:
		AudioManager.tocar_musica(musica)
	else:
		AudioManager.parar_musica()
	if ambiente != null:
		AudioManager.tocar_ambiente(ambiente)
	else:
		AudioManager.parar_ambiente()
	GameManager.precarregar(proxima_cena)
	if iniciar_sozinho:
		iniciar()


func iniciar() -> void:
	if _rodando or terminado:
		return
	_rodando = true
	_aguardando_tempo = true
	_espera = atraso_inicial


func _process(delta: float) -> void:
	if not _rodando or terminado or not _aguardando_tempo:
		return
	_espera -= delta
	if _espera <= 0.0:
		_aguardando_tempo = false
		_avancar()


func _unhandled_input(event: InputEvent) -> void:
	if not _rodando or terminado or _aguardando_tempo:
		return
	# Celular: tocar na tela avança. PC: clique esquerdo (o clique que o celular gera a partir
	# do toque é ignorado, senão um toque contaria duas vezes).
	var toque: bool = event is InputEventScreenTouch and event.pressed
	var clique: bool = event is InputEventMouseButton and event.pressed 			and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION
	if toque or clique or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _caixa.esta_completo():
			_avancar()
		else:
			_caixa.completar()


func _avancar() -> void:
	indice += 1
	if indice >= falas.size():
		concluir()
		return
	var fala: DialogueLine = falas[indice]
	fala_iniciada.emit(indice)
	if fala.acao != &"" and palco != null and palco.has_method(fala.acao):
		palco.call(fala.acao)
	if fala.som != null:
		AudioManager.registrar_sfx(&"fala_da_cena", fala.som)
		AudioManager.tocar_sfx(&"fala_da_cena")
	if fala.texto == "":
		_caixa.esconder()
		_aguardando_tempo = true
		_espera = fala.duracao_sem_texto
	else:
		_caixa.mostrar(fala)


## Chamado pela opção "Pular cena" da pausa.
func pular() -> void:
	concluir()


func concluir() -> void:
	if terminado:
		return
	terminado = true
	_caixa.esconder()
	terminou.emit()
	Events.cutscene_finished.emit(id)
	GameManager.concluir_cutscene(proxima_cena)

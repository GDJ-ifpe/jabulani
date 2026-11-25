extends Node

## Fluxo do jogo: sequência de cenas com fade, pausa, game over, reinício da arena,
## telas de conclusão e cenas de história.
## Sequência da Fase 1: menu -> abertura -> Caverna -> Superfície -> chefe -> cena final
## -> "Fase 1 concluída" -> menu.

const CENA_MENU: String = "res://shared/ui/menu_principal.tscn"
const CENA_ABERTURA: String = "res://fases/fase1_sertao/cutscenes/abertura.tscn"
const CENA_CAVERNA: String = "res://fases/fase1_sertao/subfase1_caverna/caverna.tscn"
const CENA_SUPERFICIE: String = "res://fases/fase1_sertao/subfase2_superficie/superficie.tscn"
const CENA_CHEFE_FASE1: String = "res://fases/fase1_sertao/boss/Base_Scenes/fase.tscn"
const CENA_POS_CHEFE_FASE1: String = "res://fases/fase1_sertao/cutscenes/pos_carlitos.tscn"
const CENA_PAUSA: String = "res://shared/ui/pausa.tscn"
const CENA_PAUSA_CUTSCENE: String = "res://shared/ui/pausa_cutscene.tscn"
const CENA_OPCOES: String = "res://shared/ui/opcoes.tscn"
const CENA_GAME_OVER: String = "res://shared/ui/game_over.tscn"
const CENA_CONCLUSAO: String = "res://shared/ui/subfase_concluida.tscn"
const CENA_FASE_CONCLUIDA: String = "res://shared/ui/fase_concluida.tscn"

## Primeira cena do jogo (menu -> Jogar).
const PRIMEIRA_CENA: String = CENA_ABERTURA

var duracao_fade: float = 0.35 # s (cada metade da transição)
var espera_game_over: float = 1.4 # s entre a morte e a tela de game over (deixa a animação tocar)

var _arena_atual: String = ""
var _proxima_pendente: String = "" # cena que "Continuar" abre na tela de conclusão
var _trocando: bool = false
var _painel: Node = null # pausa, game over ou conclusão em exibição
var _opcoes: Node = null # Opções abertas por cima da pausa
var _precarregando: String = "" # cena pedida em segundo plano (ver precarregar)
var _camada: CanvasLayer
var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camada = CanvasLayer.new()
	_camada.layer = 100
	add_child(_camada)
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada.add_child(_fade)
	PlayerData.player_died.connect(_on_player_died)
	Events.exit_reached.connect(concluir_arena)


func _unhandled_input(event: InputEvent) -> void:
	# Esc e o Options do controle abrem e fecham a pausa. A Bola do controle também é ui_cancel
	# (volta nos menus), mas em jogo ela é o dash: só fecha a pausa, nunca abre.
	var options: bool = InputMap.has_action(&"pausar") and event.is_action_pressed(&"pausar")
	var cancelar: bool = event.is_action_pressed("ui_cancel")
	if not options and not cancelar:
		return
	if _opcoes != null:
		# A própria tela de Opções trata Esc e Bola (volta para a pausa); Options fecha tudo.
		if options:
			continuar()
			get_viewport().set_input_as_handled()
		return
	if _painel != null and _painel.is_in_group("painel_pausa"):
		continuar()
		get_viewport().set_input_as_handled()
	elif pode_pausar() and (options or not event is InputEventJoypadButton):
		pausar()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- navegação

func novo_jogo() -> void:
	PlayerData.novo_jogo()
	if ResourceLoader.exists(PRIMEIRA_CENA):
		ir_para_cutscene(PRIMEIRA_CENA)
	else:
		ir_para_arena(CENA_CAVERNA)


## Entra numa arena (subfase de ondas ou chefe): vida cheia e ponto de reinício em caso de morte.
func ir_para_arena(caminho: String) -> void:
	if _trocando:
		return
	_arena_atual = caminho
	PlayerData.iniciar_arena()
	_trocar_cena(caminho)


## Entra numa cena de história (sem jogador).
func ir_para_cutscene(caminho: String) -> void:
	if _trocando:
		return
	_arena_atual = ""
	_trocar_cena(caminho)


## Regra de morte: recomeça a arena atual com vida cheia.
func reiniciar_arena() -> void:
	PlayerData.reiniciar_arena()
	_trocar_cena(_caminho_da_arena())


func ir_para_menu() -> void:
	_arena_atual = ""
	AudioManager.parar_tudo()
	_trocar_cena(CENA_MENU)


## Chamado quando o jogador atravessa a saída de uma arena: mostra a tela de conclusão da
## subfase. Se a próxima cena existe, a tela oferece "Continuar"; senão, "Jogar de novo".
func concluir_arena(proxima_cena: String) -> void:
	if _trocando or _painel != null:
		return
	var existe_proxima: bool = proxima_cena != "" and ResourceLoader.exists(proxima_cena)
	_proxima_pendente = proxima_cena if existe_proxima else ""
	if existe_proxima:
		precarregar(proxima_cena)
	var titulo: String = ""
	var arena: Node = get_tree().get_first_node_in_group("arena")
	if arena != null and "titulo_conclusao" in arena:
		titulo = arena.titulo_conclusao
	_abrir_painel(CENA_CONCLUSAO, true, func(painel: Node) -> void:
		if titulo != "":
			painel.set("titulo", titulo)
		if existe_proxima:
			painel.set("opcoes", PackedStringArray(["Continuar", "Menu"]))
			painel.call("definir_acoes", [&"PROXIMA_CENA", &"MENU"])
	)


## Opção "Continuar" da tela de conclusão.
func continuar_para_proxima() -> void:
	if _proxima_pendente == "":
		return
	var caminho: String = _proxima_pendente
	_proxima_pendente = ""
	ir_para_arena(caminho)


## Chamado quando uma cena de história termina (ou é pulada).
## Sem próxima cena, a fase acabou: mostra a tela "Fase concluída".
func concluir_cutscene(proxima_cena: String) -> void:
	if _trocando:
		return
	if proxima_cena != "" and ResourceLoader.exists(proxima_cena):
		_fechar_painel()
		get_tree().paused = false
		ir_para_arena(proxima_cena)
	else:
		_abrir_painel(CENA_FASE_CONCLUIDA, true)


## Opção "Pular cena" da pausa.
func pular_cutscene() -> void:
	var cena: Node = get_tree().get_first_node_in_group("cutscene")
	if cena != null and cena.get("terminado"):
		return # pedido repetido (ex.: Enter apertado duas vezes): não fecha a tela que a cena já abriu
	_fechar_painel()
	get_tree().paused = false
	if cena != null and cena.has_method("pular"):
		cena.pular()


## Começa a carregar uma cena em segundo plano, para a troca não travar o jogo depois
## (principalmente no navegador). A troca de cena usa o resultado se o caminho for o mesmo.
func precarregar(caminho: String) -> void:
	if caminho == "" or caminho == _precarregando or not ResourceLoader.exists(caminho):
		return
	_descartar_precarga()
	if ResourceLoader.load_threaded_request(caminho) == OK:
		_precarregando = caminho


## Esquece uma pré-carga que não vai ser usada (ex.: voltou ao menu no meio da cutscene).
func _descartar_precarga() -> void:
	if _precarregando == "":
		return
	if ResourceLoader.load_threaded_get_status(_precarregando) == ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_get(_precarregando)
	_precarregando = ""


func sair_do_jogo() -> void:
	get_tree().quit()


func _caminho_da_arena() -> String:
	if _arena_atual != "":
		return _arena_atual
	var cena: Node = get_tree().current_scene
	return cena.scene_file_path if cena != null else CENA_MENU


func _trocar_cena(caminho: String) -> void:
	if _trocando:
		return
	if not ResourceLoader.exists(caminho):
		push_error("GameManager: cena não encontrada: %s" % caminho)
		return
	_trocando = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, duracao_fade)
	await tween.finished
	_fechar_painel()
	get_tree().paused = false
	if caminho == _precarregando:
		_precarregando = ""
		var cena: PackedScene = ResourceLoader.load_threaded_get(caminho) as PackedScene
		if cena != null:
			get_tree().change_scene_to_packed(cena)
		else:
			get_tree().change_scene_to_file(caminho)
	else:
		_descartar_precarga()
		get_tree().change_scene_to_file(caminho)
	await get_tree().process_frame
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, duracao_fade)
	await tween.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trocando = false


# ---------------------------------------------------------------- pausa

func em_cutscene() -> bool:
	return get_tree().get_first_node_in_group("cutscene") != null


func pode_pausar() -> bool:
	if _trocando or _painel != null:
		return false
	if em_cutscene():
		return true
	if PlayerData.esta_morto():
		return false
	return get_tree().get_first_node_in_group("player") != null


func pausar() -> void:
	_abrir_painel(CENA_PAUSA_CUTSCENE if em_cutscene() else CENA_PAUSA, true)


## Opção "Opções" da pausa: abre os volumes por cima da pausa e volta para ela ao fechar.
func abrir_opcoes() -> void:
	if _painel == null or _opcoes != null:
		return
	var cena: PackedScene = load(CENA_OPCOES)
	if cena == null:
		push_error("GameManager: painel não encontrado: %s" % CENA_OPCOES)
		return
	_opcoes = cena.instantiate()
	_opcoes.tree_exited.connect(_on_opcoes_fechadas.bind(_opcoes))
	_camada.add_child(_opcoes)
	_camada.move_child(_fade, -1)
	_painel.visible = false


func _on_opcoes_fechadas(opcoes: Node) -> void:
	if _opcoes != opcoes:
		return
	_opcoes = null
	if is_instance_valid(_painel) and not _painel.is_queued_for_deletion():
		_painel.visible = true
		if _painel.has_method("focar"):
			_painel.focar()


func continuar() -> void:
	_fechar_painel()
	get_tree().paused = false


# ---------------------------------------------------------------- game over

func _on_player_died() -> void:
	await get_tree().create_timer(espera_game_over, true).timeout
	if _trocando or _painel != null or not PlayerData.esta_morto():
		return
	_abrir_painel(CENA_GAME_OVER, false)


# ---------------------------------------------------------------- painéis

## `preparar` recebe o painel antes de ele entrar na árvore (para trocar título e opções).
func _abrir_painel(caminho: String, pausar_jogo: bool, preparar: Callable = Callable()) -> void:
	_fechar_painel()
	var cena: PackedScene = load(caminho)
	if cena == null:
		push_error("GameManager: painel não encontrado: %s" % caminho)
		return
	_painel = cena.instantiate()
	if preparar.is_valid():
		preparar.call(_painel)
	_camada.add_child(_painel)
	_camada.move_child(_fade, -1)
	get_tree().paused = pausar_jogo


func _fechar_painel() -> void:
	if _opcoes != null:
		_opcoes.queue_free()
		_opcoes = null
	if _painel != null:
		_painel.queue_free()
		_painel = null

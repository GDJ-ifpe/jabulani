class_name WaveSpawner
extends Node

## Gera os inimigos das ondas nos SpawnPoints da arena.
## Para de gerar quando as ondas acabam, quando o tempo-limite passa ou quando a contagem
## de derrotados é atingida. A arena fica limpa quando, depois disso, não resta inimigo vivo.

signal onda_iniciada(numero: int)
signal geracao_encerrada
signal arena_limpa

@export var ondas: Array[WaveData] = []
@export var duracao_max_s: float = 90.0 # tempo-limite da geração: depois de 90 s não surgem mais inimigos (0 = sem limite)
@export var contagem_para_encerrar: int = 0 # quantidade de derrotados que encerra a geração (0 = desligado: vale só o tempo)
@export var atraso_inicial_s: float = 2.0 # respiro antes do primeiro inimigo
@export var iniciar_sozinho: bool = true
## Onde os inimigos entram na árvore (padrão: o pai do spawner).
@export var destino: Node

var onda_atual: int = -1
var derrotados: int = 0
var tempo_decorrido: float = 0.0
var gerando: bool = false
var encerrado: bool = false

var _fila: Array[WaveEntry] = []
var _restante_da_entrada: int = 0
var _espera: float = 0.0
var _limpa_emitida: bool = false
var _ninhos_ativos: Array[Node] = []


func _ready() -> void:
	Events.enemy_defeated.connect(_on_inimigo_derrotado)
	if destino == null:
		destino = get_parent()
	if iniciar_sozinho:
		iniciar.call_deferred()


func iniciar() -> void:
	if gerando or encerrado:
		return
	gerando = true
	_espera = atraso_inicial_s
	_proxima_onda()


func _process(delta: float) -> void:
	if gerando:
		tempo_decorrido += delta
		if duracao_max_s > 0.0 and tempo_decorrido >= duracao_max_s:
			_encerrar_geracao()
			return
		_espera -= delta
		if _espera <= 0.0:
			_gerar_lote()
	elif encerrado and not _limpa_emitida and inimigos_vivos() == 0:
		_limpa_emitida = true
		arena_limpa.emit()
		Events.arena_cleared.emit()


func inimigos_vivos() -> int:
	return get_tree().get_nodes_in_group("enemy").size()


func tempo_restante() -> float:
	return maxf(duracao_max_s - tempo_decorrido, 0.0)


# ---------------------------------------------------------------- ondas

func _proxima_onda() -> void:
	onda_atual += 1
	if onda_atual >= ondas.size():
		_encerrar_geracao()
		return
	_fila = ondas[onda_atual].entradas.duplicate()
	_restante_da_entrada = _fila[0].quantidade if not _fila.is_empty() else 0
	onda_iniciada.emit(onda_atual + 1)
	Events.wave_started.emit(onda_atual + 1)


func _gerar_lote() -> void:
	var onda: WaveData = ondas[onda_atual]
	_espera = onda.intervalo_s
	for i in maxi(onda.simultaneos, 1):
		_descartar_entradas_esgotadas()
		if _fila.is_empty():
			break
		# Sem ponto livre (ex.: todas as estalactites ocupadas ou a teia já com aranha),
		# o inimigo da vez é pulado: nunca dois ocupantes no mesmo ponto.
		_gerar(_fila[0])
		_restante_da_entrada -= 1
	_descartar_entradas_esgotadas()
	if _fila.is_empty():
		_proxima_onda()


func _descartar_entradas_esgotadas() -> void:
	while not _fila.is_empty() and _restante_da_entrada <= 0:
		_fila.pop_front()
		_restante_da_entrada = _fila[0].quantidade if not _fila.is_empty() else 0


func _gerar(entrada: WaveEntry) -> bool:
	var ponto: SpawnPoint = _ponto_livre(entrada.tipo_de_spawn)
	if ponto == null:
		return false

	if entrada.tipo_de_spawn == SpawnPoint.Tipo.NINHO:
		if ponto.ninho != null and ponto.ninho.has_method("ativar"):
			ponto.ninho.ativar()
			ponto.ocupar(ponto.ninho)
			_ninhos_ativos.append(ponto.ninho)
		return true

	if entrada.cena == null:
		return true
	var inimigo: Node2D = entrada.cena.instantiate()
	if destino is Node2D:
		inimigo.position = (destino as Node2D).to_local(ponto.global_position)
	else:
		inimigo.position = ponto.global_position
	if inimigo.has_method("configurar_spawn"):
		inimigo.configurar_spawn(ponto)
	ponto.ocupar(inimigo)
	destino.add_child(inimigo)
	return true


func _ponto_livre(tipo: SpawnPoint.Tipo) -> SpawnPoint:
	var livres: Array[SpawnPoint] = []
	for no in get_tree().get_nodes_in_group("spawn_point"):
		var ponto := no as SpawnPoint
		if ponto != null and ponto.tipo == tipo and ponto.esta_livre():
			livres.append(ponto)
	if livres.is_empty():
		return null
	return livres.pick_random()


func _encerrar_geracao() -> void:
	if encerrado:
		return
	gerando = false
	encerrado = true
	for ninho in _ninhos_ativos:
		if is_instance_valid(ninho) and ninho.has_method("desativar"):
			ninho.desativar()
	geracao_encerrada.emit()
	Events.spawner_finished.emit()


func _on_inimigo_derrotado(_inimigo: Node) -> void:
	derrotados += 1
	if gerando and contagem_para_encerrar > 0 and derrotados >= contagem_para_encerrar:
		_encerrar_geracao()

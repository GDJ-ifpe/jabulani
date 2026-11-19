extends Control

## Menu principal: Jogar, Opções, Créditos, Sair.

const CENA_OPCOES: PackedScene = preload("res://shared/ui/opcoes.tscn")
const CENA_CREDITOS: PackedScene = preload("res://shared/ui/creditos.tscn")

@onready var painel: PainelMenu = $Painel

var _sobreposta: Control = null # Opções ou Créditos em exibição


func _enter_tree() -> void:
	# No navegador não existe "sair": encerrar o motor trava a página. Lá o botão some
	# (antes de o painel montar os botões); quem joga fecha a aba.
	if OS.has_feature("web"):
		var painel_menu: PainelMenu = get_node("Painel")
		painel_menu.opcoes = painel_menu.opcoes.slice(0, painel_menu.opcoes.size() - 1)


func _ready() -> void:
	painel.opcao_escolhida.connect(_on_opcao)


func _on_opcao(indice: int) -> void:
	match indice:
		0:
			GameManager.novo_jogo()
		1:
			_abrir(CENA_OPCOES)
		2:
			_abrir(CENA_CREDITOS)
		3:
			GameManager.sair_do_jogo()


func _abrir(cena: PackedScene) -> void:
	if _sobreposta != null:
		return
	_sobreposta = cena.instantiate()
	add_child(_sobreposta)
	_sobreposta.tree_exited.connect(_on_sobreposta_fechada)
	painel.visible = false


func _on_sobreposta_fechada() -> void:
	_sobreposta = null
	painel.visible = true
	painel.focar()

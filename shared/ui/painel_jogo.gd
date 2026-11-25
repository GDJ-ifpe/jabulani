extends PainelMenu

## Painéis abertos pelo GameManager durante o jogo: pausa, game over e telas de conclusão.
## Cada opção chama uma ação do GameManager, na mesma ordem dos botões.

enum Acao { CONTINUAR, REINICIAR_ARENA, MENU, JOGAR_DE_NOVO, PROXIMA_CENA, PULAR_CENA, OPCOES }

@export var acoes: Array[Acao] = []
@export var mostrar_pontuacao: bool = false


func _ready() -> void:
	if mostrar_pontuacao:
		texto = "Pontuação: %05d" % PlayerData.pontos
	super()
	opcao_escolhida.connect(_on_opcao)


## Troca as ações por nome (ex.: [&"PROXIMA_CENA", &"MENU"]), antes de o painel entrar na árvore.
func definir_acoes(nomes: Array) -> void:
	acoes.clear()
	for nome in nomes:
		acoes.append(Acao[String(nome)])


func _on_opcao(indice: int) -> void:
	if indice >= acoes.size():
		return
	match acoes[indice]:
		Acao.CONTINUAR:
			GameManager.continuar()
		Acao.REINICIAR_ARENA:
			GameManager.reiniciar_arena()
		Acao.MENU:
			GameManager.ir_para_menu()
		Acao.JOGAR_DE_NOVO:
			GameManager.novo_jogo()
		Acao.PROXIMA_CENA:
			GameManager.continuar_para_proxima()
		Acao.PULAR_CENA:
			GameManager.pular_cutscene()
		Acao.OPCOES:
			GameManager.abrir_opcoes()

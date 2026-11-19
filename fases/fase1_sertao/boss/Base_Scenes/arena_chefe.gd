extends Arena

## Arena do chefe: uma tela só, sem ondas. Quando o chefe é derrotado, espera um instante
## e passa para a cena de história seguinte.

@export_file("*.tscn") var proxima_cena: String = ""
@export var espera_apos_derrota: float = 1.0 # s entre a derrota do chefe e a troca de cena


func _ready() -> void:
	super()
	Events.boss_defeated.connect(_on_chefe_derrotado)


func _on_chefe_derrotado(_id: StringName) -> void:
	await get_tree().create_timer(espera_apos_derrota, false).timeout
	if PlayerData.esta_morto():
		return
	if proxima_cena != "" and ResourceLoader.exists(proxima_cena):
		GameManager.ir_para_cutscene(proxima_cena)
	else:
		GameManager.concluir_cutscene("")

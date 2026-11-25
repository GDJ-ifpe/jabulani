extends StaticBody2D

## Parede de teia da Aranha Armadeira. Sólida (camada Terreno) enquanto existir.
## Com `duracao` > 0 some sozinha; com 0 fica até alguém chamar remover().
## Visual provisório: TODO_ARTE_teia.

@export var duracao: float = 5.0 # s até sumir (0 = permanente)
@export var tempo_de_aparecer: float = 0.25 # s

var _removendo: bool = false


func _ready() -> void:
	collision_layer = Camadas.TERRENO
	collision_mask = 0
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, tempo_de_aparecer)
	AudioManager.tocar_sfx(&"TODO_AUDIO_teia", -6.0)
	if duracao > 0.0:
		await get_tree().create_timer(duracao, false).timeout
		remover()


func remover() -> void:
	if _removendo:
		return
	_removendo = true
	collision_layer = 0
	remove_from_group("bloqueio_saida")
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, tempo_de_aparecer)
	tween.tween_callback(queue_free)

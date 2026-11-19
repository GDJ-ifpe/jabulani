extends BaseProjectile

## Carniça do urubu ("lixo representativo"): cai em linha reta, fere quem estiver embaixo
## e some ao tocar o chão. O desenho é sorteado entre os itens de lixo da folha.

## Regiões da folha de itens que podem aparecer.
@export var itens: Array[Rect2] = [
	Rect2(206, 16, 35, 46), # saco de papel
	Rect2(243, 12, 17, 50), # garrafa
	Rect2(262, 27, 23, 35), # pote
	Rect2(330, 22, 21, 40), # lata
	Rect2(353, 28, 18, 34), # latinha
	Rect2(496, 22, 17, 40), # caixinha
]

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	if not itens.is_empty():
		sprite.region_rect = itens.pick_random()


func _ao_tocar_terreno() -> void:
	AudioManager.tocar_sfx(&"TODO_AUDIO_carnica_chao", -10.0)
	destruir()

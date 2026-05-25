extends Node

signal hp_changed(novo_hp: int)
signal player_died

var max_hp: int = 5

var hp: int = max_hp:
	set(value):
		hp = clamp(value, 0, max_hp)
		hp_changed.emit(hp)
		if hp == 0:
			player_died.emit()

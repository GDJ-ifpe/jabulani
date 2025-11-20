extends Node2D

@onready var player := $player as CharacterBody2D
@onready var player_scene = preload("res://shared/player/scenes/player.tscn")
@onready var camera := $Camera2D as Camera2D

func _ready() -> void:
	player.follow_camera(camera)
	player.player_has_died.connect(reload_game)
	PlayerManager.player_life = 6
	PlayerManager.pontos = 0

func _process(_delta: float) -> void:
	pass

func reload_game():
	await get_tree().create_timer(1.0).timeout
	if get_tree():
		get_tree().reload_current_scene()
	

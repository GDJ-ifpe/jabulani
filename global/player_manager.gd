extends Node

var player = null
var pontos := 0 
var player_life := 6
var player_power := 6
var jabusintesi = false
var current_checkpoint = null


func respawn_player():
	if current_checkpoint  != null:
		player.position = current_checkpoint.global_position

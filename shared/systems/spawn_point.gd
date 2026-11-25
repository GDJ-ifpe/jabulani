class_name SpawnPoint
extends Marker2D

## Ponto onde o WaveSpawner faz um inimigo surgir. O tipo diz que inimigo cabe ali:
## estalactite (morcego pendurado), teia (aranha), ninho (formigas), borda (quem anda pelo chão)
## ou alto (quem chega voando: urubu, rolinhas). Cada ponto comporta um ocupante por vez.

enum Tipo { BORDA, ESTALACTITE, TEIA, NINHO, ALTO }

@export var tipo: Tipo = Tipo.BORDA
## TEIA: caminho da aranha, na ordem (filhos Node2D deste nó).
@export var no_waypoints: Node2D
## TEIA: pontos onde a aranha pode erguer paredes temporárias (filhos Node2D).
@export var no_pontos_de_parede: Node2D
## TEIA: ponto da parede que bloqueia a saída enquanto a aranha viver.
@export var ponto_parede_saida: Node2D
## NINHO: o ninho que este ponto ativa.
@export var ninho: Node

var ocupante: Node = null


func _ready() -> void:
	add_to_group("spawn_point")


func esta_livre() -> bool:
	return not is_instance_valid(ocupante)


func ocupar(no: Node) -> void:
	ocupante = no


func liberar() -> void:
	ocupante = null


func obter_waypoints() -> Array[Vector2]:
	return _posicoes(no_waypoints)


func obter_pontos_de_parede() -> Array[Vector2]:
	return _posicoes(no_pontos_de_parede)


func _posicoes(pai: Node2D) -> Array[Vector2]:
	var lista: Array[Vector2] = []
	if pai == null:
		return lista
	for filho in pai.get_children():
		if filho is Node2D:
			lista.append((filho as Node2D).global_position)
	return lista

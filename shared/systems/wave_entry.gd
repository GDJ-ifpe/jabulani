class_name WaveEntry
extends Resource

## Um item de uma onda: que inimigo, quantos e em que tipo de ponto ele surge.
## Para o ninho de formigas, deixe `cena` vazia e use o tipo NINHO: o spawner só ativa o ninho,
## que passa a soltar as formigas por conta própria.

@export var cena: PackedScene
@export var quantidade: int = 1
@export var tipo_de_spawn: SpawnPoint.Tipo = SpawnPoint.Tipo.BORDA

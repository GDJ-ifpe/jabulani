class_name WaveData
extends Resource

## Uma onda: lista de inimigos que surgem em ordem, `simultaneos` por vez, a cada `intervalo_s`.

@export var entradas: Array[WaveEntry] = []
@export var intervalo_s: float = 7.0 # s entre um surgimento e o próximo: 7 s na primeira onda da fase, 4 s nas seguintes
@export var simultaneos: int = 1 # inimigos que surgem juntos: 1 por vez no Sertão; 2 por vez na Zona da Mata e no Litoral

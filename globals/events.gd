extends Node

## Sinais globais, para sistemas que não se conhecem (ondas, HUD, áudio, fluxo de jogo).
## São emitidos e ouvidos por outros scripts; por isso o aviso de "sinal não usado" é silenciado.

@warning_ignore("unused_signal")
signal wave_started(numero: int)
@warning_ignore("unused_signal")
signal enemy_defeated(inimigo: Node)
@warning_ignore("unused_signal")
signal spawner_finished
@warning_ignore("unused_signal")
signal arena_cleared
@warning_ignore("unused_signal")
signal exit_reached(proxima_cena: String)
@warning_ignore("unused_signal")
signal boss_spawned(boss: Node)
@warning_ignore("unused_signal")
signal boss_defeated(id: StringName)
@warning_ignore("unused_signal")
signal cutscene_finished(id: StringName)

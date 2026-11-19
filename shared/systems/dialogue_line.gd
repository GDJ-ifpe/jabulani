class_name DialogueLine
extends Resource

## Um passo de uma cena de história: uma fala (quem fala + texto) e, opcionalmente,
## uma ação do palco disparada quando o passo começa.
## Sem texto, o passo é só a ação e avança sozinho depois de `duracao_sem_texto`.

@export var falante: String = ""
@export_multiline var texto: String = ""
@export var retrato: Texture2D
@export var som: AudioStream
## Nome de um método do palco da cena (troca de imagem, escurecer, efeito...).
@export var acao: StringName = &""
@export var duracao_sem_texto: float = 2.0 # s

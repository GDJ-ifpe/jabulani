class_name TelegraphWarning
extends Node2D

## Aviso visual rápido: pisca numa posição (retângulo ou círculo) antes de um ataque
## e some sozinho. Pode mostrar uma seta com a direção em que o ataque vai passar.
## Uso: TelegraphWarning.criar(pai, posicao_global, tamanho, duracao)

signal terminou

enum Forma { RETANGULO, CIRCULO }

@export var forma: Forma = Forma.RETANGULO
@export var tamanho: Vector2 = Vector2(48.0, 48.0) # retângulo: largura x altura; círculo: x = diâmetro
@export var duracao: float = 0.6 # s piscando antes de sumir
@export var piscadas_por_segundo: float = 6.0
@export var cor: Color = Color(1.0, 0.25, 0.2, 0.55)
@export var direcao: Vector2 = Vector2.ZERO # diferente de zero: desenha uma seta apontando para lá
@export var som: StringName = &"TODO_AUDIO_aviso"

var _tempo: float = 0.0


static func criar(pai: Node, posicao_global: Vector2, tamanho_aviso: Vector2, duracao_aviso: float,
		forma_aviso: Forma = Forma.RETANGULO, direcao_aviso: Vector2 = Vector2.ZERO) -> TelegraphWarning:
	var aviso := TelegraphWarning.new()
	aviso.tamanho = tamanho_aviso
	aviso.duracao = duracao_aviso
	aviso.forma = forma_aviso
	aviso.direcao = direcao_aviso
	pai.add_child(aviso)
	aviso.global_position = posicao_global
	return aviso


func _ready() -> void:
	z_index = 5
	if som != &"":
		AudioManager.tocar_sfx(som, -10.0)


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= duracao:
		terminou.emit()
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var intensidade: float = 0.5 + 0.5 * sin(_tempo * piscadas_por_segundo * TAU)
	var cor_atual := Color(cor.r, cor.g, cor.b, cor.a * (0.35 + 0.65 * intensidade))
	var contorno := Color(cor.r, cor.g, cor.b, minf(cor.a * 1.6, 1.0))
	if forma == Forma.CIRCULO:
		draw_circle(Vector2.ZERO, tamanho.x * 0.5, cor_atual)
		draw_arc(Vector2.ZERO, tamanho.x * 0.5, 0.0, TAU, 32, contorno, 1.0)
	else:
		var retangulo := Rect2(-tamanho * 0.5, tamanho)
		draw_rect(retangulo, cor_atual)
		draw_rect(retangulo, contorno, false, 1.0)
	if direcao != Vector2.ZERO:
		var d: Vector2 = direcao.normalized()
		var lateral := Vector2(-d.y, d.x)
		draw_colored_polygon(
			PackedVector2Array([d * 10.0, -d * 6.0 + lateral * 7.0, -d * 6.0 - lateral * 7.0]), Color.WHITE)

extends StaticBody2D

## Ninho das formigas saúvas. Depois de ativado pelo WaveSpawner, solta formigas em
## intervalos até ser desativado (fim das ondas) ou destruído. Não bloqueia a passagem
## e não conta como inimigo vivo para abrir a saída.
## Visual provisório: TODO_ARTE_ninho.

signal destruido

@export var cena_formiga: PackedScene
@export var max_hp: int = 10 # ninho destrutível com HP alto
@export var intervalo_s: float = 4.0 # s entre formigas (ritmo das ondas: 1 a cada 4 s)
@export var max_formigas_vivas: int = 2 # limite de formigas deste ninho ao mesmo tempo
@export var pontos: int = 10
@export var ponto_de_saida: Vector2 = Vector2(0.0, -10.0) # onde a formiga aparece, relativo ao ninho
@export var cor_inativo: Color = Color(0.6, 0.6, 0.6)
@export var cor_hit: Color = Color(1.0, 0.4, 0.4)

var hp: int
var ativo: bool = false
var is_dead: bool = false
var _espera: float = 0.0
var _formigas: Array = [] # sem tipo: guarda formigas que podem já ter saído da cena

@onready var visual: Node2D = $TODO_ARTE_ninho


func _ready() -> void:
	collision_layer = Camadas.INIMIGOS # só para receber golpes; não é terreno
	collision_mask = 0
	hp = max_hp
	visual.modulate = cor_inativo


func ativar() -> void:
	if is_dead or ativo:
		return
	ativo = true
	_espera = 0.5
	visual.modulate = Color.WHITE


func desativar() -> void:
	ativo = false
	if not is_dead:
		visual.modulate = cor_inativo


func _process(delta: float) -> void:
	if not ativo or is_dead:
		return
	_espera -= delta
	if _espera > 0.0:
		return
	_espera = intervalo_s
	_formigas = _formigas.filter(func(f: Variant) -> bool: return is_instance_valid(f) and not f.is_dead)
	if cena_formiga != null and _formigas.size() < max_formigas_vivas:
		_soltar_formiga()


func _soltar_formiga() -> void:
	var formiga: Node2D = cena_formiga.instantiate()
	get_parent().add_child(formiga)
	formiga.global_position = global_position + ponto_de_saida
	_formigas.append(formiga)
	AudioManager.tocar_sfx(&"TODO_AUDIO_formiga_saindo", -10.0)


func receber_dano(quantidade: int, _origem: Vector2 = Vector2.INF) -> void:
	if is_dead:
		return
	hp = maxi(hp - quantidade, 0)
	var tween: Tween = create_tween()
	tween.tween_property(visual, "modulate", cor_hit, 0.05)
	tween.tween_property(visual, "modulate", Color.WHITE if ativo else cor_inativo, 0.15)
	if hp <= 0:
		_destruir()


func _destruir() -> void:
	is_dead = true
	ativo = false
	collision_layer = 0
	PlayerData.adicionar_pontos(pontos)
	destruido.emit()
	AudioManager.tocar_sfx(&"TODO_AUDIO_ninho_destruido")
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale:y", 0.2, 0.4)
	tween.parallel().tween_property(visual, "modulate:a", 0.4, 0.4)

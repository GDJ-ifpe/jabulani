extends BaseProjectile

## Projétil das rolinhas: sai como uma pedra, em arco, e depois de um instante vira um míssil
## de fogo que segue em linha reta para onde o jogador está naquele momento.
## Visual provisório: TODO_ARTE_pedra e TODO_ARTE_missil_fogo.

@export var tempo_como_pedra: float = 0.5 # s até a pedra virar míssil
@export var velocidade_do_missil: float = 150.0 # px/s

var _virou_missil: bool = false
var _tempo: float = 0.0

@onready var visual_pedra: CanvasItem = $TODO_ARTE_pedra
@onready var visual_missil: CanvasItem = $TODO_ARTE_missil_fogo


func _ready() -> void:
	super()
	modo = Modo.ARCO
	visual_pedra.visible = true
	visual_missil.visible = false


func _physics_process(delta: float) -> void:
	super(delta)
	_tempo += delta
	if not _virou_missil and _tempo >= tempo_como_pedra:
		_virar_missil()
	if _virou_missil:
		visual_missil.scale.x = 1.0 + 0.15 * sin(_tempo * 40.0)


func _virar_missil() -> void:
	_virou_missil = true
	modo = Modo.RETA
	visual_pedra.visible = false
	visual_missil.visible = true
	var direcao: Vector2 = velocidade_atual.normalized()
	if is_instance_valid(alvo):
		direcao = (alvo.global_position - global_position).normalized()
	lancar(direcao, velocidade_do_missil)
	AudioManager.tocar_sfx(&"TODO_AUDIO_missil_fogo", -8.0)

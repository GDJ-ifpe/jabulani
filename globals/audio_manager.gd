extends Node

## Música, ambiente e efeitos. Barramentos: Master > Musica, SFX > Ambiente
## (o ambiente segue o volume de SFX das Opções).
## Música e ambiente pausam junto com o jogo; efeitos de interface não.

const BUS_MUSICA: StringName = &"Musica"
const BUS_SFX: StringName = &"SFX"
const BUS_AMBIENTE: StringName = &"Ambiente"

const VOLUME_MUDO_DB: float = -60.0
const TAXA_AMOSTRAGEM: int = 22050

var duracao_crossfade: float = 1.0 # s

var _musica: AudioStreamPlayer
var _ambiente: AudioStreamPlayer
var _sfx_registrados: Dictionary[StringName, AudioStream] = {}
var _placeholders: Dictionary[StringName, AudioStream] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_musica = _criar_player(BUS_MUSICA)
	_ambiente = _criar_player(BUS_AMBIENTE)


func _criar_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus if AudioServer.get_bus_index(bus) >= 0 else &"Master"
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	return player


# ---------------------------------------------------------------- música e ambiente

func tocar_musica(stream: AudioStream) -> void:
	_trocar(_musica, stream)


func tocar_ambiente(stream: AudioStream) -> void:
	_trocar(_ambiente, stream)


func parar_musica() -> void:
	_trocar(_musica, null)


func parar_ambiente() -> void:
	_trocar(_ambiente, null)


func parar_tudo() -> void:
	parar_musica()
	parar_ambiente()


func _trocar(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if player.stream == stream and (stream == null or player.playing):
		return
	var tween: Tween = create_tween()
	if player.playing:
		tween.tween_property(player, "volume_db", VOLUME_MUDO_DB, duracao_crossfade * 0.5)
	tween.tween_callback(_iniciar.bind(player, stream))
	if stream != null:
		tween.tween_property(player, "volume_db", 0.0, duracao_crossfade * 0.5)


func _iniciar(player: AudioStreamPlayer, stream: AudioStream) -> void:
	player.stop()
	player.stream = stream
	if stream == null:
		return
	_ativar_loop(stream)
	player.volume_db = VOLUME_MUDO_DB
	player.play()


func _ativar_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


# ---------------------------------------------------------------- efeitos

## Associa um identificador a um som de verdade. Enquanto não houver registro,
## tocar_sfx() usa um bipe gerado (identificadores TODO_AUDIO_*).
func registrar_sfx(id: StringName, stream: AudioStream) -> void:
	_sfx_registrados[id] = stream


func tocar_sfx(id: StringName, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _sfx_registrados.get(id)
	if stream == null:
		stream = _placeholder(id)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = BUS_SFX if AudioServer.get_bus_index(BUS_SFX) >= 0 else &"Master"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## Bipe curto, com tom derivado do identificador, para sons que ainda não existem.
func _placeholder(id: StringName) -> AudioStream:
	if _placeholders.has(id):
		return _placeholders[id]
	var frequencia: float = 220.0 + float(absi(hash(id)) % 12) * 55.0
	var duracao: float = 0.12
	var amostras: int = int(TAXA_AMOSTRAGEM * duracao)
	var dados := PackedByteArray()
	dados.resize(amostras * 2)
	for i in amostras:
		var t: float = float(i) / TAXA_AMOSTRAGEM
		var envelope: float = 1.0 - float(i) / amostras
		var valor: float = signf(sin(TAU * frequencia * t)) * envelope * 0.25
		dados.encode_s16(i * 2, int(valor * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TAXA_AMOSTRAGEM
	wav.stereo = false
	wav.data = dados
	_placeholders[id] = wav
	return wav


# ---------------------------------------------------------------- volumes (Opções)

## volume de 0.0 a 1.0
func definir_volume(bus: StringName, volume: float) -> void:
	var indice: int = AudioServer.get_bus_index(bus)
	if indice < 0:
		return
	AudioServer.set_bus_mute(indice, volume <= 0.001)
	AudioServer.set_bus_volume_db(indice, linear_to_db(clampf(volume, 0.001, 1.0)))


func obter_volume(bus: StringName) -> float:
	var indice: int = AudioServer.get_bus_index(bus)
	if indice < 0:
		return 1.0
	if AudioServer.is_bus_mute(indice):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(indice))

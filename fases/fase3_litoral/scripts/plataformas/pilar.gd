extends Node2D

const dura_temp := 1.0

@onready var platform := $plataform as AnimatableBody2D
@onready var sprite := $plataform/Sprite2D
@export var move_speed := 3.0
@export var distance := 192
@export var move_horizontal := true

@export var flash_duration: float = 0.5 
@export var flash_frequency: float = 0.05 

var flash_timer: float = 0.0
var flip_accumulator: float = 0.0
var is_flashing: bool = false
var is_moving: bool = false

var follow := Vector2.ZERO
var platform_center := 16
var is_flipped: bool = false
var platform_tween: Tween

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	platform.position = platform.position.lerp(follow, 0.5)
	
	if is_flashing:
		flash_timer -= _delta
		flip_accumulator += _delta
		if flip_accumulator >= flash_frequency:
			if is_flipped:
				sprite.scale.x = abs(sprite.scale.x)
				is_flipped = false
			else:
				sprite.scale.x = -abs(sprite.scale.x)
				is_flipped = true
			flip_accumulator = 0.0
		
		if flash_timer <= 0:
			is_flashing = false
			sprite.scale.x = abs(sprite.scale.x)
			is_flipped = false

func start_flash():
	flash_timer = flash_duration
	is_flashing = true

func move_platform():
	var move_direction = Vector2.RIGHT * distance if move_horizontal else Vector2.UP * distance
	var duran = move_direction.length() / float(move_speed * platform_center)
	
	platform_tween = create_tween().set_loops().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	platform_tween.tween_property(self, "follow", move_direction, duran).set_delay(dura_temp)
	platform_tween.tween_property(self, "follow", Vector2.ZERO, duran).set_delay(dura_temp)
	await get_tree().create_timer(3.0).timeout
	platform_tween.kill()

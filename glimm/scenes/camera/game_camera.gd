class_name GameCamera
extends Camera2D
## Folgt dem Spieler (Kind-Node), mit Screenshake über den Event-Bus.

@export var max_shake_offset := Vector2(16.0, 12.0)
@export var shake_recovery := 1.8

var _trauma := 0.0
var _noise := FastNoiseLite.new()
var _noise_time := 0.0


func _ready() -> void:
	_noise.frequency = 2.0
	Events.camera_shake_requested.connect(add_trauma)


func _process(delta: float) -> void:
	_trauma = maxf(_trauma - shake_recovery * delta, 0.0)
	_noise_time += delta * 30.0
	var amount := _trauma * _trauma
	offset = Vector2(
		max_shake_offset.x * amount * _noise.get_noise_2d(_noise_time, 0.0),
		max_shake_offset.y * amount * _noise.get_noise_2d(0.0, _noise_time)
	)


## strength ca. 0–10
func add_trauma(strength: float) -> void:
	_trauma = minf(_trauma + strength / 10.0, 1.0)


func apply_limits(world_rect: Rect2) -> void:
	limit_left = int(world_rect.position.x)
	limit_top = int(world_rect.position.y)
	limit_right = int(world_rect.end.x)
	limit_bottom = int(world_rect.end.y)

class_name PostFx
extends CanvasLayer
## Bildschirm-Effekte. Vignette folgt der Lichtmenge, pulse() erzeugt einen kurzen Farbversatz.

@export var min_vignette := 0.3
@export var max_vignette := 0.85

var _material: ShaderMaterial
var _pulse_tween: Tween

@onready var _rect: ColorRect = $Screen


func _ready() -> void:
	_material = _rect.material
	GameState.light_changed.connect(_on_light_changed)
	Events.player_died.connect(pulse.bind(0.03))
	_on_light_changed(GameState.light, GameState.MAX_LIGHT)


func pulse(strength: float = 0.015) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	_material.set_shader_parameter("aberration", strength)
	_pulse_tween = create_tween().set_ignore_time_scale(true)
	_pulse_tween.tween_method(
		func(value: float) -> void: _material.set_shader_parameter("aberration", value),
		strength, 0.0, 0.35
	)


func _on_light_changed(current: float, maximum: float) -> void:
	var darkness := 1.0 - current / maximum
	_material.set_shader_parameter("vignette_strength", lerpf(min_vignette, max_vignette, darkness * darkness))

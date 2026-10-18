extends PointLight2D
## Glimms Lichtkegel = aktuelle Lichtmenge. Weniger Licht -> kleinerer Radius, Flackern.

@export var min_texture_scale := 1.1
@export var max_texture_scale := 4.2
@export var min_energy := 0.9
@export var max_energy := 1.9
## Unterhalb dieses Anteils beginnt das Licht zu flackern.
@export var flicker_threshold := 0.25

var _ratio := 1.0


func _ready() -> void:
	GameState.light_changed.connect(_on_light_changed)
	_on_light_changed(GameState.light, GameState.MAX_LIGHT)
	texture_scale = lerpf(min_texture_scale, max_texture_scale, _ratio)


func _process(delta: float) -> void:
	var target_scale := lerpf(min_texture_scale, max_texture_scale, _ratio)
	texture_scale = lerpf(texture_scale, target_scale, 1.0 - exp(-6.0 * delta))

	var target_energy := lerpf(min_energy, max_energy, _ratio)
	if _ratio < flicker_threshold:
		target_energy *= randf_range(0.55, 1.0)
	energy = target_energy


func _on_light_changed(current: float, maximum: float) -> void:
	_ratio = current / maximum

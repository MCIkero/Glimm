extends Area2D
## "Lichtbrunnen": setzt den Checkpoint und füllt das Licht komplett auf.
## Der Node-Ursprung liegt auf dem Boden, gespawnt wird etwas darüber.

const SPAWN_OFFSET := Vector2(0, -16)

## Flammenfarbe, wenn dieser Brunnen der aktive Checkpoint ist (HDR, leuchtet).
@export var active_color := Color(2.2, 1.5, 0.7)
@export var inactive_color := Color(0.5, 0.6, 0.75)

var _active := false

@onready var _flame: Node2D = $Visual/Flame
@onready var _light: PointLight2D = $Light
@onready var _activate_sound: AudioStreamPlayer2D = $ActivateSound


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	GameState.checkpoint_changed.connect(_on_checkpoint_changed)
	_apply_state(false)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	GameState.refill_light()
	GameState.set_checkpoint(global_position + SPAWN_OFFSET)


func _on_checkpoint_changed(spawn_position: Vector2) -> void:
	var now_active := spawn_position.is_equal_approx(global_position + SPAWN_OFFSET)
	if now_active and not _active:
		_activate_sound.play()
	_active = now_active
	_apply_state(true)


func _apply_state(animated: bool) -> void:
	var target_scale := Vector2(1.0, 1.6) if _active else Vector2(0.7, 0.6)
	var target_color := active_color if _active else inactive_color
	var target_energy := 1.2 if _active else 0.45
	if not animated:
		_flame.scale = target_scale
		_flame.modulate = target_color
		_light.energy = target_energy
		return
	var tween := create_tween().set_parallel()
	tween.tween_property(_flame, "scale", target_scale, 0.4).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_flame, "modulate", target_color, 0.4)
	tween.tween_property(_light, "energy", target_energy, 0.4)

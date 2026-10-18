extends Area2D
## "Lichtbaum" am Levelende. Der Node-Ursprung liegt auf dem Boden.

## Farbe der Krone, sobald der Baum erreicht wurde (HDR).
@export var reached_color := Color(1.2, 2.2, 1.6)

var _reached := false

@onready var _canopy: Node2D = $Visual/Canopy
@onready var _complete_sound: AudioStreamPlayer2D = $CompleteSound


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _reached or not body is Player:
		return
	_reached = true
	_complete_sound.play()
	create_tween().tween_property(_canopy, "modulate", reached_color, 0.8)
	GameState.complete_level()
	Events.camera_shake_requested.emit(4.0)

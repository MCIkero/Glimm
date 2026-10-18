extends Area2D
## Sammelbarer Lichtsplitter: füllt Licht auf, erscheint nach einer Weile wieder.
## Aussehen und Schwebe-Animation stecken in der Szene (Visual + AnimationPlayer).

@export var light_amount := 35.0
@export var respawn_time := 10.0

var _active := true

@onready var _visual: Node2D = $Visual
@onready var _light: PointLight2D = $Light
@onready var _pickup_sound: AudioStreamPlayer2D = $PickupSound


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not _active or not body is Player:
		return
	GameState.change_light(light_amount)
	_pickup_sound.play()
	_set_active(false)
	get_tree().create_timer(respawn_time, false).timeout.connect(_set_active.bind(true))


func _set_active(value: bool) -> void:
	_active = value
	_visual.visible = value
	_light.enabled = value

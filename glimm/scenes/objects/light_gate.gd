@tool
extends StaticBody2D
## Lichttor: versperrt den Weg, bis man ihm Licht opfert.
## Berührt der Spieler das Tor und hat mehr als light_cost Licht, wird es abgezogen und
## das Tor öffnet sich dauerhaft. Sonst erscheint ein Hinweis.
## Der Node-Ursprung liegt auf dem Boden, das Tor ist 3 Kacheln hoch.

@export var light_cost := 40:
	set(value):
		light_cost = value
		_update_label()

var _open := false
var _last_hint_time := -10.0

@onready var _barrier: Node2D = $Visual/Barrier
@onready var _cost_label: Label = $CostLabel
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _light: PointLight2D = $Light


func _ready() -> void:
	_update_label()
	if Engine.is_editor_hint():
		return
	$Trigger.body_entered.connect(_on_trigger_body_entered)


func get_decor_block_rect() -> Rect2:
	return Rect2(global_position - Vector2(20, 96), Vector2(40, 96))


func _on_trigger_body_entered(body: Node2D) -> void:
	if _open or not body is Player:
		return
	if GameState.try_spend_light(light_cost):
		_open_gate()
	elif Time.get_ticks_msec() / 1000.0 - _last_hint_time > 3.0:
		_last_hint_time = Time.get_ticks_msec() / 1000.0
		$DeniedSound.play()
		Events.hint_requested.emit("Dieses Lichttor verlangt %d Licht. Sammle mehr und komm zurück." % light_cost)


func _open_gate() -> void:
	_open = true
	_collision.set_deferred("disabled", true)
	_cost_label.visible = false
	$OpenSound.play()
	var tween := create_tween().set_parallel()
	tween.tween_property(_barrier, "scale:y", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_light, "energy", 0.0, 0.8)
	Events.camera_shake_requested.emit(4.0)
	Events.hint_requested.emit("Das Lichttor nimmt dein Opfer an (−%d Licht)." % light_cost)


func _update_label() -> void:
	if is_node_ready():
		$CostLabel.text = str(light_cost)

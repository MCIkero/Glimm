@tool
class_name BashOrb
extends Area2D
## "Lichtsamen": Ziel für die Bash-Fähigkeit.
## Kann optional hin- und herschweben (Export "travel", im Editor als gestrichelte Linie sichtbar).
## Nach einem Bash wird er weggeschleudert und erscheint nach respawn_time wieder.
## Das Aussehen steckt in der Szene (Visual-Node + AnimationPlayer), nicht im Script.

signal bashed

## Bewegung relativ zur Startposition (Ping-Pong). Vector2.ZERO = statisch.
@export var travel := Vector2.ZERO:
	set(value):
		travel = value
		queue_redraw()
@export var travel_duration := 2.4
@export var respawn_time := 1.2
@export var fling_speed := 500.0

var _origin := Vector2.ZERO
var _travel_time := 0.0
var _cooldown := 0.0
var _held := false
var _fling_velocity := Vector2.ZERO

@onready var _visual: Node2D = $Visual
@onready var _highlight: CanvasItem = $Visual/HighlightRing
@onready var _light: PointLight2D = $Light
@onready var _base_light_energy := _light.energy


func _ready() -> void:
	_origin = position
	_highlight.visible = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _cooldown > 0.0:
		_cooldown -= delta
		position += _fling_velocity * delta
		_fling_velocity = _fling_velocity.lerp(Vector2.ZERO, 1.0 - exp(-4.0 * delta))
		var fade := clampf(_cooldown / respawn_time, 0.0, 1.0)
		_visual.modulate.a = 0.5 * fade
		_light.energy = _base_light_energy * 0.3 * fade
		if _cooldown <= 0.0:
			_reappear()
	elif not _held and travel != Vector2.ZERO:
		_travel_time += delta
		position = _origin + travel * _travel_progress()


func is_bashable() -> bool:
	return _cooldown <= 0.0


func set_highlighted(value: bool) -> void:
	_highlight.visible = value


func begin_bash() -> void:
	_held = true


## Wird vom Bash-Zustand aufgerufen. direction = Richtung, in die der Samen fliegt.
func launch(direction: Vector2) -> void:
	_held = false
	set_highlighted(false)
	bashed.emit()
	_on_launched(direction)


## Hook für Unterklassen (z. B. Projektile, die abprallen statt zu respawnen).
func _on_launched(direction: Vector2) -> void:
	_cooldown = respawn_time
	_fling_velocity = direction * fling_speed


func _reappear() -> void:
	position = _origin + travel * _travel_progress()
	_visual.modulate.a = 1.0
	_light.energy = _base_light_energy


func _travel_progress() -> float:
	return 0.5 - 0.5 * cos(_travel_time * TAU / travel_duration)


## Nur im Editor: Schwebestrecke anzeigen.
func _draw() -> void:
	if Engine.is_editor_hint() and travel != Vector2.ZERO:
		draw_dashed_line(Vector2.ZERO, travel, Color(1, 1, 1, 0.5), 1.5, 6.0)
		draw_arc(travel, 10.0, 0.0, TAU, 20, Color(1, 1, 1, 0.5), 1.5)

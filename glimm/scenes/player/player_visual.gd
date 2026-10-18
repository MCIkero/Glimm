class_name PlayerVisual
extends Node2D
## Aussehen der Spielfigur. Die Figur selbst besteht aus Nodes in player.tscn
## (Halo, Body, Shine, Eyes, AimArrow) – dieses Script bewegt sie nur:
## Squash & Stretch, Neigung, Blickrichtung, Ziel-Pfeil und Farbwechsel.
## Das Material "unshaded" sorgt dafür, dass Licht und Dunkelheit die Figur nicht verfärben.

@export var body_color := Color(0.85, 1.05, 1.15)
@export var denied_color := Color(1.0, 0.35, 0.35)
@export var faded_color := Color(0.35, 0.45, 0.55)
@export var eye_offset := 3.5

var _squash := Vector2.ONE
var _time := 0.0
var _state: StringName = &"Idle"
var _aim_visible := false
var _denied_flash := 0.0
var _brightness := 1.0

@onready var _player: Player = get_parent()
@onready var _figure: Node2D = $Figure
@onready var _body: CanvasItem = $Figure/Body
@onready var _halo: CanvasItem = $Figure/Halo
@onready var _eyes: Node2D = $Figure/Eyes
@onready var _aim_arrow: Node2D = $AimArrow
@onready var _halo_alpha := _halo.modulate.a


func _ready() -> void:
	_player.jumped.connect(_on_jumped)
	_player.landed.connect(_on_landed)
	_player.dashed.connect(func(_dir: int) -> void: _squash = Vector2(1.5, 0.65))
	_player.bashed.connect(func(_dir: Vector2) -> void: _squash = Vector2(0.6, 1.5))
	_player.died.connect(func() -> void: visible = false)
	_player.respawned.connect(_on_respawned)
	_player.ability_denied.connect(func() -> void: _denied_flash = 0.35)
	# Kinder sind vor dem Eltern-Node "ready" – daher direkt über den Pfad statt über @onready des Players.
	var state_machine: StateMachine = _player.get_node(^"StateMachine")
	state_machine.state_changed.connect(func(_from: StringName, to: StringName) -> void: _state = to)
	GameState.light_changed.connect(func(current: float, maximum: float) -> void: _brightness = current / maximum)
	_aim_arrow.visible = false


func _process(delta: float) -> void:
	_time += delta
	_denied_flash = maxf(_denied_flash - delta, 0.0)
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-12.0 * delta))

	var lean := 0.0 if _aim_visible else clampf(_player.velocity.x / 1200.0, -0.3, 0.3)
	rotation = lerp_angle(rotation, lean, 1.0 - exp(-10.0 * delta))
	scale = _squash

	_figure.position.y = sin(_time * 3.0) * 1.5 if _state == &"Idle" else 0.0
	_eyes.position.x = _player.facing * eye_offset

	var color := body_color.lerp(denied_color, _denied_flash / 0.35)
	_body.modulate = color.lerp(faded_color, (1.0 - _brightness) * 0.6)  # wenig Licht -> blasser
	_halo.modulate.a = _halo_alpha * (0.4 + 0.6 * _brightness)

	if _aim_visible:
		_aim_arrow.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.02)


func show_aim(enabled: bool) -> void:
	_aim_visible = enabled
	_aim_arrow.visible = enabled


func set_aim(direction: Vector2) -> void:
	_aim_arrow.global_rotation = direction.angle()


func _on_jumped(kind: StringName) -> void:
	_squash = Vector2(0.7, 1.35) if kind != &"wall" else Vector2(0.8, 1.2)


func _on_landed(fall_speed: float) -> void:
	var impact := clampf(fall_speed / _player.max_fall_speed, 0.0, 1.0)
	_squash = Vector2(1.0 + 0.45 * impact, 1.0 - 0.35 * impact)


func _on_respawned() -> void:
	visible = true
	_squash = Vector2(0.3, 1.8)

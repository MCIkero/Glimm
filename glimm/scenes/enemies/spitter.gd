@tool
class_name Spitter
extends StaticBody2D
## Speier: stationärer Gegner, der Schattenkugeln auf den Spieler schießt,
## sobald dieser in Reichweite und Sichtlinie ist. Wird von zurückgebashten Kugeln zerstört.
## Die Reichweite ist die Kreisform des Detector-Nodes (im Editor sichtbar und verstellbar).
## Der Node-Ursprung liegt auf dem Boden.

signal destroyed

@export var bolt_scene: PackedScene
@export var fire_interval := 2.2
@export var light_reward := 20.0

var _cooldown := 1.0
var _target: Player = null
var _alive := true

@onready var _muzzle: Marker2D = $Muzzle
@onready var _sight: RayCast2D = $Sight
@onready var _charge: Node2D = $Visual/Charge


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	add_to_group(&"reflect_target")
	$Detector.body_entered.connect(_on_detector_body_entered)
	$Detector.body_exited.connect(_on_detector_body_exited)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var charge := 0.0
	if _target:
		_cooldown -= delta
		charge = 1.0 - clampf(_cooldown / fire_interval, 0.0, 1.0)
		if _cooldown <= 0.0 and _has_line_of_sight():
			_cooldown = fire_interval
			_fire()
	_charge.scale = Vector2.ONE * (0.8 + 0.5 * charge)
	_charge.modulate.a = 0.5 + 0.5 * charge


## Wird von einer zurückgebashten Schattenkugel aufgerufen.
func take_reflected_hit() -> void:
	if not _alive:
		return
	_alive = false
	remove_from_group(&"reflect_target")
	$Visual.visible = false
	$Rubble.visible = true
	$Burst.restart()
	$DestroyedSound.play()
	$CollisionShape2D.set_deferred("disabled", true)
	$Light.enabled = false
	GameState.change_light(light_reward)  # besiegte Schatten geben Licht zurück
	Events.camera_shake_requested.emit(5.0)
	destroyed.emit()


func _on_detector_body_entered(body: Node2D) -> void:
	if body is Player:
		_target = body


func _on_detector_body_exited(body: Node2D) -> void:
	if body == _target:
		_target = null


func _has_line_of_sight() -> bool:
	_sight.target_position = _sight.to_local(_target.global_position)
	_sight.force_raycast_update()
	return not _sight.is_colliding()


func _fire() -> void:
	var bolt: ShadowBolt = bolt_scene.instantiate()
	bolt.global_position = _muzzle.global_position
	bolt.velocity = (_target.global_position - _muzzle.global_position).normalized() * bolt.speed
	get_parent().add_child(bolt)
	$ShootSound.play()

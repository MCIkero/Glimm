class_name ShadowBolt
extends BashOrb
## Projektil des Speiers. Fliegt geradeaus, tötet bei Berührung, verschwindet an Wänden.
## Bash-bar: Der Spieler schleudert sich weg, das Projektil fliegt zurück
## und trifft Gegner, die take_reflected_hit() anbieten (Speier, Boss).

@export var speed := 170.0
@export var reflected_speed := 650.0
@export var lifetime := 6.0
## Farbe nach dem Zurückschleudern (HDR, leuchtet).
@export var reflected_color := Color(2.0, 1.6, 0.8)
## Zurückgeschleuderte Kugeln lenken leicht auf Ziele in der Gruppe "reflect_target"
## (Speier, Boss), die grob in Flugrichtung liegen. Macht das Zurückschießen fair.
@export var homing_strength := 5.0
@export var homing_range := 800.0

var velocity := Vector2.ZERO
var _reflected := false


func _ready() -> void:
	super._ready()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if _reflected:
		_steer_towards_target(delta)
	if not _held:
		position += velocity * delta


func _steer_towards_target(delta: float) -> void:
	var best: Node2D = null
	var best_score := 0.5  # nur Ziele innerhalb von ca. 60° vor der Kugel
	for node in get_tree().get_nodes_in_group(&"reflect_target"):
		var target := node as Node2D
		var offset := target.global_position - global_position
		if offset.length() > homing_range:
			continue
		var score := velocity.normalized().dot(offset.normalized())
		if score > best_score:
			best_score = score
			best = target
	if best:
		var desired := (best.global_position - global_position).normalized() * velocity.length()
		velocity = velocity.lerp(desired, clampf(homing_strength * delta, 0.0, 1.0))


func is_bashable() -> bool:
	return not _reflected


func _on_launched(direction: Vector2) -> void:
	_reflected = true
	# Zurückgeschleudert fliegt die Kugel durch Wände und trifft nur noch Gegner (Layer "enemies").
	set_deferred("collision_mask", 16)
	velocity = direction * reflected_speed
	lifetime = 2.0
	$Visual/Core.modulate = reflected_color
	$Visual/Halo.modulate = Color(reflected_color, 0.25)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if not _reflected and not _held:
			(body as Player).die()
		return
	if _held:
		return
	if body.has_method("take_reflected_hit"):
		if not _reflected:
			return  # eigener Schütze beim Abfeuern
		body.take_reflected_hit()
	queue_free()  # Wand oder Gegner getroffen


func _on_area_entered(area: Area2D) -> void:
	# Gegner, die selbst ein Area2D sind (z. B. der Boss)
	if _reflected and not _held and area.has_method("take_reflected_hit"):
		area.take_reflected_hit()
		queue_free()

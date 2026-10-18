class_name ShadowHeart
extends Area2D
## Endboss "Schattenherz".
##
## Schwebt über der Arena und schießt Schattenkugeln. Verletzbar ist er nur durch
## zurückgebashte Kugeln (take_reflected_hit). Jeder Treffer gibt Glimm Licht zurück.
##   Phase 1: einzelne gezielte Kugeln
##   Phase 2: Dreier-Fächer, ruft Krabbler herbei (über phase_changed -> Arena)
##   Phase 3: schneller, Kugelringe in alle Richtungen, Arena wird dunkler
## Das Aussehen steckt in der Szene (Visual + AnimationPlayer).

signal phase_changed(phase: int)
signal defeated

@export var display_name := "Schattenherz"
@export var max_health := 6
@export var bolt_scene: PackedScene
## Hierhin werden die Kugeln gehängt (damit die Arena sie beim Reset entfernen kann).
@export var projectile_container: Node
@export_group("Bewegung")
@export var hover_width := 280.0
@export var hover_height := 18.0
@export var hover_period := 6.0
@export_group("Angriffe")
## Pause zwischen zwei Angriffen je Phase (Sekunden).
@export var fire_intervals: Array[float] = [2.6, 2.2, 1.8]
## Geschwindigkeit der Kugeln je Phase.
@export var bolt_speeds: Array[float] = [150.0, 170.0, 190.0]
@export var ring_bolt_count := 8
## Ab diesen Lebenspunkten beginnt Phase 2 bzw. 3.
@export var phase_two_health := 4
@export var phase_three_health := 2
@export var hit_light_reward := 15.0
@export var invulnerable_time := 0.8

var health := 0
var phase := 1
var active := false

var _origin := Vector2.ZERO
var _time := 0.0
var _fire_cooldown := 0.0
var _invulnerable := 0.0

@onready var _visual: Node2D = $Visual
@onready var _muzzle: Marker2D = $Muzzle


func _ready() -> void:
	_origin = position
	health = max_health
	add_to_group(&"reflect_target")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_time += delta
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	var period := hover_period * (0.65 if phase == 3 else 1.0)
	position = _origin + Vector2(
		sin(_time * TAU / period) * hover_width,
		sin(_time * 2.3) * hover_height
	)
	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		_fire_cooldown = fire_intervals[phase - 1]
		_attack()


func start() -> void:
	health = max_health
	phase = 1
	_time = 0.0
	_fire_cooldown = 1.5
	active = true
	visible = true
	_visual.modulate = Color.WHITE
	$CollisionShape2D.set_deferred("disabled", false)
	$RoarSound.play()
	Events.boss_started.emit(display_name, max_health)
	Events.boss_health_changed.emit(health, max_health)


## Komplett zurücksetzen (nach dem Tod des Spielers).
func reset() -> void:
	active = false
	health = max_health
	phase = 1
	position = _origin
	visible = true
	_visual.modulate = Color.WHITE
	$CollisionShape2D.set_deferred("disabled", false)
	Events.boss_reset.emit()


func take_reflected_hit() -> void:
	if not active or _invulnerable > 0.0:
		return
	health -= 1
	_invulnerable = invulnerable_time
	$HitSound.play()
	$Burst.restart()
	GameState.change_light(hit_light_reward)
	Events.camera_shake_requested.emit(6.0)
	Events.boss_health_changed.emit(health, max_health)
	var flash := create_tween()
	flash.tween_property(_visual, "modulate", Color(3, 3, 3), 0.05)
	flash.tween_property(_visual, "modulate", _phase_tint(), 0.3)

	if health <= 0:
		_defeat()
	elif health <= phase_three_health and phase < 3:
		_enter_phase(3)
	elif health <= phase_two_health and phase < 2:
		_enter_phase(2)


func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	$RoarSound.play()
	phase_changed.emit(phase)


func _phase_tint() -> Color:
	match phase:
		2:
			return Color(1.15, 0.9, 1.2)
		3:
			return Color(1.4, 0.75, 1.0)
	return Color.WHITE


func _defeat() -> void:
	active = false
	$CollisionShape2D.set_deferred("disabled", true)
	$DefeatSound.play()
	$Burst.amount = 80
	$Burst.restart()
	Events.camera_shake_requested.emit(10.0)
	var fade := create_tween()
	fade.tween_property(_visual, "scale", Vector2.ONE * 1.6, 0.6).set_trans(Tween.TRANS_BACK)
	fade.parallel().tween_property(_visual, "modulate:a", 0.0, 0.8)
	fade.tween_callback(_hide_after_defeat)
	defeated.emit()
	Events.boss_defeated.emit()


func _hide_after_defeat() -> void:
	visible = false
	_visual.scale = Vector2.ONE
	_visual.modulate = Color.WHITE


func _attack() -> void:
	var target := get_tree().get_first_node_in_group(&"player") as Node2D
	if target == null:
		return
	var aim := (target.global_position - _muzzle.global_position).normalized()
	var speed := bolt_speeds[phase - 1]
	match phase:
		1:
			_fire(aim, speed)
		2:
			for angle in [-0.32, 0.0, 0.32]:
				_fire(aim.rotated(angle), speed)
		3:
			for i in ring_bolt_count:
				_fire(Vector2.from_angle(TAU * i / ring_bolt_count + _time), speed * 0.8)
			_fire(aim, speed)
	$ShootSound.play()


func _fire(direction: Vector2, speed: float) -> void:
	var bolt: ShadowBolt = bolt_scene.instantiate()
	bolt.global_position = _muzzle.global_position
	bolt.velocity = direction * speed
	bolt.lifetime = 7.0
	var parent := projectile_container if projectile_container else get_parent()
	parent.add_child(bolt)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player and active:
		player.die()

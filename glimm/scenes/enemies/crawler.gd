class_name Crawler
extends CharacterBody2D
## Krabbler: läuft am Boden hin und her, dreht an Wänden und Kanten um.
## Berührung tötet den Spieler – außer er dasht hindurch, dann stirbt der Krabbler.
## Erscheint wieder, wenn der Spieler respawnt.

@export var speed := 70.0
@export var gravity := 1800.0
@export var light_reward := 15.0
## -1 = startet nach links, 1 = nach rechts.
@export_enum("Links:-1", "Rechts:1") var start_direction := -1

var _direction := -1
var _alive := true
var _spawn_position := Vector2.ZERO

@onready var _visual: Node2D = $Visual
@onready var _edge_check: RayCast2D = $EdgeCheck
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _burst: CPUParticles2D = $Burst


func _ready() -> void:
	_spawn_position = global_position
	_direction = -start_direction
	_turn_around()
	_hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	Events.player_respawned.connect(_revive)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	velocity.y = minf(velocity.y + gravity * delta, 600.0)
	velocity.x = _direction * speed
	move_and_slide()

	if is_on_floor() and (is_on_wall() or not _edge_check.is_colliding()):
		_turn_around()


func _turn_around() -> void:
	_direction *= -1
	_visual.scale.x = _direction  # die Grafik schaut nach rechts
	# Kantenprüfung sofort auf die neue Seite setzen und aktualisieren,
	# sonst meldet der Strahl im nächsten Frame noch den alten Abgrund (Hin-und-her-Zittern).
	_edge_check.position.x = 12.0 * _direction
	_edge_check.force_raycast_update()


func _on_hurtbox_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or not _alive:
		return
	if player.is_dashing():
		_defeat()
	else:
		player.die()


## Auch zurückgebashte Schattenkugeln besiegen Krabbler.
func take_reflected_hit() -> void:
	if _alive:
		_defeat()


func _defeat() -> void:
	_alive = false
	_visual.visible = false
	$Light.enabled = false
	$DefeatSound.play()
	_burst.restart()
	_hurtbox.set_deferred("monitoring", false)
	GameState.change_light(light_reward)
	Events.camera_shake_requested.emit(4.0)


func _revive() -> void:
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_direction = -start_direction
	_turn_around()
	_alive = true
	_visual.visible = true
	$Light.enabled = true
	_hurtbox.set_deferred("monitoring", true)

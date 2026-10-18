class_name Player
extends CharacterBody2D
## Der Spieler "Glimm".
##
## Dieses Script enthält nur gemeinsam genutzte Bewegungs-Bausteine
## (Schwerkraft, Laufen, Timer, Fähigkeits-Checks). WAS in welchem Moment
## passiert, entscheiden die Zustände unter $StateMachine.

signal jumped(kind: StringName)
signal landed(fall_speed: float)
signal dashed(direction: int)
signal bashed(direction: Vector2)
signal died
signal respawned
## Fähigkeit gedrückt, aber nicht genug Licht vorhanden.
signal ability_denied

const STICK_THRESHOLD := 0.25

@export_group("Laufen")
@export var run_speed := 260.0
@export var ground_acceleration := 2600.0
@export var ground_friction := 3000.0
@export var air_acceleration := 1700.0
## Bremsung, wenn man in der Luft schneller als run_speed ist (z. B. nach Bash).
@export var air_drag := 450.0

@export_group("Springen")
@export var jump_velocity := -560.0
@export var air_jump_velocity := -500.0
@export var gravity_rising := 1500.0
@export var gravity_falling := 2300.0
## Schwerkraft-Faktor, wenn Sprung-Taste früh losgelassen wird (variable Sprunghöhe).
@export var jump_cut_multiplier := 2.4
@export var max_fall_speed := 720.0
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.12
@export var air_jumps := 1

@export_group("Wand")
@export var wall_slide_speed := 110.0
@export var wall_jump_velocity := Vector2(330.0, -540.0)
@export var wall_jump_control_lock := 0.16

@export_group("Dash")
@export var dash_speed := 700.0
@export var dash_duration := 0.18
@export var dash_light_cost := 20.0

@export_group("Bash")
@export var bash_launch_speed := 820.0
@export var bash_light_cost := 10.0
@export var bash_max_hold_time := 1.6
@export var bash_time_scale := 0.12
@export var bash_control_lock := 0.22

var facing := 1
var air_jumps_left := 0
var can_dash := true
## Nur bei "normalen" Sprüngen darf ein früh losgelassener Knopf die Höhe kürzen.
var jump_cut_allowed := true
var bash_target: BashOrb = null

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _control_lock_timer := 0.0

@onready var state_machine: StateMachine = $StateMachine
@onready var visual: PlayerVisual = $Visual
@onready var _bash_detector: Area2D = $BashDetector
@onready var _wall_check_left: RayCast2D = $WallCheckLeft
@onready var _wall_check_right: RayCast2D = $WallCheckRight


func _ready() -> void:
	add_to_group(&"player")
	GameState.light_depleted.connect(die)
	refresh_air_abilities()
	state_machine.setup(self)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_bash_target()
	state_machine.physics_update(delta)


# --- Eingabe -------------------------------------------------------------------

## Digital (-1, 0, 1): ein halb gekippter Stick soll nicht "halb schnell" laufen lassen –
## so fühlen sich Controller und Tastatur gleich präzise an.
func get_input_direction() -> float:
	var axis := Input.get_axis(&"move_left", &"move_right")
	if absf(axis) < STICK_THRESHOLD:
		return 0.0
	return signf(axis)


func get_aim_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"aim_up", &"aim_down")


func is_jump_buffered() -> bool:
	return _jump_buffer_timer > 0.0


func consume_jump_buffer() -> void:
	_jump_buffer_timer = 0.0


func start_coyote_time() -> void:
	_coyote_timer = coyote_time


func has_coyote_time() -> bool:
	return _coyote_timer > 0.0


func clear_coyote_time() -> void:
	_coyote_timer = 0.0


## Reduziert kurzzeitig die Luftsteuerung, damit Wall-Jump/Bash-Schwung nicht sofort verpufft.
func lock_control(duration: float) -> void:
	_control_lock_timer = duration


# --- Bewegung ------------------------------------------------------------------

func apply_gravity(delta: float) -> void:
	var gravity := gravity_rising if velocity.y < 0.0 else gravity_falling
	if velocity.y < 0.0 and jump_cut_allowed and not Input.is_action_pressed(&"jump"):
		gravity *= jump_cut_multiplier
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func apply_horizontal_movement(delta: float, on_ground: bool) -> void:
	var input_dir := get_input_direction()
	var target_speed := input_dir * run_speed
	var acceleration: float

	if on_ground:
		acceleration = ground_acceleration if input_dir != 0.0 else ground_friction
	elif absf(velocity.x) > run_speed and signf(velocity.x) == signf(input_dir):
		acceleration = air_drag  # Schwung aus Dash/Bash erhalten
	else:
		acceleration = air_acceleration

	if _control_lock_timer > 0.0:
		acceleration *= 0.15
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)

	if input_dir != 0.0 and _control_lock_timer <= 0.0:
		facing = 1 if input_dir > 0.0 else -1


## -1 = Wand links, 1 = Wand rechts, 0 = keine Wand in Reichweite.
func get_wall_direction() -> int:
	if _wall_check_right.is_colliding():
		return 1
	if _wall_check_left.is_colliding():
		return -1
	return 0


func refresh_air_abilities() -> void:
	air_jumps_left = air_jumps if GameState.has_ability(&"double_jump") else 0
	can_dash = true


# --- Fähigkeits-Checks -------------------------------------------------------

func can_wall_jump() -> bool:
	return GameState.has_ability(&"wall_jump") and get_wall_direction() != 0


func can_start_dash() -> bool:
	if not Input.is_action_just_pressed(&"dash"):
		return false
	if not GameState.has_ability(&"dash") or not can_dash:
		return false
	return _check_light(dash_light_cost)


func can_start_bash() -> bool:
	if not Input.is_action_just_pressed(&"bash"):
		return false
	if bash_target == null:
		return false
	return _check_light(bash_light_cost)


func _check_light(cost: float) -> bool:
	if GameState.has_light_for(cost):
		return true
	ability_denied.emit()
	return false


func is_dashing() -> bool:
	return state_machine.current_state.name == &"Dash"


# --- Leben & Tod -------------------------------------------------------------

func die() -> void:
	if state_machine.current_state.name == &"Dead":
		return
	state_machine.transition_to(&"Dead")


func respawn() -> void:
	global_position = GameState.checkpoint_position
	velocity = Vector2.ZERO
	GameState.refill_light()
	refresh_air_abilities()
	respawned.emit()
	Events.player_respawned.emit()


# --- Intern ------------------------------------------------------------------

func _update_timers(delta: float) -> void:
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	_control_lock_timer = maxf(_control_lock_timer - delta, 0.0)
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_timer = jump_buffer_time


## Sucht den nächsten bash-baren Lichtsamen im Umkreis und hebt ihn hervor.
func _update_bash_target() -> void:
	var best: BashOrb = null
	if GameState.has_ability(&"bash"):
		var best_distance := INF
		for area in _bash_detector.get_overlapping_areas():
			var orb := area as BashOrb
			if orb == null or not orb.is_bashable():
				continue
			var distance := global_position.distance_squared_to(orb.global_position)
			if distance < best_distance:
				best_distance = distance
				best = orb

	if best == bash_target:
		return
	if is_instance_valid(bash_target):
		bash_target.set_highlighted(false)
	bash_target = best
	if bash_target:
		bash_target.set_highlighted(true)

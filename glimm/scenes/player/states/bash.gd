extends PlayerState
## Signatur-Mechanik: An einem Lichtsamen festhalten, Zeit verlangsamt sich,
## zielen, loslassen -> Glimm wird in Zielrichtung geschleudert, der Samen in die Gegenrichtung.

var _target: BashOrb
var _aim := Vector2.UP
var _held_time := 0.0


func enter(_previous_state: StringName, msg: Dictionary) -> void:
	_target = msg.get("target")
	_held_time = 0.0
	_aim = Vector2.UP

	GameState.try_spend_light(player.bash_light_cost)
	Engine.time_scale = player.bash_time_scale
	player.velocity = Vector2.ZERO
	_target.begin_bash()
	player.visual.show_aim(true)
	player.visual.set_aim(_aim)


func exit() -> void:
	Engine.time_scale = 1.0
	player.visual.show_aim(false)


func physics_update(delta: float) -> void:
	# delta ist durch Engine.time_scale verlangsamt – für das Halte-Limit brauchen wir Echtzeit.
	var real_delta := delta / Engine.time_scale
	_held_time += real_delta

	var input_aim := player.get_aim_vector()
	if input_aim.length() > 0.3:
		_aim = input_aim.normalized()
	player.visual.set_aim(_aim)

	if is_instance_valid(_target):
		var pull := 1.0 - exp(-18.0 * real_delta)
		player.global_position = player.global_position.lerp(_target.global_position, pull)

	if not Input.is_action_pressed(&"bash") or _held_time >= player.bash_max_hold_time:
		_launch()


func _launch() -> void:
	Engine.time_scale = 1.0
	player.velocity = _aim * player.bash_launch_speed
	if absf(_aim.x) > 0.1:
		player.facing = 1 if _aim.x > 0.0 else -1
	player.lock_control(player.bash_control_lock)
	player.refresh_air_abilities()

	if is_instance_valid(_target):
		_target.launch(-_aim)
	player.bashed.emit(_aim)
	Events.camera_shake_requested.emit(5.0)

	if _aim.y < 0.0:
		transition_to(&"Jump", {"kind": &"launch"})
	else:
		transition_to(&"Fall")

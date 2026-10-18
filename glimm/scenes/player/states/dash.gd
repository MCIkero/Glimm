extends PlayerState
## Kurzer, schwerkraftloser Sprint in Blickrichtung. Kann per Sprung abgebrochen werden
## (Dash-Jump behält den Schwung).

var _direction := 1
var _time_left := 0.0


func enter(_previous_state: StringName, _msg: Dictionary) -> void:
	GameState.try_spend_light(player.dash_light_cost)
	player.can_dash = false

	var input_direction := player.get_input_direction()
	if input_direction != 0.0:
		player.facing = 1 if input_direction > 0.0 else -1
	_direction = player.facing
	_time_left = player.dash_duration

	player.velocity = Vector2(_direction * player.dash_speed, 0.0)
	player.dashed.emit(_direction)
	Events.camera_shake_requested.emit(2.5)


func physics_update(delta: float) -> void:
	_time_left -= delta

	if player.is_jump_buffered() and (player.is_on_floor() or player.air_jumps_left > 0):
		var kind := &"ground" if player.is_on_floor() else &"air"
		player.velocity.x = _direction * player.dash_speed * 0.75
		transition_to(&"Jump", {"kind": kind})
		return

	player.velocity = Vector2(_direction * player.dash_speed, 0.0)
	player.move_and_slide()

	if player.is_on_wall():
		_time_left = 0.0
	if _time_left > 0.0:
		return

	player.velocity.x = _direction * player.run_speed
	if player.is_on_floor():
		transition_to(&"Run" if player.get_input_direction() != 0.0 else &"Idle")
	else:
		transition_to(&"Fall")

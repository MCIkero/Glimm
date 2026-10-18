extends PlayerState
## An der Wand langsam herunterrutschen. Frischt Doppelsprung und Dash auf.

var _wall_direction := 0


func enter(_previous_state: StringName, _msg: Dictionary) -> void:
	_wall_direction = player.get_wall_direction()
	player.facing = -_wall_direction  # vom Wand weg schauen (Dash geht dann nach außen)
	player.refresh_air_abilities()
	player.velocity.y = minf(player.velocity.y, player.wall_slide_speed)


func physics_update(delta: float) -> void:
	if try_ability_transitions():
		return
	if player.is_jump_buffered():
		transition_to(&"Jump", {"kind": &"wall"})
		return

	player.velocity.y = minf(player.velocity.y + player.gravity_falling * delta, player.wall_slide_speed)
	player.velocity.x = _wall_direction * 20.0  # leicht in die Wand drücken
	player.move_and_slide()

	if player.is_on_floor():
		transition_to(&"Idle")
		return

	var input_direction := signf(player.get_input_direction())
	if player.get_wall_direction() != _wall_direction or input_direction == -_wall_direction:
		transition_to(&"Fall")

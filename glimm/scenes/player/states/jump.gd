extends AirborneState
## Aufsteigende Phase. "kind" bestimmt, wie der Sprung ausgelöst wurde:
## ground, air (Doppelsprung), wall (Walljump) oder launch (nach Bash, Geschwindigkeit ist schon gesetzt).


func enter(_previous_state: StringName, msg: Dictionary) -> void:
	var kind: StringName = msg.get("kind", &"ground")
	player.consume_jump_buffer()
	player.clear_coyote_time()
	player.jump_cut_allowed = true

	match kind:
		&"ground":
			player.velocity.y = player.jump_velocity
		&"air":
			player.velocity.y = player.air_jump_velocity
			player.air_jumps_left -= 1
		&"wall":
			var wall_direction := player.get_wall_direction()
			player.velocity = Vector2(
				-wall_direction * player.wall_jump_velocity.x,
				player.wall_jump_velocity.y
			)
			player.facing = -wall_direction
			player.lock_control(player.wall_jump_control_lock)
			player.refresh_air_abilities()
		&"launch":
			player.jump_cut_allowed = false

	player.jumped.emit(kind)


func _check_air_transition() -> void:
	if player.velocity.y >= 0.0:
		transition_to(&"Fall")

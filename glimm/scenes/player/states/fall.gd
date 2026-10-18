extends AirborneState


func _check_air_transition() -> void:
	var wall_direction := player.get_wall_direction()
	var pushing_into_wall := wall_direction != 0 and signf(player.get_input_direction()) == wall_direction
	if pushing_into_wall and GameState.has_ability(&"wall_jump"):
		transition_to(&"WallSlide")

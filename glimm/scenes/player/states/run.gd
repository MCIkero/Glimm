extends GroundedState


func _check_ground_transition() -> void:
	if player.get_input_direction() == 0.0 and absf(player.velocity.x) < 10.0:
		transition_to(&"Idle")

class_name GroundedState
extends PlayerState
## Gemeinsame Logik für Zustände am Boden (Idle, Run).


func enter(_previous_state: StringName, _msg: Dictionary) -> void:
	player.refresh_air_abilities()


func physics_update(delta: float) -> void:
	if try_ability_transitions():
		return
	if player.is_jump_buffered():
		transition_to(&"Jump", {"kind": &"ground"})
		return

	player.apply_gravity(delta)
	player.apply_horizontal_movement(delta, true)
	player.move_and_slide()

	if not player.is_on_floor():
		player.start_coyote_time()
		transition_to(&"Fall")
		return
	_check_ground_transition()


## Wird von Idle/Run überschrieben.
func _check_ground_transition() -> void:
	pass

class_name AirborneState
extends PlayerState
## Gemeinsame Logik für Zustände in der Luft (Jump, Fall).


func physics_update(delta: float) -> void:
	if try_ability_transitions():
		return
	if _try_jumps():
		return

	player.apply_gravity(delta)
	player.apply_horizontal_movement(delta, false)
	var fall_speed := player.velocity.y
	player.move_and_slide()

	if player.is_on_floor():
		player.landed.emit(fall_speed)
		transition_to(&"Run" if player.get_input_direction() != 0.0 else &"Idle")
		return
	_check_air_transition()


## Reihenfolge: Coyote-Sprung > Walljump > Doppelsprung.
func _try_jumps() -> bool:
	if not player.is_jump_buffered():
		return false
	if player.has_coyote_time():
		transition_to(&"Jump", {"kind": &"ground"})
		return true
	if player.can_wall_jump():
		transition_to(&"Jump", {"kind": &"wall"})
		return true
	if player.air_jumps_left > 0:
		transition_to(&"Jump", {"kind": &"air"})
		return true
	return false


## Wird von Jump/Fall überschrieben.
func _check_air_transition() -> void:
	pass

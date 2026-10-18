extends PlayerState
## Kurze Pause nach dem Tod, danach Respawn am letzten Checkpoint.

@export var respawn_delay := 1.0

var _time_left := 0.0


func enter(_previous_state: StringName, _msg: Dictionary) -> void:
	_time_left = respawn_delay
	player.velocity = Vector2.ZERO
	GameState.register_death()
	player.died.emit()
	Events.player_died.emit()
	Events.camera_shake_requested.emit(8.0)


func physics_update(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		player.respawn()
		transition_to(&"Idle")

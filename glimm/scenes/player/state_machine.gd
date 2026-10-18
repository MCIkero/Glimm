class_name StateMachine
extends Node
## Einfache Finite State Machine.
##
## Jeder Kind-Node ist ein PlayerState. Der Besitzer ruft physics_update()
## auf, damit die Reihenfolge (erst Timer, dann Zustand) eindeutig ist.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: PlayerState

var current_state: PlayerState
var _states: Dictionary = {}


func setup(player: Player) -> void:
	for child in get_children():
		var state := child as PlayerState
		if state == null:
			continue
		state.player = player
		state.state_machine = self
		_states[state.name] = state

	current_state = initial_state
	current_state.enter(&"", {})


func physics_update(delta: float) -> void:
	current_state.physics_update(delta)


func transition_to(target_state: StringName, msg: Dictionary = {}) -> void:
	assert(_states.has(target_state), "Unbekannter Zustand: %s" % target_state)
	var previous := current_state.name
	current_state.exit()
	current_state = _states[target_state]
	current_state.enter(previous, msg)
	state_changed.emit(previous, target_state)

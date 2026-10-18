class_name PlayerState
extends Node
## Basisklasse für alle Spieler-Zustände.

var player: Player
var state_machine: StateMachine


func enter(_previous_state: StringName, _msg: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func transition_to(target_state: StringName, msg: Dictionary = {}) -> void:
	state_machine.transition_to(target_state, msg)


## Fähigkeiten, die aus (fast) jedem Zustand heraus starten können.
## Gibt true zurück, wenn ein Zustandswechsel stattgefunden hat.
func try_ability_transitions() -> bool:
	if player.can_start_bash():
		transition_to(&"Bash", {"target": player.bash_target})
		return true
	if player.can_start_dash():
		transition_to(&"Dash")
		return true
	return false

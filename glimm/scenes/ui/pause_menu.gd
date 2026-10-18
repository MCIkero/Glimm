class_name PauseMenu
extends CanvasLayer
## Pausenmenü. Läuft auch bei pausiertem Baum (process_mode = Always).
## Meldet nur Wünsche per Signal – was passiert, entscheidet Main.

signal resume_requested
signal restart_requested
signal menu_requested

@onready var _resume_button: Button = %ResumeButton
@onready var _controls_label: Label = %ControlsLabel


func _ready() -> void:
	visible = false
	%ResumeButton.pressed.connect(resume_requested.emit)
	%RestartButton.pressed.connect(restart_requested.emit)
	%MenuButton.pressed.connect(menu_requested.emit)
	InputHints.device_changed.connect(func(_pad: bool) -> void: _update_controls())
	Audio.connect_ui_sounds(self)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	_update_controls()
	visible = true
	get_tree().paused = true
	Audio.set_music_muffled(true)
	_resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	Audio.set_music_muffled(false)


func _update_controls() -> void:
	_controls_label.text = InputHints.format_text(
		"Laufen: {move}   ·   Springen: {jump}   ·   Dash: {dash}\n" +
		"Bash: {bash} halten + {aim} zielen   ·   Neustart: {restart}"
	)

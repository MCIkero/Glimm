extends Control
## Hauptmenü mit Levelauswahl. Mit Maus, Tastatur und Controller bedienbar
## (Godot-Fokus-Navigation über die ui_*-Aktionen).

const GAME_SCENE := "res://scenes/main.tscn"

## Musik im Hauptmenü.
@export var music: AudioStream

@onready var _play_button: Button = %PlayButton
@onready var _level_list: GridContainer = %LevelList
@onready var _controls_label: Label = %ControlsLabel


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false

	_play_button.pressed.connect(_start_level.bind(0))
	%QuitButton.pressed.connect(get_tree().quit)
	for i in GameState.get_level_count():
		var button := Button.new()
		button.text = "%d  ·  %s" % [i + 1, GameState.get_level_name(i)]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_start_level.bind(i))
		_level_list.add_child(button)

	Audio.play_music(music)
	InputHints.device_changed.connect(func(_pad: bool) -> void: _update_controls())
	_update_controls()
	_play_button.grab_focus()
	Audio.connect_ui_sounds(self)


func _start_level(index: int) -> void:
	GameState.select_level(index)
	get_tree().change_scene_to_file(GAME_SCENE)


func _update_controls() -> void:
	var device := "Controller" if InputHints.using_gamepad else "Tastatur"
	_controls_label.text = InputHints.format_text(
		"Steuerung (" + device + "):  Laufen {move}  ·  Springen {jump}  ·  Dash {dash}  ·  " +
		"Bash {bash}  ·  Pause {pause}"
	)

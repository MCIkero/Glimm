extends Node
## Spiel-Szene: lädt das aktuelle Level aus GameState, platziert den Spieler,
## konfiguriert die Kamera und behandelt globale Aktionen (Pause, Neustart, Levelwechsel).

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

var _level: Level
var _level_finished := false

@onready var _player: Player = $Player
@onready var _camera: GameCamera = $Player/Camera
@onready var _hud: Hud = $HUD
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _post_fx: PostFx = $PostFx


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false

	_level = GameState.get_current_level_scene().instantiate()
	add_child(_level)
	move_child(_level, 0)  # Level hinter dem Spieler zeichnen

	_player.global_position = _level.get_spawn_position()
	GameState.begin_level(_level.granted_abilities, _player.global_position)

	Audio.play_music(_level.music)
	_camera.apply_limits(_level.get_world_rect())
	_camera.reset_smoothing()

	Events.level_completed.connect(_on_level_completed)
	_player.bashed.connect(func(_dir: Vector2) -> void: _post_fx.pulse())
	_pause_menu.resume_requested.connect(_pause_menu.close)
	_pause_menu.restart_requested.connect(restart_level)
	_pause_menu.menu_requested.connect(_go_to_menu)

	_hud.show_level_title(GameState.current_level_index, _level.level_name)
	if not _level.start_hint.is_empty():
		Events.hint_requested.emit(_level.start_hint)


func _unhandled_input(event: InputEvent) -> void:
	if _level_finished:
		if event.is_action_pressed(&"jump") or event.is_action_pressed(&"ui_accept"):
			_continue()
		return

	if event.is_action_pressed(&"pause"):
		_pause_menu.open()
	elif event.is_action_pressed(&"restart"):
		restart_level()
	elif event.is_action_pressed(&"debug_unlock_all"):
		GameState.unlock_all_abilities()
		Events.hint_requested.emit("Debug: alle Fähigkeiten freigeschaltet")


func restart_level() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	Audio.set_music_muffled(false)
	get_tree().reload_current_scene()


func _on_level_completed(_time: float, _deaths: int) -> void:
	_level_finished = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED


func _continue() -> void:
	if GameState.has_next_level():
		GameState.select_level(GameState.current_level_index + 1)
		restart_level()
	else:
		_go_to_menu()


func _go_to_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	Audio.set_music_muffled(false)
	get_tree().change_scene_to_file(MAIN_MENU)

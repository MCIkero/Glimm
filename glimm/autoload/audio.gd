extends Node
## Musik und UI-Sounds (Autoload "Audio", Szene autoload/audio.tscn).
##
## Musik läuft über den Bus "Music", Effekte über "SFX" (siehe default_bus_layout.tres,
## im Editor unten im Audio-Panel einstellbar). Beim Musikwechsel wird überblendet.

## Wie lange ein Musikwechsel überblendet wird (Sekunden).
@export var crossfade_time := 1.2
## Lautstärke der Musik im Normalbetrieb (dB).
@export var music_volume_db := 0.0

var _active: AudioStreamPlayer
var _fading: AudioStreamPlayer

@onready var _music_a: AudioStreamPlayer = $MusicA
@onready var _music_b: AudioStreamPlayer = $MusicB
@onready var _ui_move: AudioStreamPlayer = $UiMove
@onready var _ui_confirm: AudioStreamPlayer = $UiConfirm


func _ready() -> void:
	_active = _music_a
	_fading = _music_b


## Startet eine neue Hintergrundmusik. Läuft dieselbe schon, passiert nichts.
func play_music(stream: AudioStream) -> void:
	if stream == null or (_active.playing and _active.stream == stream):
		return
	var previous := _active
	_active = _fading
	_fading = previous

	_active.stream = stream
	_active.volume_db = -40.0
	_active.play()
	var tween := create_tween().set_parallel()
	tween.tween_property(_active, "volume_db", music_volume_db, crossfade_time)
	if previous.playing:
		tween.tween_property(previous, "volume_db", -40.0, crossfade_time)
		tween.chain().tween_callback(previous.stop)


## Dämpft die Musik (z. B. im Pausenmenü) über den Low-Pass-Effekt auf dem Music-Bus.
func set_music_muffled(muffled: bool) -> void:
	var bus := AudioServer.get_bus_index(&"Music")
	if bus >= 0 and AudioServer.get_bus_effect_count(bus) > 0:
		AudioServer.set_bus_effect_enabled(bus, 0, muffled)


func play_ui_move() -> void:
	_ui_move.play()


func play_ui_confirm() -> void:
	_ui_confirm.play()


## Verbindet alle Buttons unter `root` mit den UI-Sounds.
func connect_ui_sounds(root: Node) -> void:
	for button in root.find_children("*", "BaseButton", true, false):
		button.focus_entered.connect(play_ui_move)
		button.pressed.connect(play_ui_confirm)

extends Node
## Merkt sich, ob zuletzt Tastatur oder Controller benutzt wurde (Autoload "InputHints"),
## und liefert passende Tastenbeschriftungen für Hinweistexte.
##
## In Texten können Platzhalter wie {jump}, {dash}, {bash}, {move}, {aim}, {pause}
## verwendet werden – format_text() ersetzt sie je nach Eingabegerät.

signal device_changed(using_gamepad: bool)

const KEYBOARD_LABELS := {
	"move": "A/D oder ←/→",
	"aim": "W/A/S/D",
	"jump": "Leertaste/J",
	"dash": "Shift/K",
	"bash": "E/L",
	"restart": "R",
	"pause": "Esc",
	"confirm": "Leertaste/Enter",
}
const XBOX_LABELS := {
	"move": "linker Stick",
	"aim": "linker Stick",
	"jump": "A",
	"dash": "X/RB",
	"bash": "Y/LB",
	"restart": "Back",
	"pause": "Start",
	"confirm": "A",
}
const PLAYSTATION_LABELS := {
	"move": "linker Stick",
	"aim": "linker Stick",
	"jump": "Kreuz",
	"dash": "Viereck/R1",
	"bash": "Dreieck/L1",
	"restart": "Share",
	"pause": "Options",
	"confirm": "Kreuz",
}
## Stick-Ausschläge darunter zählen nicht als Gerätewechsel (Drift).
const STICK_THRESHOLD := 0.5

var using_gamepad := false
var _pad_name := ""


func _ready() -> void:
	# Mit angestecktem Controller direkt Controller-Texte zeigen.
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		_pad_name = Input.get_joy_name(pads[0])
		using_gamepad = true


func _input(event: InputEvent) -> void:
	var is_pad := event is InputEventJoypadButton \
		or (event is InputEventJoypadMotion and absf(event.axis_value) > STICK_THRESHOLD)
	var is_keyboard := event is InputEventKey or event is InputEventMouseButton
	if is_pad:
		_pad_name = Input.get_joy_name(event.device)
		_set_gamepad(true)
	elif is_keyboard:
		_set_gamepad(false)


func label(action: String) -> String:
	return _labels().get(action, action)


func format_text(text: String) -> String:
	return text.format(_labels())


func _labels() -> Dictionary:
	if not using_gamepad:
		return KEYBOARD_LABELS
	var lower := _pad_name.to_lower()
	if lower.contains("playstation") or lower.contains("ps4") or lower.contains("ps5") or lower.contains("dualsense") or lower.contains("dualshock") or lower.contains("sony"):
		return PLAYSTATION_LABELS
	return XBOX_LABELS


func _set_gamepad(value: bool) -> void:
	if using_gamepad == value:
		return
	using_gamepad = value
	device_changed.emit(value)

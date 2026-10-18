extends Node
## Globaler Spielzustand (Autoload "GameState").
##
## Hält alles, was einen Tod bzw. Szenenwechsel überdauert: Licht,
## freigeschaltete Fähigkeiten, Checkpoint, Zeit und Tode.
## Änderungen werden per Signal gemeldet – UI und Spieler reagieren darauf.

signal light_changed(current: float, maximum: float)
signal light_depleted
signal ability_unlocked(ability: StringName)
signal checkpoint_changed(spawn_position: Vector2)
## Ein Level wurde (neu) gestartet – UI sollte sich komplett aktualisieren.
signal level_started(level_index: int)

const MAX_LIGHT := 100.0
## Licht, das pro Sekunde verloren geht. Das ist der Kern-Twist:
## Zeit und Fähigkeiten kosten Licht, Licht ist Sichtweite UND Leben.
const LIGHT_DECAY_PER_SECOND := 1.2

## Texte dürfen Platzhalter wie {dash} enthalten (siehe InputHints).
const ABILITY_INFO := {
	&"double_jump": {
		"name": "Doppelsprung",
		"hint": "In der Luft erneut {jump}: Doppelsprung.",
	},
	&"wall_jump": {
		"name": "Walljump",
		"hint": "An eine Wand springen und erneut {jump}: Walljump.",
	},
	&"dash": {
		"name": "Dash",
		"hint": "Neue Fähigkeit – DASH!  {dash}.  Kostet etwas Licht.",
	},
	&"bash": {
		"name": "Bash",
		"hint": "Neue Fähigkeit – BASH!  Nahe eines Lichtsamens {bash} halten, mit {aim} zielen, loslassen.  Frischt Doppelsprung und Dash auf.",
	},
}

## Levelliste als Resource – im Inspector bearbeitbar.
const LEVEL_CATALOG_PATH := "res://resources/level_catalog.tres"

const STARTING_ABILITIES: Array[StringName] = [&"double_jump", &"wall_jump"]

var light := MAX_LIGHT
var checkpoint_position := Vector2.ZERO
var elapsed_time := 0.0
var deaths := 0
var is_running := false
var current_level_index := 0

var level_catalog: LevelCatalog

var _unlocked: Dictionary = {}


func _ready() -> void:
	level_catalog = load(LEVEL_CATALOG_PATH)
	reset()


func _process(delta: float) -> void:
	if not is_running:
		return
	elapsed_time += delta
	change_light(-LIGHT_DECAY_PER_SECOND * delta)


## Setzt den kompletten Zustand zurück (Spielstart / Neustart).
func reset() -> void:
	_unlocked.clear()
	for ability in STARTING_ABILITIES:
		_unlocked[ability] = true
	light = MAX_LIGHT
	elapsed_time = 0.0
	deaths = 0
	is_running = false


## Startet das aktuelle Level frisch: Grund-Fähigkeiten + die, die das Level mitgibt.
func begin_level(granted_abilities: Array[StringName], spawn_position: Vector2) -> void:
	reset()
	for ability in granted_abilities:
		_unlocked[ability] = true
	checkpoint_position = spawn_position
	is_running = true
	level_started.emit(current_level_index)
	light_changed.emit(light, MAX_LIGHT)


func get_level_count() -> int:
	return level_catalog.levels.size()


func get_current_level_scene() -> PackedScene:
	return level_catalog.levels[current_level_index].scene


func get_level_name(index: int) -> String:
	return level_catalog.levels[index].title


func has_next_level() -> bool:
	return current_level_index + 1 < get_level_count()


func select_level(index: int) -> void:
	current_level_index = clampi(index, 0, get_level_count() - 1)


# --- Licht -------------------------------------------------------------------

func change_light(amount: float) -> void:
	var previous := light
	light = clampf(light + amount, 0.0, MAX_LIGHT)
	if is_equal_approx(light, previous):
		return
	light_changed.emit(light, MAX_LIGHT)
	if previous > 0.0 and light <= 0.0:
		light_depleted.emit()


func has_light_for(cost: float) -> bool:
	return light > cost


## Zieht Licht ab, falls genug vorhanden ist. Gibt zurück, ob es geklappt hat.
func try_spend_light(cost: float) -> bool:
	if not has_light_for(cost):
		return false
	change_light(-cost)
	return true


func refill_light() -> void:
	change_light(MAX_LIGHT)


# --- Fähigkeiten -------------------------------------------------------------

func has_ability(ability: StringName) -> bool:
	return _unlocked.get(ability, false)


func unlock_ability(ability: StringName) -> void:
	if has_ability(ability):
		return
	_unlocked[ability] = true
	ability_unlocked.emit(ability)


func unlock_all_abilities() -> void:
	for ability in ABILITY_INFO:
		unlock_ability(ability)


func get_ability_name(ability: StringName) -> String:
	return ABILITY_INFO.get(ability, {}).get("name", String(ability))


func get_ability_hint(ability: StringName) -> String:
	return ABILITY_INFO.get(ability, {}).get("hint", "")


# --- Fortschritt ---------------------------------------------------------------

func set_checkpoint(spawn_position: Vector2) -> void:
	if checkpoint_position.is_equal_approx(spawn_position):
		return
	checkpoint_position = spawn_position
	checkpoint_changed.emit(spawn_position)


func register_death() -> void:
	deaths += 1


func complete_level() -> void:
	if not is_running:
		return
	is_running = false
	Events.level_completed.emit(elapsed_time, deaths)

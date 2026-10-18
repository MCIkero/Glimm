class_name Hud
extends CanvasLayer
## HUD: Lichtleiste, Fähigkeiten, Zeit, Hinweise und Meldungen.
## Kennt keine Gameplay-Nodes – alles kommt über GameState- und Events-Signale.

const LOW_LIGHT_RATIO := 0.25
const ABILITY_ORDER: Array[StringName] = [&"double_jump", &"wall_jump", &"dash", &"bash"]

var _hint_tween: Tween
var _message_tween: Tween
var _light_ratio := 1.0
## Unformatierter Hinweistext – wird bei Gerätewechsel neu formatiert.
var _raw_hint := ""

@onready var _light_bar: ProgressBar = %LightBar
@onready var _abilities_label: RichTextLabel = %AbilitiesLabel
@onready var _time_label: Label = %TimeLabel
@onready var _hint_panel: PanelContainer = %HintPanel
@onready var _hint_label: Label = %HintLabel
@onready var _message_label: Label = %MessageLabel
@onready var _fade: ColorRect = %Fade
@onready var _boss_panel: Control = %BossPanel
@onready var _boss_name: Label = %BossName
@onready var _boss_bar: ProgressBar = %BossBar


func _ready() -> void:
	GameState.light_changed.connect(_on_light_changed)
	GameState.ability_unlocked.connect(func(_a: StringName) -> void: _refresh_abilities())
	GameState.checkpoint_changed.connect(func(_p: Vector2) -> void: show_message("Lichtbrunnen aktiviert", 1.2))
	Events.hint_requested.connect(show_hint)
	Events.player_died.connect(_on_player_died)
	Events.player_respawned.connect(_on_player_respawned)
	Events.level_completed.connect(_on_level_completed)
	GameState.level_started.connect(func(_i: int) -> void: _refresh_abilities())
	Events.boss_started.connect(_on_boss_started)
	Events.boss_health_changed.connect(_on_boss_health_changed)
	Events.boss_defeated.connect(func() -> void: _set_boss_panel_visible(false))
	Events.boss_reset.connect(func() -> void: _set_boss_panel_visible(false))
	InputHints.device_changed.connect(func(_pad: bool) -> void: _hint_label.text = InputHints.format_text(_raw_hint))

	_boss_panel.visible = false
	_hint_panel.modulate.a = 0.0
	_message_label.modulate.a = 0.0
	_fade.color.a = 0.0
	_on_light_changed(GameState.light, GameState.MAX_LIGHT)
	_refresh_abilities()


func _process(_delta: float) -> void:
	_time_label.text = _format_time(GameState.elapsed_time)
	if _light_ratio < LOW_LIGHT_RATIO:
		_light_bar.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.012)
	else:
		_light_bar.modulate.a = 1.0


func show_hint(text: String) -> void:
	_raw_hint = text
	_hint_label.text = InputHints.format_text(text)
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = _create_tween()
	_hint_tween.tween_property(_hint_panel, "modulate:a", 1.0, 0.25)
	_hint_tween.tween_interval(4.5)
	_hint_tween.tween_property(_hint_panel, "modulate:a", 0.0, 0.6)


func show_message(text: String, duration: float) -> void:
	_message_label.text = InputHints.format_text(text)
	if _message_tween:
		_message_tween.kill()
	_message_tween = _create_tween()
	_message_tween.tween_property(_message_label, "modulate:a", 1.0, 0.2)
	if duration > 0.0:
		_message_tween.tween_interval(duration)
		_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.5)


## Tweens sollen unabhängig von der Bash-Zeitlupe laufen.
func _create_tween() -> Tween:
	return create_tween().set_ignore_time_scale(true)


func _on_light_changed(current: float, maximum: float) -> void:
	_light_ratio = current / maximum
	_light_bar.max_value = maximum
	_light_bar.value = current


func _refresh_abilities() -> void:
	var parts: PackedStringArray = []
	for ability in ABILITY_ORDER:
		var ability_name := GameState.get_ability_name(ability)
		if GameState.has_ability(ability):
			parts.append("[color=#bff3ff]%s[/color]" % ability_name)
		else:
			parts.append("[color=#3a4560]???[/color]")
	_abilities_label.text = "  ·  ".join(parts)


func _on_player_died() -> void:
	var text := "Dein Licht ist erloschen" if GameState.light <= 0.0 else "Autsch!"
	show_message(text, 0.6)
	var tween := _create_tween()
	tween.tween_property(_fade, "color:a", 0.6, 0.35)


func _on_player_respawned() -> void:
	var tween := _create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.4)


func show_level_title(index: int, level_name: String) -> void:
	show_message("Level %d\n%s" % [index + 1, level_name], 1.8)


func _on_level_completed(time_seconds: float, deaths: int) -> void:
	var next := "{confirm}: nächstes Level" if GameState.has_next_level() else "Alle Level geschafft!\n{confirm}: Hauptmenü"
	show_message("Der Lichtbaum erstrahlt!\nZeit %s  ·  Tode %d\n\n%s" % [_format_time(time_seconds), deaths, next], 0.0)


func _on_boss_started(boss_name: String, max_health: int) -> void:
	_boss_name.text = boss_name
	_boss_bar.max_value = max_health
	_boss_bar.value = max_health
	_set_boss_panel_visible(true)


func _on_boss_health_changed(current: int, maximum: int) -> void:
	_boss_bar.max_value = maximum
	var tween := _create_tween()
	tween.tween_property(_boss_bar, "value", current, 0.3)


func _set_boss_panel_visible(value: bool) -> void:
	if value:
		_boss_panel.visible = true
		_boss_panel.modulate.a = 0.0
	var tween := _create_tween()
	tween.tween_property(_boss_panel, "modulate:a", 1.0 if value else 0.0, 0.4)
	if not value:
		tween.tween_callback(_boss_panel.hide)


func _format_time(seconds: float) -> String:
	return "%02d:%05.2f" % [floori(seconds / 60.0), fmod(seconds, 60.0)]

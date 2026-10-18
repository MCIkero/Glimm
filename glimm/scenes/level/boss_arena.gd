class_name BossArena
extends Node2D
## Steuert den Bosskampf: schließt das Tor hinter dem Spieler, startet den Boss,
## ruft in Phase 2 Krabbler, verdunkelt die Arena in Phase 3 und gibt nach dem Sieg
## den Lichtbaum frei. Stirbt der Spieler, wird alles zurückgesetzt.

@export var boss: ShadowHeart
@export var goal: Area2D
@export var darkness: CanvasModulate
@export var boss_music: AudioStream
@export var crawler_scene: PackedScene
@export_multiline var intro_hint := "Das Schattenherz! Bashe seine Kugeln – ziele dabei vom Boss weg, dann fliegt die Kugel zurück in ihn."
## Farbe der Grund-Dunkelheit in Phase 3.
@export var phase_three_darkness := Color(0.16, 0.14, 0.24)

var _active := false
var _defeated := false
var _base_darkness := Color.WHITE

@onready var _gate: StaticBody2D = $Gate
@onready var _projectiles: Node2D = $Projectiles
@onready var _summon_points: Node2D = $SummonPoints
@onready var _summoned: Node2D = $Summoned


func _ready() -> void:
	if darkness:
		_base_darkness = darkness.color
	$Trigger.body_entered.connect(_on_trigger_body_entered)
	boss.phase_changed.connect(_on_boss_phase_changed)
	boss.defeated.connect(_on_boss_defeated)
	Events.player_respawned.connect(_on_player_respawned)
	_set_gate_closed(false, false)
	goal.visible = false
	goal.process_mode = Node.PROCESS_MODE_DISABLED


func _on_trigger_body_entered(body: Node2D) -> void:
	if _active or _defeated or not body is Player:
		return
	_active = true
	_set_gate_closed(true, true)
	boss.start()
	Audio.play_music(boss_music)
	Events.hint_requested.emit(intro_hint)


func _on_boss_phase_changed(phase: int) -> void:
	match phase:
		2:
			# Aufruf kommt aus einem Physik-Callback (Treffer) – neue Körper erst danach einfügen.
			_summon_crawlers.call_deferred()
			Events.hint_requested.emit("Das Schattenherz ruft Krabbler herbei!")
		3:
			_tween_darkness(phase_three_darkness)
			Events.hint_requested.emit("Die Dunkelheit wächst – halte dein Licht am Leben!")


func _summon_crawlers() -> void:
	if not _active:
		return
	for marker in _summon_points.get_children():
		var crawler: Node2D = crawler_scene.instantiate()
		crawler.position = (marker as Node2D).position
		_summoned.add_child(crawler)


func _on_boss_defeated() -> void:
	_active = false
	_defeated = true
	_clear_spawned()
	_tween_darkness(_base_darkness)
	_set_gate_closed(false, true)
	GameState.refill_light()
	Audio.play_music(owner.music if owner else null)
	goal.process_mode = Node.PROCESS_MODE_INHERIT
	goal.visible = true
	goal.scale = Vector2(0.2, 0.2)
	create_tween().tween_property(goal, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK)
	Events.hint_requested.emit("Das Schattenherz ist besiegt! Der Lichtbaum erwacht.")


func _on_player_respawned() -> void:
	if not _active or _defeated:
		return
	_active = false
	_clear_spawned()
	boss.reset()
	_tween_darkness(_base_darkness)
	_set_gate_closed(false, false)
	Audio.play_music(owner.music if owner else null)


func _clear_spawned() -> void:
	for child in _projectiles.get_children() + _summoned.get_children():
		child.queue_free()


func _set_gate_closed(closed: bool, animated: bool) -> void:
	_gate.get_node("CollisionShape2D").set_deferred("disabled", not closed)
	var target := 1.0 if closed else 0.0
	var visual: Node2D = _gate.get_node("Visual")
	if animated:
		create_tween().tween_property(visual, "scale:y", target, 0.4).set_trans(Tween.TRANS_CUBIC)
		_gate.get_node("CloseSound").play()
	else:
		visual.scale.y = target


func _tween_darkness(color: Color) -> void:
	if darkness:
		create_tween().tween_property(darkness, "color", color, 1.5)

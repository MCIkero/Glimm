@tool
extends Area2D
## Unsichtbare Zone, die beim Betreten einen Hilfetext anzeigt.
## Größe = CollisionShape2D (im Editor mit den Anfassern ziehen).
## Platzhalter wie {jump}, {dash}, {bash} zeigen im Spiel die passende Taste.

@export_multiline var text := "":
	set(value):
		text = value
		queue_redraw()
@export var only_once := true

var _shown := false


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(true)
		return
	set_process(false)
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	queue_redraw()  # nur im Editor: Text folgt der Form


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or (only_once and _shown):
		return
	_shown = true
	Events.hint_requested.emit(text)


## Nur im Editor sichtbar: Anfang des Textes über der Zone.
func _draw() -> void:
	if not Engine.is_editor_hint() or not has_node("CollisionShape2D"):
		return
	var collision: CollisionShape2D = $CollisionShape2D
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		return
	var top_left := collision.position - shape.size * 0.5
	draw_string(ThemeDB.fallback_font, top_left + Vector2(0, -4), "Hinweis: " + text.left(32),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.95, 1.0))

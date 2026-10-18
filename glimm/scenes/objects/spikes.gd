@tool
extends Area2D
## Dornen über width_tiles Kacheln. Die Breite passt Grafik (Sprite2D mit Region)
## und Kollisionsform automatisch an – auch im Editor.
## Der Node-Ursprung ist die linke obere Ecke der ersten Kachel.

const TILE_SIZE := 32.0

@export_range(1, 64) var width_tiles := 1:
	set(value):
		width_tiles = value
		_apply_width()


func _ready() -> void:
	_apply_width()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func get_decor_block_rect() -> Rect2:
	return Rect2(global_position, Vector2(width_tiles * TILE_SIZE, TILE_SIZE))


func _apply_width() -> void:
	if not is_node_ready():
		return
	var width := width_tiles * TILE_SIZE
	var sprite: Sprite2D = $Visual
	sprite.region_rect = Rect2(0, 0, width, TILE_SIZE)
	var collision: CollisionShape2D = $CollisionShape2D
	(collision.shape as RectangleShape2D).size = Vector2(width - 8.0, 14.0)
	collision.position = Vector2(width * 0.5, TILE_SIZE - 7.0)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player:
		player.die()

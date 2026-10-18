@tool
extends Node2D
## Deko-Ebene: Gras, Ranken und Leuchtpilze sind normale Szenen-Instanzen
## (grass_tuft.tscn, vine.tscn, glow_mushroom.tscn) und können im Editor frei
## verschoben, gelöscht oder von Hand ergänzt werden.
##
## Der Button "Deko verteilen" im Inspector verteilt sie automatisch auf allen freien
## Oberflächen (vorhandene Deko wird dabei ersetzt). Objekte in der Gruppe
## "decor_blocker" (Dornen, Tore, Schreine …) halten Deko fern.

const GRASS_SCENE := preload("res://scenes/level/grass_tuft.tscn")
const VINE_SCENE := preload("res://scenes/level/vine.tscn")
const MUSHROOM_SCENE := preload("res://scenes/level/glow_mushroom.tscn")
const GRASS_TEXTURES: Array[Texture2D] = [
	preload("res://assets/textures/grass_1.png"),
	preload("res://assets/textures/grass_2.png"),
]

@export var terrain: AutoTerrain
@export_range(0.0, 1.0) var grass_chance := 0.55
@export_range(0.0, 1.0) var vine_chance := 0.3
@export_range(0.0, 1.0) var mushroom_chance := 0.05
@export_tool_button("Deko verteilen", "Reload") var distribute_action := distribute
@export_tool_button("Deko entfernen", "Remove") var clear_action := clear


func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.free()


func distribute() -> void:
	if terrain == null:
		push_warning("Decor: Bitte zuerst die Fels-Ebene (terrain) zuweisen.")
		return
	clear()
	var tile := Vector2(terrain.tile_set.tile_size)
	var blocked := _collect_blocked_rects()
	var rng := RandomNumberGenerator.new()

	for cell in terrain.get_used_cells():
		rng.seed = hash(cell)
		var above := cell + Vector2i.UP
		var below := cell + Vector2i.DOWN
		var surface_free := not terrain.is_solid(above) \
			and not _is_blocked(Rect2(Vector2(above) * tile, tile), blocked)
		if surface_free and rng.randf() < grass_chance:
			var grass: Sprite2D = _spawn(GRASS_SCENE, Vector2(cell.x * tile.x + rng.randf_range(4, tile.x - 4), cell.y * tile.y))
			grass.texture = GRASS_TEXTURES[rng.randi() % GRASS_TEXTURES.size()]
			grass.flip_h = rng.randf() < 0.5
		if surface_free and rng.randf() < mushroom_chance and not terrain.is_solid(above + Vector2i.UP):
			_spawn(MUSHROOM_SCENE, Vector2(cell.x * tile.x + rng.randf_range(8, tile.x - 8), cell.y * tile.y))
		if not terrain.is_solid(below) and not terrain.is_solid(below + Vector2i.DOWN) \
				and rng.randf() < vine_chance:
			var vine: Node2D = _spawn(VINE_SCENE, Vector2(cell.x * tile.x + rng.randf_range(4, tile.x - 4), (cell.y + 1) * tile.y))
			vine.scale = Vector2(1.0, rng.randf_range(0.3, 1.0))


func _spawn(scene: PackedScene, pos: Vector2) -> Node2D:
	var node: Node2D = scene.instantiate()
	node.position = pos
	add_child(node, true)
	# Owner setzen, damit die Deko in der Szene gespeichert wird und im Szenenbaum erscheint.
	node.owner = _scene_root()
	return node


func _scene_root() -> Node:
	if Engine.is_editor_hint() and get_tree().edited_scene_root:
		return get_tree().edited_scene_root
	return owner if owner else self


func _collect_blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for node in _scene_root().find_children("*", "Node2D", true, false):
		if not node.is_in_group(&"decor_blocker"):
			continue
		if node.has_method("get_decor_block_rect"):
			rects.append(node.get_decor_block_rect())
		else:
			rects.append(Rect2(node.global_position - Vector2(24, 48), Vector2(48, 56)))
	return rects


func _is_blocked(rect: Rect2, blocked: Array[Rect2]) -> bool:
	for other in blocked:
		if other.intersects(rect):
			return true
	return false

@tool
extends Node2D
## Schatten der Fels-Ebene als normale LightOccluder2D-Nodes (in der Szene gespeichert).
##
## Im Editor werden sie automatisch neu erzeugt, sobald man Fels malt oder radiert –
## oder per Button "Schatten neu erzeugen". Zeilenweise werden zusammenhängende Fels-Streifen
## zu einem Occluder zusammengefasst. Frei liegende Seiten werden um `inset` eingerückt:
## So bleibt die Felsoberfläche beleuchtet und erst dahinter beginnt der Schatten.

@export var terrain: AutoTerrain
@export var inset := 20.0
@export var auto_update := true
@export_tool_button("Schatten neu erzeugen", "Reload") var rebuild_action := rebuild


func _ready() -> void:
	if Engine.is_editor_hint() and terrain:
		terrain.cells_edited.connect(_on_cells_edited)


func _on_cells_edited() -> void:
	if auto_update:
		rebuild()


func rebuild() -> void:
	if terrain == null:
		return
	for child in get_children():
		remove_child(child)
		child.free()
	var tile := Vector2(terrain.tile_set.tile_size)
	var cells := terrain.get_used_cells()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))

	var i := 0
	while i < cells.size():
		var start: Vector2i = cells[i]
		var top_open := not terrain.is_solid(start + Vector2i.UP)
		var bottom_open := not terrain.is_solid(start + Vector2i.DOWN)
		var end := start
		# Streifen verlängern, solange die Nachbarkachel gleich "offen" ist
		while i + 1 < cells.size():
			var next: Vector2i = cells[i + 1]
			if next != end + Vector2i.RIGHT:
				break
			if (not terrain.is_solid(next + Vector2i.UP)) != top_open \
					or (not terrain.is_solid(next + Vector2i.DOWN)) != bottom_open:
				break
			end = next
			i += 1
		_add_strip(start, end, tile, top_open, bottom_open)
		i += 1


func _add_strip(start: Vector2i, end: Vector2i, tile: Vector2, top_open: bool, bottom_open: bool) -> void:
	var rect := Rect2(Vector2(start) * tile, Vector2(end.x - start.x + 1, 1) * tile)
	if top_open:
		rect = rect.grow_side(SIDE_TOP, -inset)
	if bottom_open:
		rect = rect.grow_side(SIDE_BOTTOM, -inset)
	if not terrain.is_solid(start + Vector2i.LEFT):
		rect = rect.grow_side(SIDE_LEFT, -inset)
	if not terrain.is_solid(end + Vector2i.RIGHT):
		rect = rect.grow_side(SIDE_RIGHT, -inset)
	var polygon := OccluderPolygon2D.new()
	polygon.polygon = PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)
	])
	var occluder := LightOccluder2D.new()
	occluder.name = "Strip%d_%d" % [start.x, start.y]
	occluder.occluder = polygon
	add_child(occluder)
	var root := get_tree().edited_scene_root if Engine.is_editor_hint() and get_tree().edited_scene_root else owner
	occluder.owner = root

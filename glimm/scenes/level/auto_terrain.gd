@tool
class_name AutoTerrain
extends TileMapLayer
## Fels-Ebene des Levels.
##
## Malen geht auf zwei Arten:
##   - im TileMap-Panel unter "Terrains" das Terrain "Fels" wählen (Godot-Autotiling), oder
##   - einfach irgendeine Fels-Kachel malen – dieses Script korrigiert dann die Variante.
## Zeile 0 = Fels innen, Zeile 1 = Oberfläche (Moos), Zeile 2 = Decke (Wurzeln),
## jeweils 4 Varianten, abhängig von der Position (sieht nicht gekachelt aus).

## Wird im Editor gesendet, nachdem Kacheln gemalt/radiert wurden (z. B. für TerrainShadows).
signal cells_edited

const SOURCE_ID := 0
const VARIANTS := 4
const ROW_INNER := 0
const ROW_TOP := 1
const ROW_BOTTOM := 2

var _update_queued := false
var _applying := false
var _loaded := false


func _ready() -> void:
	# Nach dem Laden der Szene nicht sofort reagieren – nur auf echte Änderungen.
	_mark_loaded.call_deferred()


## Wird von Godot aufgerufen, sobald sich Kacheln ändern (z. B. beim Malen im Editor).
func _update_cells(_coords: Array[Vector2i], forced_cleanup: bool) -> void:
	if Engine.is_editor_hint() and _loaded and not forced_cleanup:
		_queue_update()


func is_solid(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


## Rechteck aller gemalten Kacheln in Pixeln (Level-Koordinaten).
func get_world_rect() -> Rect2:
	var used := get_used_rect()
	var size := Vector2(tile_set.tile_size)
	return Rect2(Vector2(used.position) * size, Vector2(used.size) * size)


func _mark_loaded() -> void:
	_loaded = true


func _queue_update() -> void:
	if _update_queued or _applying:
		return
	_update_queued = true
	_apply_variants.call_deferred()


func _apply_variants() -> void:
	_update_queued = false
	_applying = true
	for cell in get_used_cells():
		if get_cell_source_id(cell) != SOURCE_ID:
			continue
		var wanted := _pick_atlas_coords(cell)
		if get_cell_atlas_coords(cell) != wanted:
			set_cell(cell, SOURCE_ID, wanted)
	_applying = false
	cells_edited.emit()


func _pick_atlas_coords(cell: Vector2i) -> Vector2i:
	var variant := absi(hash(cell)) % VARIANTS
	if not is_solid(cell + Vector2i.UP):
		return Vector2i(variant, ROW_TOP)
	if not is_solid(cell + Vector2i.DOWN):
		return Vector2i(variant, ROW_BOTTOM)
	return Vector2i(variant, ROW_INNER)

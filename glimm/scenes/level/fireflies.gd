@tool
extends GPUParticles2D
## Glühwürmchen über das ganze Level verteilt. Beim Spielstart passen sich Bereich und
## Menge automatisch an die gemalte Fels-Ebene an.

@export var terrain: AutoTerrain
@export var per_million_pixels := 45.0


func _ready() -> void:
	if terrain and not Engine.is_editor_hint():
		process_material = process_material.duplicate()
		_fit_to_terrain()


func _fit_to_terrain() -> void:
	var area := terrain.get_world_rect()
	if area.has_area() == false:
		return
	var material := process_material as ParticleProcessMaterial
	material.emission_box_extents = Vector3(area.size.x * 0.5, area.size.y * 0.5, 0)
	position = area.get_center()
	amount = maxi(int(area.get_area() / 1_000_000.0 * per_million_pixels), 16)
	visibility_rect = Rect2(-area.size * 0.5, area.size)
	preprocess = lifetime

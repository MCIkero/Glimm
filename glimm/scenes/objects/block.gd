@tool
class_name Block
extends StaticBody2D
## Einzelner Felsblock (32 × 32 px) als Baustein für das Level-Design.
##
## Im Editor einfach aus dem Dateisystem-Dock ins Level ziehen (unter "Blocks"),
## mit Einrasten auf 32 px verschieben, mit Strg+D duplizieren – wie Bauklötze.
## Kollision, Schatten (LightOccluder2D) und Beleuchtung (Normal Map) sind eingebaut.
## Ursprung = linke obere Ecke, damit Blöcke exakt im 32-px-Raster sitzen.

enum Look { STONE, MOSS_TOP, ROOTS_BOTTOM }

## Steinmuster (vier Varianten aus dem Kachel-Atlas).
@export_range(0, 3) var variant := 0:
	set(value):
		variant = value
		_apply()

## Aussehen: normaler Stein, Moos oben oder Wurzeln unten.
@export var look := Look.STONE:
	set(value):
		look = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	$Sprite2D.region_rect = Rect2(variant * 32, int(look) * 32, 32, 32)

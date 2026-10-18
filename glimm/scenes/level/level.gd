class_name Level
extends Node2D
## Wurzel eines Levels. Stellt Spawnpunkt und Weltgrenzen für Main/Kamera bereit.
##
## Neues Level: scenes/levels/level_template.tscn duplizieren, im Editor gestalten und
## in resources/level_catalog.tres eintragen. Name, Start-Hinweis, Fähigkeiten und Musik
## im Inspector setzen.

@export var level_name := "Level"
@export_multiline var start_hint := ""
## Fähigkeiten, die man in diesem Level von Anfang an besitzt (zusätzlich zu den Grund-Fähigkeiten).
@export var granted_abilities: Array[StringName] = []
## Hintergrundmusik dieses Levels (läuft in Schleife).
@export var music: AudioStream

@onready var _terrain: AutoTerrain = $Terrain
@onready var _player_spawn: Marker2D = $PlayerSpawn


func get_spawn_position() -> Vector2:
	return _player_spawn.global_position


func get_world_rect() -> Rect2:
	return _terrain.get_world_rect()

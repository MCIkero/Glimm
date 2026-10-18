class_name LevelCatalog
extends Resource
## Reihenfolge der Level. Im Inspector bearbeiten: Eintrag hinzufügen, Titel setzen,
## Level-Szene in das Feld "Scene" ziehen. Das Hauptmenü liest diese Liste automatisch.

@export var levels: Array[LevelEntry] = []

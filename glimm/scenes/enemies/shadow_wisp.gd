@tool
class_name ShadowWisp
extends BashOrb
## Schatten-Irrlicht: schwebender Gegner. Tödlich bei Berührung –
## aber (wie ein Lichtsamen) bash-bar. Erbt die komplette Bash-Logik von BashOrb.


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	# Während man es festhält oder es gerade weggeschleudert wurde, ist es harmlos.
	if player and is_bashable() and not _held:
		player.die()

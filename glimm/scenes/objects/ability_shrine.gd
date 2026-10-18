@tool
extends Area2D
## Schrein, der beim Betreten eine Fähigkeit freischaltet (Metroidvania-Progression).
## Der Node-Ursprung liegt auf dem Boden.

## Freigeschaltete Fähigkeit: "dash" oder "bash".
@export var ability: StringName = &"dash"
## Farbe der schwebenden Rune (HDR-Werte > 1 leuchten).
@export var rune_color := Color(1.35, 1.0, 1.8):
	set(value):
		rune_color = value
		_apply_color()

@onready var _orb: Node2D = $Visual/Orb
@onready var _light: PointLight2D = $Light
@onready var _unlock_sound: AudioStreamPlayer2D = $UnlockSound


func _ready() -> void:
	_apply_color()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	GameState.ability_unlocked.connect(func(_a: StringName) -> void: _update_used())
	GameState.level_started.connect(func(_i: int) -> void: _update_used())
	_update_used()


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or GameState.has_ability(ability):
		return
	GameState.unlock_ability(ability)
	GameState.refill_light()
	_unlock_sound.play()
	Events.hint_requested.emit(GameState.get_ability_hint(ability))
	Events.camera_shake_requested.emit(6.0)


func _update_used() -> void:
	var used := GameState.has_ability(ability)
	_orb.modulate.a = 0.35 if used else 1.0
	$Visual/Orb/Ring.visible = not used
	_light.energy = 0.35 if used else 1.2


func _apply_color() -> void:
	if not is_node_ready():
		return
	$Visual/Orb/Core.modulate = rune_color
	$Visual/Orb/Halo.modulate = Color(rune_color, 0.3)
	var brightest := maxf(1.0, maxf(rune_color.r, maxf(rune_color.g, rune_color.b)))
	$Light.color = Color(rune_color.r / brightest, rune_color.g / brightest, rune_color.b / brightest)

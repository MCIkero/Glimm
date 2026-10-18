extends Node2D
## Partikel- und Sound-Feedback des Spielers. Hört nur auf Player-Signale.
## Die Sounds sind AudioStreamPlayer-Nodes unter "Sounds" (im Editor austauschbar).

@onready var _player: Player = get_parent()
@onready var _trail: CPUParticles2D = $Trail
@onready var _burst: CPUParticles2D = $Burst
@onready var _dust: CPUParticles2D = $Dust
@onready var _sounds: Node = $Sounds


func _ready() -> void:
	_player.jumped.connect(_on_jumped)
	_player.landed.connect(_on_landed)
	_player.dashed.connect(_on_dashed)
	_player.bashed.connect(_on_bashed)
	_player.died.connect(_on_died)
	_player.respawned.connect(_on_respawned)
	_player.ability_denied.connect(_play.bind(&"Denied"))


func _on_jumped(kind: StringName) -> void:
	match kind:
		&"ground", &"wall":
			_dust.restart()
			_play(&"Jump")
		&"air":
			_emit_burst(12, 160.0)
			_play(&"DoubleJump")


func _on_dashed(_direction: int) -> void:
	_emit_burst(18, 260.0)
	_play(&"Dash")


func _on_bashed(_direction: Vector2) -> void:
	_emit_burst(28, 340.0)
	_play(&"Bash")


func _on_landed(fall_speed: float) -> void:
	if fall_speed > 350.0:
		_dust.restart()
		_play(&"Land")


func _on_died() -> void:
	_trail.emitting = false
	_emit_burst(48, 420.0)
	_play(&"Death")


func _on_respawned() -> void:
	_trail.emitting = true
	_emit_burst(24, 180.0)
	_play(&"Respawn")


func _play(sound_name: StringName) -> void:
	var player := _sounds.get_node_or_null(NodePath(sound_name)) as AudioStreamPlayer
	if player:
		player.play()


func _emit_burst(amount: int, speed: float) -> void:
	_burst.amount = amount
	_burst.initial_velocity_min = speed * 0.4
	_burst.initial_velocity_max = speed
	_burst.restart()

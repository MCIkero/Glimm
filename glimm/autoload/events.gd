extends Node
## Globaler Event-Bus (Autoload "Events").
##
## Einmalige Gameplay-Ereignisse laufen über diesen Bus. So müssen Sender
## (Spieler, Schreine, Ziel) ihre Empfänger (HUD, Kamera) nicht kennen.

@warning_ignore("unused_signal")
signal player_died

@warning_ignore("unused_signal")
signal player_respawned

@warning_ignore("unused_signal")
signal level_completed(time_seconds: float, deaths: int)

## Kurzer Hilfetext unten im Bild (Tutorial, neue Fähigkeit ...).
@warning_ignore("unused_signal")
signal hint_requested(text: String)

## Stärke ungefähr 0–10.
@warning_ignore("unused_signal")
signal camera_shake_requested(strength: float)

## Bosskampf: Start, Lebensänderung, Sieg und Zurücksetzen (z. B. nach dem Tod des Spielers).
@warning_ignore("unused_signal")
signal boss_started(boss_name: String, max_health: int)

@warning_ignore("unused_signal")
signal boss_health_changed(current: int, maximum: int)

@warning_ignore("unused_signal")
signal boss_defeated

@warning_ignore("unused_signal")
signal boss_reset

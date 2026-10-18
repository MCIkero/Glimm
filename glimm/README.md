# Glimm – Licht ist Leben

2D-Metroidvania-Plattformer in **Godot 4.7**, inspiriert vom Movement-Gefühl von *Ori and the Will of the Wisps*.

**Eigener Twist:** Glimm ist selbst die einzige Lichtquelle in einer dunklen Höhle. Licht ist gleichzeitig **Sichtweite, Lebensenergie und Ressource**:

- Das Licht nimmt mit der Zeit langsam ab, und damit schrumpft auch der sichtbare Bereich.
- Dash und Bash kosten Licht, **Lichttore** öffnen sich nur gegen ein Licht-Opfer.
- Lichtsplitter, Lichtbrunnen (Checkpoints) und besiegte Schatten füllen das Licht wieder auf.
- Bei 0 Licht erlischt Glimm und startet neu am letzten Lichtbrunnen.

---

## Starten

1. **Godot 4.7** herunterladen (Standard-Version, *nicht* .NET): <https://godotengine.org/download>
2. Godot starten → **Importieren** → `project.godot` in diesem Ordner auswählen.
3. **F5** startet das Spiel mit dem Hauptmenü („Spielen“ oder Levelauswahl).

Renderer: **Forward+** (Vulkan). Falls das Spiel auf einem sehr alten Rechner nicht startet: *Projekt → Projekteinstellungen → Rendering → Renderer* auf „Mobile“ stellen.

## Steuerung

| Aktion | Tastatur | Controller |
|---|---|---|
| Laufen | A / D oder ← / → | Linker Stick / D-Pad |
| Zielen (für Bash) | W / S oder ↑ / ↓ (+ A/D) | Linker Stick |
| Springen (halten = höher) | Leertaste oder J | A / Kreuz |
| Dash *(freischaltbar)* | Shift oder K | X / RB |
| Bash *(freischaltbar)* | E oder L **halten**, zielen, loslassen | Y / LB |
| Pause-Menü | Esc oder P | Start |
| Level neu starten | R | Back / Select |
| Debug: alle Fähigkeiten | F1 | – |

Hinweistexte passen sich automatisch dem zuletzt benutzten Gerät an (Xbox- und PlayStation-Beschriftung). Alle Tasten sind unter *Projekteinstellungen → Eingabezuordnung* änderbar.

## Level, Gegner, Mechaniken

| # | Level | Neues |
|---|---|---|
| 1 | Wurzelhöhle | Tutorial: Laufen, Springen, Walljump. Dash und Bash werden freigeschaltet. |
| 2 | Der Schacht | Vertikales Level über 4 Etagen, Lichttor, erste Gegner |
| 3 | Schattenhain | Viele Gegner, teures Lichttor, Tunnel, Kamin und Finale mit Bash-Kette |
| 4 | Irrlichtschlucht | Lange Bash-Ketten über Dornen, bewegte Irrlichter, Lichttor (50) |
| 5 | Dunkle Tiefe | Dunkler, schnellere Irrlichter, Dash-Lücken, Speier-Grube, Walljump-Kamin |
| 6 | Herz der Schatten | Alle Gegnertypen kombiniert, danach **Bosskampf gegen das Schattenherz** |

Die Schwierigkeit steigt von Level zu Level: höhere Torkosten, schnellere Irrlichter (`wisp_duration`), weniger Lichtsplitter und eine dunklere Grundbeleuchtung.

### Bosskampf: Das Schattenherz

Beim Betreten der Arena schließt sich das Tor hinter Glimm, die Bossmusik startet und unten erscheint eine Lebensleiste. Das Schattenherz hat 6 Leben und lässt sich nur mit seinen eigenen Kugeln besiegen: **Kugel bashen und dabei vom Boss weg zielen** – die Kugel fliegt zurück und lenkt leicht auf den Boss ein.

| Phase | Leben | Angriff |
|---|---|---|
| 1 | 6–5 | Einzelne gezielte Kugeln |
| 2 | 4–3 | Dreier-Fächer, zusätzlich erscheinen Krabbler auf den Seitenplattformen |
| 3 | 2–1 | Kugelring mit 8 Kugeln + gezielter Schuss, die Arena wird dunkler |

Stirbt Glimm, wird der Kampf vollständig zurückgesetzt. Nach dem Sieg öffnet sich das Tor und der Lichtbaum (Ziel) erscheint.

| Gegner | Verhalten | So besiegst du ihn |
|---|---|---|
| **Schatten-Irrlicht** | schwebt oder patrouilliert, Berührung ist tödlich | Bash-bar wie ein Lichtsamen |
| **Krabbler** | läuft am Boden, dreht an Kanten und Wänden um | **Dash** hindurch (+15 Licht) |
| **Speier** | schießt Schattenkugeln, wenn er dich sieht | Kugel **bashen** → fliegt zurück (+20 Licht) |
| **Schattenherz** (Boss) | schwebt über der Arena, 3 Angriffsphasen | 6 zurückgeschleuderte Kugeln |

Bewegung: variable Sprunghöhe, Coyote Time, Jump Buffer, Doppelsprung, Walljump, Dash (mit Dash-Jump) und **Bash** (festhalten → Zeitlupe → zielen → wegschleudern).

---

## Alles im Editor bearbeiten

Das Projekt ist komplett im Godot-Editor bearbeitbar – es gibt keine externen Generatoren oder Build-Schritte.

### Neues Level anlegen

1. `scenes/levels/level_template.tscn` im Dateisystem-Dock duplizieren (z. B. `level_04.tscn`) und öffnen.
2. Wurzel-Node auswählen → im Inspector **Level Name**, **Start Hint**, **Granted Abilities** (z. B. `dash`, `bash`) und **Music** setzen.
3. `resources/level_catalog.tres` öffnen → im Inspector bei **Levels** einen Eintrag hinzufügen, **Title** setzen und die neue Szene in **Scene** ziehen. Das Hauptmenü zeigt das Level automatisch an.

### Gestalten

- **Fels malen:** Node `Terrain` auswählen → unten im *TileMap*-Panel unter **Terrains** das Terrain **„Fels“** wählen und malen (Godot-Autotiling: Moos oben, Wurzeln an der Decke). Auch normales Malen mit einer beliebigen Fels-Kachel funktioniert – das Script `AutoTerrain` korrigiert die Variante.
- **Schatten** (`TerrainShadows`) aktualisieren sich beim Malen automatisch. Es sind normale `LightOccluder2D`-Nodes. Button im Inspector: *Schatten neu erzeugen*.
- **Deko** (`Decor`): Gras, Ranken und Leuchtpilze sind normale Szenen-Instanzen und können frei verschoben, gelöscht oder aus `scenes/level/` von Hand ergänzt werden. Button im Inspector: *Deko verteilen* (ersetzt die vorhandene Deko).
- **Objekte und Gegner:** Szenen aus `scenes/objects/` und `scenes/enemies/` ins Level ziehen (unter `Objects`, `Hazards`, `Enemies`):

| Szene | Im Inspector bzw. Editor einstellen |
|---|---|
| `bash_orb` (Lichtsamen), `shadow_wisp` (Irrlicht) | **Travel**: Schwebestrecke (gestrichelte Linie im Editor), `(0,0)` = statisch |
| `spikes` (Dornen) | **Width Tiles**: Breite in Kacheln (Grafik und Kollision passen sich an) |
| `light_gate` (Lichttor) | **Light Cost**: geforderte Lichtmenge (Anzeige über dem Tor) |
| `ability_shrine` (Schrein) | **Ability**: `dash` oder `bash`, **Rune Color** |
| `hint_zone` (Hinweis) | **Text** (Platzhalter `{jump}`, `{dash}`, `{bash}` …), Größe über die Kollisionsform |
| `crawler` (Krabbler) | **Start Direction**, Geschwindigkeit |
| `spitter` (Speier) | Reichweite = Kreisform des Nodes `Detector`, **Fire Interval** |
| `boss_arena` + `shadow_heart` | Leben, Phasengrenzen, Schussintervalle und Kugeltempo je Phase am **ShadowHeart**; Tor, Auslöser und Krabbler-Punkte (`SummonPoints`) als Nodes in der Arena |
| `checkpoint`, `goal`, `light_shard` | einfach platzieren (Ursprung auf dem Boden, außer Lichtsplitter) |

- **Aussehen:** Alle Figuren und Objekte bestehen aus `Sprite2D`, `Polygon2D`, `Line2D` und `Label`, animiert mit `AnimationPlayer`. Farben, Formen und Animationen lassen sich direkt in den Szenen ändern.
- **Spielgefühl:** Alle Bewegungswerte sind `@export`-Variablen am Node **Player** (`scenes/player/player.tscn`).
- **Sound:** Effekte sind `AudioStreamPlayer`-Nodes in den jeweiligen Szenen (z. B. `Player/Effects/Sounds`). Lautstärken der Busse *Music* und *SFX* im unteren **Audio**-Panel.

> Tipp: In der 2D-Ansicht *Einrasten* auf 32 px stellen, dann sitzen Objekte genau auf den Kacheln.

---

## Architektur

```
autoload/      GameState (Licht, Fähigkeiten, Checkpoint), Events (Event-Bus),
               InputHints (Tastatur/Controller), Audio (Musik, UI-Sounds – audio.tscn)
resources/     LevelEntry / LevelCatalog (Levelliste als Resource) + level_catalog.tres
scenes/
  main.tscn    Spielszene: lädt das Level, Kamera, Pause, Levelwechsel
  player/      Player (CharacterBody2D) + StateMachine mit Idle, Run, Jump, Fall,
               WallSlide, Dash, Bash, Dead; Visual, Effekte, Licht
  objects/     Lichtsamen, Lichtsplitter, Lichtbrunnen, Dornen, Schrein, Lichttor, Ziel, Hinweis
  enemies/     ShadowWisp (erbt von BashOrb), Spitter + ShadowBolt, Crawler, ShadowHeart (Boss)
  level/       Level-Basis, BossArena, AutoTerrain, TerrainShadows, Decor, Deko-Szenen, Hintergrund
  levels/      level_01–06 + level_template
  fx/, ui/, camera/   Post-Processing, HUD, Menüs, Kamera
assets/        Texturen, Tileset, Shader, Materialien, Audio, Theme, Environment
```

- **Zustandsmaschine statt Monolith**, jeder Spielerzustand ist ein eigener Node.
- **Signals und Event-Bus** entkoppeln Gameplay, UI, Kamera und Audio.
- **Gemeinsame Schnittstelle** `take_reflected_hit()`: Speier, Krabbler und Boss reagieren auf zurückgeschleuderte Kugeln, ohne dass die Kugel ihre Klassen kennt (Duck Typing + Gruppe `reflect_target`).
- **Boss entkoppelt:** `ShadowHeart` meldet nur `phase_changed`/`defeated`, die `BossArena` entscheidet über Tor, Krabbler, Dunkelheit und Musik; das HUD hört über den Event-Bus (`boss_started`, `boss_health_changed` …) zu.
- **Szenen-Instancing und Vererbung** (`ShadowWisp`/`ShadowBolt` erben von `BashOrb`).
- **@tool-Skripte** machen Level-Inhalte im Editor sichtbar und bearbeitbar (Schwebestrecken, Dornenbreite, Torkosten, Schatten, Deko).
- **Godot-Features:** `TileMapLayer` + Terrain-Set, `CharacterBody2D`, `Area2D`, `RayCast2D`, `PointLight2D` + `LightOccluder2D` + `CanvasModulate`, `CanvasTexture` (Normal Maps), `WorldEnvironment` (Glow, HDR 2D), `Parallax2D`, `GPUParticles2D`/`CPUParticles2D`, Shader (Wind, Lichttor, Post-FX), `AnimationPlayer`, `Tween`, Audio-Busse mit Low-Pass-Effekt (Pause), `AudioStreamRandomizer`, Custom Resources, `@export_tool_button`.

## Quellen / Assets

- **Engine:** Godot Engine 4.7 – MIT-Lizenz, <https://godotengine.org>
- **Schrift:** Godot-Standardschrift (Open Sans, SIL Open Font License 1.1)
- **Hintergrundmusik:** `background_sound_1.ogg`, `background_sound_2.ogg` – [Quelle/Urheber und Lizenz eintragen]
- **Soundeffekte:** selbst erzeugt (synthetisch generiert)
- **Grafik:** selbst erstellt – Kachel-Textur und Normal Map prozedural generiert, alle Figuren und Objekte aus Godot-Nodes (Sprite2D, Polygon2D, Line2D) aufgebaut
- **Inspiration:** *Ori and the Will of the Wisps* (Moon Studios, 2020) – nur Spielgefühl und Bash-Idee, keine Assets übernommen

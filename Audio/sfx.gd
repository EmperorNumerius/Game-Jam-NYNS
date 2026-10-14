extends Node
## Sound manager (autoload "Sfx"). Replaces the old Wwise setup so the game
## also runs in a web browser. All sounds are the originals from the Wwise
## sound bank, converted to .ogg.
##
##   Sfx.play("ore_break")          one-shot, slight random pitch
##   Sfx.loop("drill", true/false)  start/stop a looping sound
##   Sfx.music("cave" / "colony")   crossfade between music tracks

const SOUNDS := {
	"ore_break": ["res://Audio/ore_break_1.ogg", "res://Audio/ore_break_2.ogg"],
	"crystal_break": ["res://Audio/crystal_break_1.ogg", "res://Audio/crystal_break_2.ogg", "res://Audio/crystal_break_3.ogg"],
	"place_tether": ["res://Audio/place_tether.ogg"],
	"oxygen_refill": ["res://Audio/oxygen_refill.ogg"],
	"player_hit": ["res://Audio/player_hit.ogg"],
	"worm_hit": ["res://Audio/worm_hit.ogg"],
	"worm_death": ["res://Audio/worm_death.ogg"],
	"worm_tunnel": ["res://Audio/worm_tunnel.ogg"],
	"ui_click": ["res://Audio/ui_click.ogg"],
}

const LOOPS := {
	"drill": "res://Audio/drill_engine.ogg",
	"low_oxygen": "res://Audio/low_oxygen_beep.ogg",
}

const MUSIC := {
	"cave": "res://Audio/music_cave.ogg",
	"colony": "res://Audio/music_colony.ogg",
}

const POOL_SIZE := 12
const MUSIC_DB := -8.0

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _loops := {}
var _music_players := {}
var _current_music := ""
var _last_played := {}


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SOUNDS:
		_streams[key] = SOUNDS[key].map(func(path): return load(path))
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	for key in LOOPS:
		var stream: AudioStreamOggVorbis = load(LOOPS[key]).duplicate()
		stream.loop = true
		var p := AudioStreamPlayer.new()
		p.stream = stream
		add_child(p)
		_loops[key] = p
	for key in MUSIC:
		var stream: AudioStreamOggVorbis = load(MUSIC[key]).duplicate()
		stream.loop = true
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = -80.0
		add_child(p)
		_music_players[key] = p
	# Every button in the game clicks when pressed.
	get_tree().node_added.connect(_on_node_added)


## Play a one-shot sound. `min_gap` stops the same sound from stacking up
## when it's triggered every frame.
func play(key: String, volume_db := 0.0, pitch_spread := 0.08, min_gap := 0.0):
	if not _streams.has(key):
		push_warning("Unknown sound: " + key)
		return
	var now := Time.get_ticks_msec() / 1000.0
	if min_gap > 0.0 and now - _last_played.get(key, -1000.0) < min_gap:
		return
	_last_played[key] = now
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _streams[key].pick_random()
	p.volume_db = volume_db
	p.pitch_scale = randf_range(1.0 - pitch_spread, 1.0 + pitch_spread)
	p.play()


func loop(key: String, on: bool, volume_db := 0.0):
	var p: AudioStreamPlayer = _loops[key]
	p.volume_db = volume_db
	if on and not p.playing:
		p.play()
	elif not on and p.playing:
		p.stop()


func music(key: String, fade := 1.5):
	if key == _current_music:
		return
	for k in _music_players:
		var p: AudioStreamPlayer = _music_players[k]
		if k == key:
			if not p.playing:
				p.play()
			create_tween().tween_property(p, "volume_db", MUSIC_DB, fade)
		elif p.playing:
			var tween := create_tween()
			tween.tween_property(p, "volume_db", -80.0, fade)
			tween.tween_callback(p.stop)
	_current_music = key


func stop_all():
	for k in _loops:
		_loops[k].stop()


func _on_node_added(node: Node):
	if node is BaseButton:
		node.pressed.connect(play.bind("ui_click", -4.0, 0.03))

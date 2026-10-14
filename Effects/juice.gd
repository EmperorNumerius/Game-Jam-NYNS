extends Node
## Game-feel helpers (autoload "Juice").
##
##   Juice.shake(6.0)                       camera shake, decays on its own
##   Juice.hitstop(0.05)                    freeze the game for a moment
##   Juice.dust(world_pos, color, 8)        burst of debris particles
##   Juice.popup("+2", world_pos, color)    floating text that rises and fades

const MAX_SHAKE := 18.0
const SHAKE_DECAY := 40.0  # pixels per second

var _shake := 0.0
var _hitstop_until := 0
var _hitstop_scale := 1.0
var _popup_layer: CanvasLayer


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta):
	# Hit-pause: slow time until the deadline passes (checked every frame, in real time)
	Engine.time_scale = _hitstop_scale if Time.get_ticks_msec() < _hitstop_until else 1.0

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	_shake = max(_shake - SHAKE_DECAY * delta, 0.0)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake


func shake(amount: float):
	# Take the bigger of the current and new shake instead of adding,
	# so fast digging doesn't build up into an earthquake.
	_shake = min(max(_shake, amount), MAX_SHAKE)


func hitstop(seconds: float, slow_scale := 0.05):
	_hitstop_until = max(_hitstop_until, Time.get_ticks_msec() + int(seconds * 1000.0))
	_hitstop_scale = slow_scale


func dust(world_pos: Vector2, color: Color, amount := 8, speed := 140.0):
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.randomness = 0.5
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 600)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	var fade := Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	p.color_ramp = fade
	p.z_index = 50
	p.global_position = world_pos
	scene.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func popup(text: String, world_pos: Vector2, color := Color.WHITE, size := 22):
	var layer := _get_popup_layer()
	if layer == null:
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = world_pos + Vector2(randf_range(-12, 12) - 40, -40)
	label.size = Vector2(80, 30)
	label.pivot_offset = label.size / 2
	label.scale = Vector2(0.4, 0.4)
	layer.add_child(label)
	var t := label.create_tween().set_parallel(true)
	t.tween_property(label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "position:y", label.position.y - 50, 0.8).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.45)
	t.chain().tween_callback(label.queue_free)


func flash(item: CanvasItem, color := Color(1, 0.3, 0.3), time := 0.25):
	item.modulate = color
	item.create_tween().tween_property(item, "modulate", Color.WHITE, time)


## Popups live on their own layer that follows the camera, so the world's
## darkness (CanvasModulate) doesn't dim them.
func _get_popup_layer() -> CanvasLayer:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	if is_instance_valid(_popup_layer) and _popup_layer.get_parent() == scene:
		return _popup_layer
	_popup_layer = CanvasLayer.new()
	_popup_layer.follow_viewport_enabled = true
	_popup_layer.layer = 0  # below the HUD
	scene.add_child(_popup_layer)
	return _popup_layer

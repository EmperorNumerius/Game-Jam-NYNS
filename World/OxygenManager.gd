extends Node


@export var tether_placer : Node
@export var o2_meter : Range
@export var o2_low_vignette : CanvasItem
@export var o2_low_fullscreen : CanvasItem

@export var o2_current = 1.0
@export var o2_max = 1.0:
	set(v):
		o2_max = v
		if !is_inside_tree(): await ready
		if o2_meter == null: await get_tree().process_frame
		o2_meter.max_value = v
@export var o2_depletion = 1.0
@export var o2_recovery = 4.0

var checkpoint_pos = Vector2()
var _was_recovering = false


func _ready():
	o2_current = o2_max
	checkpoint_pos = get_parent().global_position
	

func _process(delta):
	var recovering = tether_placer.nearby_tethers.size() > 0
	if recovering:
		o2_current += o2_recovery * delta
		if not _was_recovering and o2_current < o2_max * 0.95:
			Sfx.play("oxygen_refill", -4.0)
	else:
		o2_current -= o2_depletion * delta
	_was_recovering = recovering
	if o2_current > o2_max:
		o2_current = o2_max

	if o2_current < -2.0:
		get_parent().global_position = checkpoint_pos
		var remains_on_death = 0.25
		get_parent().gems = ceili(get_parent().gems * remains_on_death)
		get_parent().gold = ceili(get_parent().gold * remains_on_death)
		get_parent().iron = ceili(get_parent().iron * remains_on_death)
		get_parent().oxyore = ceili(get_parent().oxyore * remains_on_death)
		o2_current = o2_max
		Juice.shake(18.0)
		Juice.popup("You passed out! Lost 75% of your ore", checkpoint_pos + Vector2(0, -60), Color(1, 0.5, 0.5), 22)
	
	# Warning beeps when oxygen is low and you're not refilling
	Sfx.loop("low_oxygen", o2_current < o2_max * 0.3 and not recovering, -6.0)
	o2_low_vignette.self_modulate.a = smoothstep(0.5, 0.2, o2_current / o2_max)
	o2_low_fullscreen.self_modulate.a = smoothstep(5, 0, o2_current)

	o2_meter.value = o2_current

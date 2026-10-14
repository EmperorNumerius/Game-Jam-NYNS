extends Area2D

@export var tether_scene : PackedScene
@export var place_at : Node
@export var count_label : Label
@export var count_left = 3:
	set(v):
		count_left = v
		if !is_inside_tree(): await ready
		count_label.text = str(v)

var nearby_tethers = []

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	count_left = count_left


func _process(delta):
	queue_redraw()


func _input(event):
	if event.is_pressed() && event.is_action("Place") &&  nearby_tethers.size() > 0 && count_left > 0:
		var new_node = tether_scene.instantiate()
		place_at.add_child(new_node)
		new_node.global_position = global_position
		var nearest_tether = nearby_tethers[0]
		for x in nearby_tethers:
			if global_position.distance_squared_to(nearest_tether.global_position) > global_position.distance_squared_to(x.global_position):
				nearest_tether = x
		new_node.connect_tether(nearest_tether)
		count_left -= 1
		Sfx.play("place_tether")
		Juice.shake(5.0)
		Juice.dust(global_position, Color("4dc3ff"), 12, 160.0)


func _on_area_entered(area):
	if !area.is_in_group("oxygen_tether"): return
	nearby_tethers.append(area.get_parent())
	$Hint.show()


func _on_area_exited(area):
	if !area.is_in_group("oxygen_tether"): return
	nearby_tethers.erase(area.get_parent())
	$Hint.visible = nearby_tethers.size() > 0


func _draw():
	for x in nearby_tethers:
		draw_line(Vector2.ZERO, x.global_position - global_position, Color.WHITE, 4.0)


func _on_frame_timeout():
	$Hint/Sprite2D.frame_coords.x = 1 - $Hint/Sprite2D.frame_coords.x
	$Hint/Sprite2D.frame_coords.y = 0 if count_left > 0 else 1

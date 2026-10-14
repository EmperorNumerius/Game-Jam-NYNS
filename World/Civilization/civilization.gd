extends Node2D

const CIV_WIDTH = 1828
const CIV_HEIGHT = 1235

@onready var rng = RandomNumberGenerator.new()
@onready var bg = $Background
@onready var workshop = $Workshop
@onready var qtmole = $SurpriseMole
@onready var dirt = $"../Dirt"

var visited = false

var civ_textures := [
	preload("res://Sprites/Civilization/civ1.png"),
	preload("res://Sprites/Civilization/civ3.png"),
	preload("res://Sprites/Civilization/civ7.png"),
	preload("res://Sprites/Civilization/civ8.png"),
	preload("res://Sprites/Civilization/civ2.png"),
	preload("res://Sprites/Civilization/civ4.png"),
	preload("res://Sprites/Civilization/civ5.png"),
	preload("res://Sprites/Civilization/civ6.png"),
	preload("res://Sprites/Civilization/civ9.png")
] as Array[Texture]

var tween

# 450px tall, 750px wide
# Called when the node enters the scene tree for the first time.

func _ready():
	# The upgrade menu now only opens when the player walks into a workshop.
	if !visited:
		var tether = $"/root/World/OxygenTethers".get_child(0).duplicate()
		$"/root/World/OxygenTethers".add_child(tether)
		tether.position = position
		tether.z_index = -1

	# set the x and y to a random val  
	# in pixels: x clamped (600, 2200), y every 3500 
	dirt.delete_dirt((global_position.x - 450)/16, 900/16, (global_position.y - 300)/16, 600/16)
	var civ_position = Vector2i(0,0)
	var bg_variant = randi_range(0,8)
	_set_civ_variant(bg_variant)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_tile_delete_area_entered(area):
	pass
	#if area is TileMap:
		#var tilemap := area.get_collider() as TileMap
		#tilemap.erase_cell(0, area.position)


func _set_civ_variant(bg_var):
	# sets background variant
	bg.texture = civ_textures[bg_var]
	
	# sets the workshop location
	var ws_variant = randi_range(0,3)
	if (bg_var <=3):
		ws_variant = randi_range(0,2)
	workshop.region_rect = Rect2(CIV_WIDTH*ws_variant, 0, CIV_WIDTH, CIV_HEIGHT)
	
	# qtmole ;P <3
	qtmole.visible = false
	if (rng.randf() < 0.1):
		qtmole.visible = true
	

func _on_player_entered_area_entered(area):
	visited = true
	if tween != null: tween.stop()
	tween = create_tween()
	$PointLight2D.show()
	$PointLight2D2.show()
	tween.tween_property($PointLight2D, "energy", 1.0, 1.0)
	tween.parallel().tween_property($PointLight2D2, "energy", 1.0, 1.0)


func _on_player_entered_area_exited(area:Area2D):
	if tween != null: tween.stop()
	tween = create_tween()
	tween.tween_property($PointLight2D, "energy", 0.0, 1.0)
	tween.parallel().tween_property($PointLight2D2, "energy", 0.0, 1.0)
	tween.tween_callback(func():
		$PointLight2D.hide()
		$PointLight2D2.hide()
	)

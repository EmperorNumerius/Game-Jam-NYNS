extends CharacterBody2D

signal block_destroyed()

var ORI_SPEED = 200
var SPEED = ORI_SPEED
var RESISTANCE = 100
var MINING_LEVEL = 0
var ORE_YIELD = 1
var direction = Vector2.ZERO

var inside = false

var gems = 0
var gold = 0
var iron = 0
var oxyore = 0

@onready var dig_timer = $DigTimer
@onready var oxygen_manager = $OxygenManager
@onready var hurt_timer = $HurtTimer
@onready var in_civ = $InCiv
@onready var upgrades = $"../UI/UpgradeMenu"

# name, popup color, and sound for each ore row in the Ores tileset
const ORE_INFO = [
	{"name": "gems", "color": Color("a8e61d"), "sound": "crystal_break"},
	{"name": "gold", "color": Color("ffcc00"), "sound": "ore_break"},
	{"name": "iron", "color": Color("c9bcbc"), "sound": "ore_break"},
	{"name": "oxyore", "color": Color("4dc3ff"), "sound": "crystal_break"},
]
const DIRT_COLORS = [Color("8a6450"), Color("6e5048"), Color("5a4a5e"), Color("4a4660")]

var _bonk_cooldown = 0.0

func _process(delta):
	_bonk_cooldown -= delta

func _physics_process(delta):
	direction.x = Input.get_axis("Left", "Right")
	direction.y = Input.get_axis("Up", "Down")
	direction = direction.normalized()
	velocity = direction * SPEED
	var collision = move_and_collide(velocity * delta)
	while collision and collision.get_collider() is TileMap:
		var tilemap := collision.get_collider() as TileMap
		var pos = tilemap.local_to_map(collision.get_position() - collision.get_normal() * 1.0)

		#coordinates for ores
		var coords = tilemap.get_cell_atlas_coords(0,pos)
		var cell_center = tilemap.to_global(tilemap.map_to_local(pos))
		#check mining level
		if tilemap.name == "Dirt":
			if MINING_LEVEL < coords.x / 16:
				# Too hard for the current drill: give feedback instead of silently stopping
				if _bonk_cooldown <= 0.0:
					_bonk_cooldown = 0.6
					Juice.shake(4.0)
					Juice.popup("Need a better drill!", cell_center, Color(1, 0.6, 0.5), 18)
				break

		if tilemap.name == "Ores" and coords.y >= 0 and coords.y < ORE_INFO.size():
			var ore = ORE_INFO[coords.y]
			set(ore["name"], get(ore["name"]) + ORE_YIELD)
			Sfx.play(ore["sound"])
			Juice.popup("+%d %s" % [ORE_YIELD, ore["name"]], cell_center, ore["color"])
			Juice.dust(cell_center, ore["color"], 14, 220.0)
			Juice.shake(7.0)
			Juice.hitstop(0.045)
		elif tilemap.name == "Dirt":
			Juice.dust(cell_center, DIRT_COLORS[clampi(coords.x / 16, 0, 3)], 6)
			Juice.shake(2.0)
		dig_timer.start()
		SPEED = ORI_SPEED - RESISTANCE
		tilemap.erase_cell(0, pos)
		if tilemap.name == "Dirt":
			tilemap.erase_cell(1, pos)
			for pos_offset in [
				pos + Vector2i.UP,
				pos + Vector2i.DOWN,
				pos + Vector2i.LEFT,
				pos + Vector2i.RIGHT,
			]:
				var dest_atlas_coords := tilemap.get_cell_atlas_coords(0, pos_offset)
				if dest_atlas_coords != Vector2i(-1, -1):
					tilemap.set_cell(1, pos_offset, 0, Vector2i(randi() % 3, dest_atlas_coords.x / 16))

		block_destroyed.emit()
		tilemap.update_internals()
		collision = move_and_collide(collision.get_remainder())

func _on_dig_timer_timeout():
	SPEED = ORI_SPEED

func _on_hitbox_area_entered(area):
	oxygen_manager.o2_current += -12
	oxygen_manager.o2_recovery = 1.0
	hurt_timer.start()
	Sfx.play("player_hit")
	Juice.shake(16.0)
	Juice.hitstop(0.08)
	Juice.flash($Node2D)
	Juice.popup("-12 O2", global_position + Vector2(0, -30), Color(1, 0.35, 0.35), 24)

func _on_hurt_timer_timeout():
	oxygen_manager.o2_recovery = 4.0


func _on_in_civ_area_entered(area):
	inside = true
	Sfx.music("colony")


func _on_in_civ_area_exited(area):
	inside = false
	Sfx.music("cave")


func _on_in_workshop_area_entered(area):
	upgrades.visible = true


func _on_in_workshop_area_exited(area):
	upgrades.visible = false

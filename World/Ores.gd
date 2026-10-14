extends TileMap


#LEFT CLICK TO GENERATE 1 LEVEL, no depth limit, 120, 150, 200 DEPTH per civilization
var WIDTH = 200
var DEPTH = 0

var spwn_gems = 0
var spwn_gold = 0
var spwn_iron = 0
var spwn_oxyore = 0

var ore_chance = 0.0015
var gem_chance = ore_chance/20.0
var gold_chance = ore_chance/10.0
var iron_chance = ore_chance/2.0
var oxyore_chance = ore_chance

signal ore_created(WIDTH, DEPTH, increase)

@onready var rng = RandomNumberGenerator.new()
@onready var dirt = $"../Dirt"

const TILES = {
	'gems': 0,
	'gold': 1,
	'iron': 2,
	'oxyore': 3
}

func _ready():
	self.ore_created.connect(dirt.create_dirt)
				
func _process(delta):
	ore_chance = 0.0015 + (DEPTH/1000000.0)
	gem_chance = ore_chance/min((16.0 - 1.1**(DEPTH/100)), 5.0)
	gold_chance = ore_chance/min((9.0 - 1.1**(DEPTH/100)), 3.0)
	iron_chance = ore_chance/2.0
	oxyore_chance = ore_chance
	#if Input.is_action_just_released('mouse_left'):
		#DEPTH += 100
		#print([DEPTH, spwn_gems, spwn_gold, spwn_iron, spwn_oxyore])
		#create_ores(WIDTH)
	
func create_ores(width, increase):
	ore_created.emit(WIDTH, DEPTH, increase)
	for y in range(DEPTH, DEPTH + increase):
		for x in range(width):
			var rand_num = rng.randf_range(0.0, 1.0)
			if min(gem_chance, gold_chance) > rand_num: #spwn_gems
				spwn_gems += create_ore_chunk(0, x, y, 0.1)
			elif min(gold_chance, iron_chance) > rand_num: #spwn_gold
				spwn_gold += create_ore_chunk(1, x, y, 0.15)
			elif iron_chance > rand_num: #spwn_iron
				spwn_iron += create_ore_chunk(2, x, y, 0.2)
			elif oxyore_chance > rand_num: #spwn_oxyore
				spwn_oxyore += create_ore_chunk(3, x, y, 0.1)
			else: #dirt
				pass
	DEPTH += increase
	
func create_ore_chunk(ore, center_x, center_y, spawn_chance):
	var ore_amt = 0
	var rand_radius = rng.randf_range(3.0, 10.0)
	for x in range(rand_radius*2):
		for y in range(rand_radius*2):
			var rand_num = rng.randf_range(0.0, 1.0)
			if sqrt(((x-rand_radius)**2) + ((y-rand_radius)**2)) <= rand_radius and spawn_chance > rand_num:
				if get_cell_source_id(0, Vector2(x, y)) == -1:
					create_ore(ore, center_x + x, center_y + y)
					ore_amt += 1
	return ore_amt

func create_ore(ore, x, y):
	# Pick one of the three sprite variants for this ore at random.
	# (The old version checked > 1.0 before > 2.0, so variant 1 never appeared.)
	var variant = rng.randi_range(0, 2)
	set_cell(0, Vector2i(x, y), 0, Vector2i(variant, ore))
	
func delete_ore(width, width_inc, depth, depth_inc):
	for y in range(depth, depth+depth_inc):
		for x in range(width, width+width_inc):
			erase_cell(0, Vector2i(x, y))
	


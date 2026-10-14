extends CharacterBody2D

#worm hovers the player around a circle, tries to go through the player to attack, then goes back into its travel or hover state
const SPEED = 320.0

@onready var player = $"../Player"
@onready var head = $Head
@onready var body = $WormBody
@onready var tail = $Tail

@onready var hover_timer = $HoverTimer
@onready var travel_timer = $TravelTimer
@onready var oxygen_manager = $"../Player/OxygenManager"

enum {
	TRAVEL,
	HOVER,
	ATTACK,
	WAIT
}

var state = TRAVEL
var rng
var max = 4
var curr = 0
var angle = 0
var randomnum = 0
var hp = 180
var radius = 700
var circle_angle = 0
var pos = Vector2(0, 0)
var worm_pos = Vector2(0, 0)
var in_area = false
var taking_dmg = false

func _ready():
	body.part = head
	while curr < max:
		var dup = body.duplicate()
		add_child(dup)
		dup.part = body
		body = dup
	tail.part = body
	rng = RandomNumberGenerator.new()
	rng.randomize()
	randomnum = rng.randf()
	hover_timer.one_shot = true
	travel_timer.one_shot = true

func _physics_process(delta):
	if taking_dmg:
		hp += -1
		Sfx.play("worm_hit", -2.0, 0.15, 0.12)
		if Engine.get_physics_frames() % 6 == 0:
			Juice.dust(head.global_position, Color("d9a6a6"), 5, 180.0)
			Juice.shake(3.0)
	if hp <= 0:
		Sfx.play("worm_death")
		Juice.popup("Worm defeated!", head.global_position, Color(1, 0.85, 0.4), 28)
		Juice.dust(head.global_position, Color("d9a6a6"), 30, 320.0)
		Juice.shake(16.0)
		Juice.hitstop(0.12)
		position = Vector2(player.position.x + 6000, player.position.y + 6000)
		hp = 180
	match state:
		TRAVEL:
			if in_area:
				move(get_circle_position(player.global_position, radius + 800), head, delta)
			else:
				move(get_circle_position(player.global_position, radius), head, delta)
				if travel_timer.time_left <= 0:
					travel_timer.start()
		HOVER:
			if hover_timer.time_left <= 0:
				hover_timer.start()
			radius = rng.randf_range(350, 500)
			angle += 0.01
			worm_pos.x = pos.x + radius * cos(angle)
			worm_pos.y = pos.y + radius * sin(angle)
			move(Vector2(worm_pos.x, worm_pos.y), head, delta)
		ATTACK:
			move(pos, head, delta) 
			if abs(pos - head.global_position) < Vector2(3, 3):
				randomnum = rng.randf()
				if randomnum > 0.5:
					state = TRAVEL
				else:
					state = HOVER
		WAIT:
			move(get_circle_position(player.global_position, radius + 1000), head, delta)
			if !player.inside:
				state = ATTACK
		
func get_circle_position(player_pos, rad):
	var x = player_pos.x + cos(angle) * rad
	var y = player_pos.y + sin(angle) * rad

	return Vector2(x, y)
	
func move(target, part, delta):
	var direction = (target - part.global_position).normalized() 
	var desired_velocity =  direction * SPEED
	var steering = (desired_velocity - part.velocity) * delta * 3
	part.velocity += steering
	rotate_part(part, target, delta)
	part.move_and_slide()
	
func rotate_part(part, target, delta):
	var direction = (target - part.global_position).normalized() 
	var angleTo = part.transform.x.angle_to(direction)
	part.rotate(sign(angleTo) * min(delta * 3, abs(angleTo)))

	
func _on_sense_area_entered(area):
	if state != ATTACK:
		in_area = true
		state = HOVER
		pos = player.global_position
	
		
func _on_sense_area_exited(area):
	in_area = false
	
func _on_hover_timer_timeout():
	pos = 2*player.global_position - Vector2(head.global_position.x, head.global_position.y)
	state = ATTACK
	_announce_attack()

func _announce_attack():
	# Rumble before the lunge so the player gets a warning
	Sfx.play("worm_tunnel", 2.0, 0.1)
	Juice.shake(6.0)

func _on_travel_timer_timeout():
	pos = 2*player.global_position - Vector2(head.global_position.x, head.global_position.y)
	state = ATTACK
	_announce_attack()

func _on_hitbox_area_entered(area):
	taking_dmg = true

func _on_hitbox_area_exited(area):
	taking_dmg = false

func _on_leave_area_area_entered(area):
	state = WAIT

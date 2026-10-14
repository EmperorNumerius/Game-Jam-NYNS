extends CharacterBody2D

const SPEED = 320.0
var radius = 160

@onready var worm = get_parent()
var part
var body
var in_area = false

func _ready():
	if name != 'Tail':
		if worm.curr < worm.max:
			worm.curr += 1
	else:
		radius = 100

func _physics_process(delta):
	#move(head.global_position, self, delta)
	if sqrt((position.x - part.position.x)**2 + (position.y - part.position.y)**2) < radius:
		in_area = true
	else:
		in_area = false
	velocity = part.velocity
	if !in_area:
		global_position = global_position.move_toward(part.global_position, delta * SPEED)
		rotate_part(self, part.global_position, delta)
	#print(global_position, '|', part.global_position)

func rotate_part(part, target, delta):
	var direction = (target - part.global_position).normalized() 
	var angleTo = part.transform.x.angle_to(direction)
	part.rotate(sign(angleTo) * min(delta * 3, abs(angleTo)))

func _on_hitbox_area_exited(area):
	pass
	#in_area = false

func _on_hitbox_area_entered(area):
	pass
	#in_area = true

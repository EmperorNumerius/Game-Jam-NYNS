extends Node

@export var controller : CharacterBody2D
@export var eye_l : Node2D
@export var eye_r : Node2D
@export var hands_item : Node2D
@export var backpack : Node2D
@export var hscale : Node2D
@export var eye_radius := 16.0
@export var drill_shake := 12.0
@export var drill_shake_time := 0.2
@export var backpack_shake := 12.0
@export var anim : AnimationTree

var look_vector := Vector2.ZERO
var block_destroyed_timer : Timer
var mining_check := false



func _ready():
	anim.active = true
	block_destroyed_timer = Timer.new()
	block_destroyed_timer.one_shot = true
	block_destroyed_timer.timeout.connect(func():
		anim["parameters/claw/playback"].travel(&"idle")
	)
	add_child(block_destroyed_timer)


func _process(delta : float):
	var rel_velocity = controller.velocity / controller.SPEED

	if rel_velocity.x > 0.0: hscale.scale.x = +1.0
	if rel_velocity.x < 0.0: hscale.scale.x = -1.0

	rel_velocity.x *= hscale.scale.x
	look_vector = look_vector.lerp(rel_velocity, 0.1)

	eye_l.position = look_vector * eye_radius
	eye_r.position = look_vector * eye_radius
	hands_item.rotation = lerp_angle(hands_item.rotation, (look_vector * Vector2(1.0, 0.5)).angle(), 0.2)
	if block_destroyed_timer.time_left > 0.0:
		hands_item.position = Vector2(randf() - 0.5, randf() - 0.5) * drill_shake

	backpack.position = Vector2(randf() - 0.5, randf() - 0.5) * backpack_shake
	if block_destroyed_timer.time_left == 0 and mining_check:
		Sfx.loop("drill", false)
		mining_check = false


func _on_player_block_destroyed():
	block_destroyed_timer.start(drill_shake_time)
	if not mining_check:
		Sfx.loop("drill", true, -6.0)
		mining_check = true
	anim["parameters/claw/playback"].travel(&"dig")

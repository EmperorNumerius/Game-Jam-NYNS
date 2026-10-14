extends Label

# Assuming the player node is a sibling of this label node
@onready var player = get_node("/root/World/Player")

func _process(delta):
	# Get the y position of the player
	# 16 pixels (one tile) = 1 meter, counted downward from the surface
	var meters = max(0, int(player.position.y / 16.0))
	self.text = str(meters) + "m"

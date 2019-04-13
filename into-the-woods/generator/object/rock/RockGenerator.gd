extends ObjectGenerator

const rock = preload("res://object/rock/Rock.tscn")

export(int) var spread

var constants

func _ready():
	constants = get_node("/root/Constants")
	
func process_stack(x):
	var submerged = terrain_info.sample_height(x) <= terrain_info.water_level
	if x % spread != 0 or submerged:
		return
	
	var node = rock.instance()
	node.position = constants.tile_size * Vector2(x, -(terrain_info.sample_height(x) + 1))
	objects.add_child(node)
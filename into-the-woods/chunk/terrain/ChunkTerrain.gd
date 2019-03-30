extends Node

signal stack_generated(chunk_x, x)
signal tile_generated(chunk_x, x, y)	# we probably won't need to use this

export(float) var height_harshness
export(int) var min_height
export(int) var max_height

# stack generation progress
var right = 0
var heightmap = {}	# for convenience

const DIRT = 0
const GRASS = 1

var chunk	# set externally
var constants
var state

func gen_stack(x):
	var nz = state.noise.perlin_noise2d(height_harshness * x, state.seed_hash)
	var height = floor(min_height + (max_height - min_height) * (nz + 1) / 2)
	heightmap[x] = height
	for y in range(height):
		# replace dirt that's exposed to air to grass after next stack's generation
		var type = DIRT
		chunk.set_cell(x, y, type)
		# after _ready (add_child)
		emit_signal("tile_generated", chunk.chunk_x, x, y)
		
	# listen in order to turn	dirt -> grass
	emit_signal("stack_generated", chunk.chunk_x, x)
	right = max(right, x)
	
func update_dirt_grass_stack(x):
	# Calculate if the tile is exposed to air or not.
	# If exposed to air, replace with a grass tile.
	for y in range(heightmap[x]):
		if is_tile_exposed(x, y) and chunk.get_cell(x, y) == DIRT:
			chunk.set_cell(x, y, GRASS)

func gen():
	for x in range(0, constants.chunk_width + 1):
		gen_stack(x)
		
	# Update all stack except the last one.
	for x in range(0, constants.chunk_width):
		# We know that all stacks around it are generated.
		update_dirt_grass_stack(x)

func _ready():
	constants = get_node("/root/Constants")
	state = get_node("/root/State")

"""HELPER"""

# Tests if tile is exposed to air
func is_tile_exposed(x, y):
	var pos = Vector2(x, y)
	# check left, right, top and bottom of tile for air
	var positions = [pos + Vector2.LEFT,
		pos + Vector2.RIGHT,
		pos + Vector2.UP,
		pos + Vector2.DOWN]
		
	for position in positions:
		# Don't check if < height, because that's the 
		# 	primary condition we're testing.
		if position.x >= 0 and position.x <= right and position.y >= 0:
			# Vector stores floats, so convert to int for dictionary keys.
			# INVALID_CELL means no tile exists there 
			#	(which means air, given the above conditions).
			if chunk.get_cell(int(position.x), int(position.y)) == chunk.INVALID_CELL:
				return true
	return false
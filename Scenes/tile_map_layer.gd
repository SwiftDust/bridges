extends TileMapLayer

@export var GRID_SIZE_X = 9
@export var GRID_SIZE_Y = 5

func draw_map(islands: Array):
	for x in GRID_SIZE_X:
		for y in GRID_SIZE_Y:
			if islands.has(Vector2(x, y)):
				set_cell(Vector2i(x, y), 1, Vector2i(0,0), 0) # draw island
			else:
				set_cell(Vector2i(x, y), 0, Vector2i(0,0), 0) # draw sea
